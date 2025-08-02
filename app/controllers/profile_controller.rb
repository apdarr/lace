class ProfileController < ApplicationController
  def show
    @user = Current.user
  end
end
