class SessionsController < ApplicationController
  allow_unauthenticated_access only: :create
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to root_url, alert: "Try again later." }

  def create
    auth = request.env["omniauth.auth"]
    user = User.find_or_create_from_strava(auth)

    if user.persisted?
      session = Session.create!(
        user: user,
        ip_address: request.remote_ip,
        user_agent: request.user_agent
      )
      cookies.signed[:session_id] = { value: session.id, httponly: true }
      redirect_to root_path, notice: "Successfully signed in with Strava!"
    else
      redirect_to root_path, alert: "Failed to sign in with Strava."
    end
  end

  def destroy
    terminate_session
    redirect_to root_path
  end
end
