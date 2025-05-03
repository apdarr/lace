class NaturalLanguageQuery
  # Distance conversion constant: 1 mile = 1609.34 meters
  MILES_TO_METERS = 1609.34
  
  DISTANCE_PATTERNS = {
    /(\d+(\.\d+)?)\s*(mi(les?)?|km)/i => ->(m) { m[1].to_f },
    /long(er)?\s*(run|distance)/i => ->(m) { 15.0 },
    /short(er)?\s*(run|distance)/i => ->(m) { 5.0 },
    /medium\s*(run|distance)/i => ->(m) { 10.0 }
  }

  HEART_RATE_PATTERNS = {
    /easy\s*(run|effort|intensity)/i => ->(m) { 130 },
    /moderate\s*(run|effort|intensity)/i => ->(m) { 140 },
    /(hard|intense|difficult)\s*(run|effort|intensity)/i => ->(m) { 160 },
    /high\s*(heart\s*rate)/i => ->(m) { 160 }
  }

  TIME_PATTERNS = {
    /(\d+)\s*(hour|hr)s?/i => ->(m) { m[1].to_i * 3600 },
    /(\d+)\s*(minute|min)s?/i => ->(m) { m[1].to_i * 60 },
    /(\d+)\s*(second|sec)s?/i => ->(m) { m[1].to_i },
    /long\s*time/i => ->(m) { 5400 },
    /short\s*time|quick/i => ->(m) { 1800 }
  }

  KUDOS_PATTERNS = {
    /(popular|most\s*liked)/i => ->(m) { 10 },
    /(\d+)\s*kudos/i => ->(m) { m[1].to_i }
  }

  def initialize(query)
    @query = query
  end

  def execute_query
    # Start with a base query for runs
    query = Activity.where(activity_type: 'Run')
    
    # Apply filters based on the parsed query components, chaining them
    query = apply_distance_filter(query)
    query = apply_heart_rate_filter(query)
    query = apply_time_filter(query)
    query = apply_kudos_filter(query)
    
    # Return the final filtered query
    query
  end

  private

  def apply_distance_filter(query)
    DISTANCE_PATTERNS.each do |pattern, value_proc|
      if @query.match?(pattern)
        match = @query.match(pattern)
        distance_in_miles = value_proc.call(match)
        
        # Convert miles to meters for Strava API data
        distance_in_meters = distance_in_miles * MILES_TO_METERS
        
        Rails.logger.debug "NaturalLanguageQuery: Parsed distance #{distance_in_miles} miles (#{distance_in_meters} meters) from query '#{@query}'"
        
        if @query =~ /more than|greater than|over|above|longer than/i
          Rails.logger.debug "NaturalLanguageQuery: Applying '> #{distance_in_meters}' filter"
          return query.where('distance > ?', distance_in_meters)
        elsif @query =~ /less than|under|below|shorter than/i
          Rails.logger.debug "NaturalLanguageQuery: Applying '< #{distance_in_meters}' filter"
          return query.where('distance < ?', distance_in_meters)
        elsif @query =~ /about|around|approximately/i
          range_min = distance_in_meters * 0.9
          range_max = distance_in_meters * 1.1
          Rails.logger.debug "NaturalLanguageQuery: Applying 'between #{range_min} and #{range_max}' filter"
          return query.where('distance BETWEEN ? AND ?', range_min, range_max)
        else
          # Default: find activities with distance close to the specified value
          # Use a percentage-based tolerance to account for potential variations
          range_min = distance_in_meters * 0.9
          range_max = distance_in_meters * 1.1
          Rails.logger.debug "NaturalLanguageQuery: Applying default 'between #{range_min} and #{range_max}' filter"
          return query.where('distance BETWEEN ? AND ?', range_min, range_max)
        end
      end
    end
    
    Rails.logger.debug "NaturalLanguageQuery: No distance pattern matched for query '#{@query}'"
    query
  end

  def apply_heart_rate_filter(query)
    HEART_RATE_PATTERNS.each do |pattern, value_proc|
      if @query.match?(pattern)
        match = @query.match(pattern)
        heart_rate = value_proc.call(match)
        
        if @query =~ /high|higher|above/i && !@query.match?(/high\s*(heart\s*rate)/i)
          return query.where('average_heart_rate > ?', heart_rate)
        elsif @query =~ /low|lower|below/i
          return query.where('average_heart_rate < ?', heart_rate)
        elsif @query =~ /easy/i
          return query.where('average_heart_rate < ?', heart_rate)
        elsif @query =~ /hard|intense|difficult/i
          return query.where('average_heart_rate > ?', heart_rate)
        else
          # Default: find activities with similar heart rate (within 10 bpm)
          return query.where('average_heart_rate BETWEEN ? AND ?', heart_rate - 10, heart_rate + 10)
        end
      end
    end
    
    query
  end

  def apply_time_filter(query)
    TIME_PATTERNS.each do |pattern, value_proc|
      if @query.match?(pattern)
        match = @query.match(pattern)
        time = value_proc.call(match)
        
        if @query =~ /more than|longer than|over|above/i
          return query.where('elapsed_time > ?', time)
        elsif @query =~ /less than|shorter than|under|below/i
          return query.where('elapsed_time < ?', time)
        elsif @query =~ /about|around|approximately/i
          return query.where('elapsed_time BETWEEN ? AND ?', time * 0.9, time * 1.1)
        else
          # Default: find activities with similar time (within 20%)
          return query.where('elapsed_time BETWEEN ? AND ?', time * 0.8, time * 1.2)
        end
      end
    end
    
    query
  end

  def apply_kudos_filter(query)
    KUDOS_PATTERNS.each do |pattern, value_proc|
      if @query.match?(pattern)
        match = @query.match(pattern)
        kudos = value_proc.call(match)
        
        if @query =~ /more than|over|above|high(er)?|most/i
          return query.where('kudos_count > ?', kudos)
        elsif @query =~ /less than|under|below|low(er)?|least/i
          return query.where('kudos_count < ?', kudos)
        else
          # Default: find activities with at least this many kudos
          return query.where('kudos_count >= ?', kudos)
        end
      end
    end
    
    query
  end
end
