class SessionsController < ApplicationController
  before_action :signed_in

  def new
  end

  def create
    user = User.find_by(:email => session_params[:email])
    if user && user.authenticate(session_params[:password])
      sign_in(user)
      redirect_to problems_path
    else
      render 'new'
    end
  end

  private

  def session_params
    params.require(:session).permit(:email, :password)
  end

  def signed_in
    redirect_to problems_path if signed_in?
  end
end