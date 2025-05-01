class NaturalLanguageQuery
  def initialize(query)
    @query = query
  end

  def execute_query
    # Get the query from OpenAI
    response = openai_client.chat(
      parameters: {
        model: "gpt-4.1-nano",          # use the latest small GPT model
        messages: [
          {
            role: "system",
            content: system_prompt
          },
          {
            role: "user",
            content: "Convert this search to an ActiveRecord query: #{@query}"
          }
        ],
        temperature: 0.2
      }
    )

    query_code = response.dig("choices", 0, "message", "content").strip

    # Execute the query safely
    execute_safe_query(query_code)
  end

  private

  def system_prompt
    <<~PROMPT
      You translate English questions about a user’s workouts into **Ruby ActiveRecord** code
      that queries the `activities` table.  Assume **all queries are about RUNS**.

      ── schema ─────────────────────────────────────────────────────────────
      activities(
        distance:float          # miles
        elapsed_time:integer    # seconds
        kudos_count:integer
        average_heart_rate:float
        max_heart_rate:float
        description:string
        start_date_local:datetime
      )
      ───────────────────────────────────────────────────────────────────────

      RULES
      1. Output only Ruby – no prose, no markdown.
      2. Always start with `Activity`.
      3. Always filter runs: append `.where(activity_type: 'Run')` unless a
         different filter is already provided.
      4. Distance language
         • “long / longer / over / more than / greater than X miles” → `distance > X`
         • “short / shorter / under / less than X miles”             → `distance < X`
      5. Intensity shortcuts
         • easy   → avg HR < 130
         • hard   → avg HR > 150
         • moderate → 130‑150
      6. Time windows
         • today, yesterday, last week, last month → translate to Ruby ranges.
      7. Sorting
         • longest / farther          → order(distance: :desc)
         • shortest                   → order(distance: :asc)
         • fastest (elapsed_time)     → order(elapsed_time: :asc)
         • slowest                    → order(elapsed_time: :desc)
         • most kudos                 → order(kudos_count: :desc)
      8. Limits
         Detect “top/first/last N” or explicit counts and use `.limit(N)`.
      9. Combine filters with chained where‑clauses.

      EXAMPLES (copy pattern exactly)

      "runs longer than 20 miles"
      Activity.where(activity_type: 'Run').where('distance > ?', 20).order(distance: :desc)

      "show me runs shorter than 3 miles"
      Activity.where(activity_type: 'Run').where('distance < ?', 3).order(distance: :asc)

      "my hardest runs"
      Activity.where(activity_type: 'Run').where('average_heart_rate > ?', 150).order(average_heart_rate: :desc)

      "easy runs under 30 minutes"
      Activity.where(activity_type: 'Run')
              .where('elapsed_time < ? AND average_heart_rate < ?', 1800, 130)
              .order(elapsed_time: :asc)

      "top 5 longest morning runs"
      Activity.where(activity_type: 'Run')
              .where("strftime('%H', start_date_local) < ?", '12')
              .order(distance: :desc)
              .limit(5)

      "yesterday's runs with the most kudos"
      Activity.where(activity_type: 'Run')
              .where('start_date_local BETWEEN ? AND ?', 1.day.ago.beginning_of_day, 1.day.ago.end_of_day)
              .order(kudos_count: :desc)

      Respond with a single ActiveRecord expression following these rules.
    PROMPT
  end

  def openai_client
    @openai_client ||= OpenAI::Client.new
  end

  def execute_safe_query(code)
    # Only allow certain query patterns for safety
    if code.match?(/\A(Activity\.(where|find_by|order|limit|joins|includes|group|having))/)
      begin
        Rails.logger.info("Executing query: #{code}")
        eval(code)
      rescue => e
        Rails.logger.error("Error executing query: #{e.message}")
        Activity.none
      end
    else
      Rails.logger.error("Potentially unsafe query rejected: #{code}")
      Activity.none
    end
  end
end
