module ActivitiesHelper
  def meters_to_miles(meters)
    if meters.nil? || meters == 0
      0
    else
      (meters * 0.000621371).round(2)
    end
  end
end
