json.extract! activity, :id, :distance, :elapsed_time, :type, :kudos_count, :average_heart_rate, :max_heart_rate, :description, :created_at, :updated_at
json.url activity_url(activity, format: :json)
