class UsersController < ApplicationController
  before_action :not_signed_in_users_only, :only => :new
  before_action :admin_only, :only => [:index, :set_admin, :code]
  before_action :current_user_only, :only => [:edit, :update]

  def index
    @users = User.all
  end

  def new
    @user = User.new
  end

  def create
    @user = User.create(user_params)
    if @user.save
      sign_in @user
      redirect_to_stored_location_or problems_path
    else
      render 'new'
    end
  end

  def show
    @user = User.find(params[:id])
  end

  def edit
    @user = User.find(params[:id])
  end

  def update
    @user = User.find(params[:id])
    if @user.update_attributes(user_params)
      render 'show'
    else
      render 'edit'
    end
  end

  def set_admin
    @user = User.find(params[:id])
    @user.update_attribute(:admin, set_admin_params)
    render 'show'
  end

  # Show list code written by user
  def code
    @user  = User.find(params[:id])
    @codes = @user.codes + @user.submissions
  end

  private

  def user_params
    params.require(:user).permit(:username, :school, :email, :password, :password_confirmation)
  end

  def set_admin_params
    params.require(:user).require(:admin)
  end
end
