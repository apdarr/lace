class NaturalLanguageQuery
  # Distance conversion constant: 1 mile = 1609.34 meters

  def initialize(query)
    @query = query
  end

  def execute_query
    # Use GPT to generate query parameters in a structured format
    query_params = generate_query_params_with_gpt(@query)

    # Build and execute the query safely using ActiveRecord methods
    build_and_execute_query(query_params)
  end

  private

  def generate_query_params_with_gpt(query)
    client = OpenAI::Client.new

    response = client.chat(
      parameters: {
        model: "gpt-4.1-nano",
        messages: [
          {
            role: "system",
            content: system_prompt_for_query_generation
          },
          {
            role: "user",
            content: "Convert this natural language query to query parameters: #{query}"
          }
        ],
        temperature: 0.1
      }
    )

    result = response.dig("choices", 0, "message", "content").strip
    Rails.logger.debug "NaturalLanguageQuery: GPT response: #{result}"

    # Parse the JSON response
    begin
      JSON.parse(result)
    rescue JSON::ParserError => e
      Rails.logger.error "NaturalLanguageQuery: Failed to parse GPT response as JSON: #{e.message}"
      Rails.logger.error "NaturalLanguageQuery: GPT response was: #{result}"
      { "conditions" => [], "order" => nil, "limit" => nil }
    end
  end

  def build_and_execute_query(query_params)
    begin
      # Start with the base Activity query, always filtering to Run activities
      query = Activity.where(activity_type: "Run")

      # Apply each condition safely
      query_params["conditions"]&.each do |condition|
        query = apply_condition(query, condition)
      end

      # Apply ordering if specified
      if query_params["order"]
        order_params = query_params["order"]
        if valid_order_column?(order_params["column"]) && valid_order_direction?(order_params["direction"])
          query = query.order(order_params["column"] => order_params["direction"])
        end
      end

      # Apply limit if specified
      if query_params["limit"]&.is_a?(Integer) && query_params["limit"] > 0 && query_params["limit"] <= 1000
        query = query.limit(query_params["limit"])
      end

      Rails.logger.info "NaturalLanguageQuery: Executing safe query with params: #{query_params}"
      query
    rescue => e
      Rails.logger.error "NaturalLanguageQuery: Error building query: #{e.message}"
      Activity.none
    end
  end

  def apply_condition(query, condition)
    column = condition["column"]
    operator = condition["operator"]
    value = condition["value"]

    # Validate column name to prevent injection
    return query unless valid_column?(column)
    
    # Validate operator to prevent injection
    return query unless valid_operator?(operator)

    case operator
    when "="
      query.where(column => value)
    when ">"
      query.where("#{column} > ?", value)
    when "<"
      query.where("#{column} < ?", value)
    when ">="
      query.where("#{column} >= ?", value)
    when "<="
      query.where("#{column} <= ?", value)
    when "BETWEEN"
      if value.is_a?(Array) && value.length == 2
        query.where("#{column} BETWEEN ? AND ?", value[0], value[1])
      else
        query
      end
    when "LIKE"
      query.where("#{column} LIKE ?", value)
    when "IN"
      if value.is_a?(Array)
        query.where(column => value)
      else
        query
      end
    else
      query
    end
  end

  def valid_column?(column)
    # Only allow known safe columns from the Activity model
    allowed_columns = %w[
      distance elapsed_time activity_type kudos_count
      average_heart_rate max_heart_rate description
      created_at updated_at strava_id start_date_local plan_id
    ]
    allowed_columns.include?(column.to_s)
  end

  def valid_operator?(operator)
    # Only allow safe operators
    allowed_operators = %w[= > < >= <= BETWEEN LIKE IN]
    allowed_operators.include?(operator.to_s)
  end

  def valid_order_column?(column)
    valid_column?(column)
  end

  def valid_order_direction?(direction)
    %w[asc desc ASC DESC].include?(direction.to_s)
  end

  def system_prompt_for_query_generation
    <<~PROMPT
      You are a Ruby on Rails expert specializing in building ActiveRecord queries. Your job is to#{' '}
      translate natural language requests about running activities into structured query parameters#{' '}
      that will be used to build safe ActiveRecord queries.

      IMPORTANT DATABASE INFORMATION:
      - The model is called 'Activity'
      - Distances are stored in METERS (not miles)
      - Times are stored in SECONDS
      - Heart rates are stored in BPM
      - Activity type is stored as a string (e.g., "Run")

      REQUIRED CONVERSIONS:
      - 1 mile = 1609.34 meters
      - 1 km = 1000 meters
      - 1 hour = 3600 seconds
      - 1 minute = 60 seconds

      COLUMN REFERENCE:
      - distance (float): the distance in meters
      - elapsed_time (integer): duration in seconds
      - activity_type (string): type of activity (e.g., "Run")#{' '}
      - kudos_count (integer): number of likes
      - average_heart_rate (float): average heart rate in BPM
      - max_heart_rate (float): maximum heart rate in BPM
      - start_date_local (datetime): when the activity started
      - created_at (datetime): when the record was created
      - updated_at (datetime): when the record was updated
      - strava_id (integer): Strava activity ID
      - plan_id (integer): associated training plan ID
      - description (string): activity description

      GUIDELINES:
      1. All queries automatically filter to activity_type = "Run"
      2. Convert all units appropriately (miles → meters, minutes → seconds)
      3. Handle relative terms appropriately:
         - "long runs" → distance > 16093.4 (10 miles in meters)
         - "short runs" → distance < 8046.7 (5 miles in meters)
         - "easy runs" → average_heart_rate < 130
         - "hard runs" → average_heart_rate > 150
         - "moderate runs" → average_heart_rate between 130-150
      4. For distance ranges (e.g., "20 mile runs"), use BETWEEN with ±100 meter tolerance
      5. Return ONLY valid JSON with no explanations

      OUTPUT FORMAT:
      Return a JSON object with the following structure:
      {
        "conditions": [
          {
            "column": "column_name",
            "operator": "=|>|<|>=|<=|BETWEEN|LIKE|IN",
            "value": "single_value_or_array_for_BETWEEN_and_IN"
          }
        ],
        "order": {
          "column": "column_name",
          "direction": "asc|desc"
        },
        "limit": integer_or_null
      }

      EXAMPLES:

      Query: "20 mile runs"
      {
        "conditions": [
          {
            "column": "distance",
            "operator": "BETWEEN",
            "value": [32086.8, 32286.8]
          }
        ],
        "order": null,
        "limit": null
      }

      Query: "runs longer than 10 km"
      {
        "conditions": [
          {
            "column": "distance",
            "operator": ">",
            "value": 10000
          }
        ],
        "order": null,
        "limit": null
      }

      Query: "easy runs under 30 minutes"
      {
        "conditions": [
          {
            "column": "average_heart_rate",
            "operator": "<",
            "value": 130
          },
          {
            "column": "elapsed_time",
            "operator": "<",
            "value": 1800
          }
        ],
        "order": null,
        "limit": null
      }

      Query: "my hardest runs with the most kudos"
      {
        "conditions": [
          {
            "column": "average_heart_rate",
            "operator": ">",
            "value": 150
          }
        ],
        "order": {
          "column": "kudos_count",
          "direction": "desc"
        },
        "limit": null
      }

      Query: "my fastest 5k runs"
      {
        "conditions": [
          {
            "column": "distance",
            "operator": "BETWEEN",
            "value": [4900, 5100]
          }
        ],
        "order": {
          "column": "elapsed_time",
          "direction": "asc"
        },
        "limit": null
      }

      RESPONSE FORMAT:
      Return ONLY valid JSON with no extra text or explanations.
    PROMPT
  end
end
