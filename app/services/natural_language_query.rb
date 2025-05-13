class NaturalLanguageQuery
  # Distance conversion constant: 1 mile = 1609.34 meters

  def initialize(query)
    @query = query
  end

  def execute_query
    # Use GPT to generate an appropriate ActiveRecord query string
    query_string = generate_query_with_gpt(@query)

    # Execute the query safely
    safely_execute_query(query_string)
  end

  private

  def generate_query_with_gpt(query)
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
            content: "Convert this natural language query to an ActiveRecord query: #{query}"
          }
        ],
        temperature: 0.1
      }
    )

    result = response.dig("choices", 0, "message", "content").strip
    Rails.logger.debug "NaturalLanguageQuery: GPT response: #{result}"

    result
  end

  def safely_execute_query(query_string)
    # Verify the query only contains safe operations (only read operations)
    if query_string =~ /\A\s*Activity\.where.*\z/i &&
       query_string !~ /update|delete|destroy|create|save|insert|drop|truncate|exec|execute/i

      begin
        # Execute the query
        Rails.logger.info "NaturalLanguageQuery: Executing query: #{query_string}"
        eval(query_string)
      rescue => e
        Rails.logger.error "NaturalLanguageQuery: Error executing query: #{e.message}"
        Activity.none
      end
    else
      Rails.logger.error "NaturalLanguageQuery: Potentially unsafe query rejected: #{query_string}"
      Activity.none
    end
  end

  def system_prompt_for_query_generation
    <<~PROMPT
      You are a Ruby on Rails expert specializing in building ActiveRecord queries. Your job is to#{' '}
      translate natural language requests about running activities into executable Rails ActiveRecord#{' '}
      query code.

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

      GUIDELINES:
      1. ALWAYS start with 'Activity.where(activity_type: "Run")'#{' '}
      2. Add appropriate where clauses based on the query
      3. Use proper ActiveRecord syntax with '?' placeholders for values
      4. Convert all units appropriately (miles → meters, minutes → seconds)
      5. Handle relative terms appropriately:
         - "long runs" → distance > 10 miles (in meters)
         - "short runs" → distance < 5 miles (in meters)
         - "easy runs" → average_heart_rate < 130
         - "hard runs" → average_heart_rate > 150
         - "moderate runs" → average_heart_rate between 130-150
      6. Return ONLY the Ruby code, no explanations

      EXAMPLES:

      Query: "20 mile runs"
      Activity.where(activity_type: "Run").where("distance BETWEEN ? AND ?", 32186.8 - 100, 32186.8 + 100)

      Query: "runs longer than 10 km"
      Activity.where(activity_type: "Run").where("distance > ?", 10000)

      Query: "easy runs under 30 minutes"
      Activity.where(activity_type: "Run").where("average_heart_rate < ?", 130).where("elapsed_time < ?", 1800)

      Query: "my hardest runs with the most kudos"
      Activity.where(activity_type: "Run").where("average_heart_rate > ?", 150).order(kudos_count: :desc)

      Query: "short morning runs this week"
      Activity.where(activity_type: "Run")
              .where("distance < ?", 8046.7)
              .where("start_date_local BETWEEN ? AND ?", Date.today.beginning_of_week, Date.today.end_of_week)
              .where("STRFTIME('%H', start_date_local) < ?", '12')

      Query: "my fastest 5k runs"
      Activity.where(activity_type: "Run")
              .where("distance BETWEEN ? AND ?", 5000 - 100, 5000 + 100)
              .order(elapsed_time: :asc)

      RESPONSE FORMAT:
      Return ONLY valid Ruby ActiveRecord query code with no extra text or explanations.
    PROMPT
  end
end
