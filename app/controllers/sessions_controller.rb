class SessionsController < ApplicationController
  allow_unauthenticated_access only: [ :new, :create, :failure ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to root_url, alert: "Try again later." }

  def new
    render :new
  end

  def create
    auth = request.env["omniauth.auth"]

    if auth.blank?
      redirect_to new_session_path, alert: "Authentication failed. Please try again."
      return
    end

    if linking_strava?(auth)
      link_strava_account(auth)
    else
      sign_in_user(auth)
    end
  end

  def failure
    redirect_to new_session_path, alert: "Authentication failed: #{params[:message]&.humanize}."
  end

  def destroy
    terminate_session
    redirect_to root_path, notice: "Successfully signed out!"
  end

  private

  def linking_strava?(auth)
    request.env["omniauth.origin"] == "link_strava" && authenticated? && auth.provider == "strava"
  end

  def link_strava_account(auth)
    existing_user = User.find_by(strava_id: auth.uid)

    if existing_user && existing_user != Current.user
      redirect_to edit_profile_path, alert: "This Strava account is already linked to another user."
      return
    end

    Current.user.link_strava!(auth)
    redirect_to edit_profile_path, notice: "Strava account connected successfully!"
  end

  def sign_in_user(auth)
    user = find_or_create_user(auth)

    if user.persisted?
      start_new_session_for(user)
      redirect_to root_path, notice: "Successfully signed in!"
    else
      redirect_to root_path, alert: "Failed to sign in."
    end
  end

  def find_or_create_user(auth)
    case auth.provider
    when "strava"
      User.find_or_create_from_strava(auth)
    when "google_oauth2"
      User.find_or_create_from_google(auth)
    else
      raise "Unsupported OAuth provider: #{auth.provider}"
    end
  end
end
