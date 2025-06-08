module ActivitiesHelper
  def meters_to_miles(meters)
    if meters.nil? || meters == 0
      0
    else
      (meters * 0.000621371).round(2)
    end
  end

  def format_duration(seconds)
    return "0s" if seconds.nil? || seconds == 0

    hours = seconds / 3600
    minutes = (seconds % 3600) / 60
    remaining_seconds = seconds % 60

    parts = []
    parts << "#{hours}h" if hours > 0
    parts << "#{minutes}m" if minutes > 0
    parts << "#{remaining_seconds}s" if remaining_seconds > 0 || parts.empty?

    parts.join(" ")
  end
end
