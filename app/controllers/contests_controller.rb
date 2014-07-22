class ContestsController < ApplicationController
  before_action :only_admin, :only => [:new, :create, :edit, :update]
  before_action :must_be_signed_in, :only => [:participate]
  before_action :correct_access, :only => :show

  def index
    @contests = Contest.all
  end

  def new
    @contest = Contest.new
  end

  def create
    @contest = Contest.create(contest_params)
    if @contest.save
      @contest.update_attribute(:creator_id, current_user.id)
      redirect_to contests_path
    else
      render 'new'
    end
  end

  def show
    @contest = Contest.find(params[:id])
  end

  def edit
    @contest = Contest.find(params[:id])
  end

  def update
    @contest = Contest.find(params[:id])
    if @contest.update_attributes(contest_params)
      render 'show'
    else
      render 'edit'
    end
  end

  def participate
    @contest = Contest.find(params[:id])
    @contest.participant_ids |= [current_user.id]
    redirect_to @contest
  end

  private

  def contest_params
    params.require(:contest).permit(:title, :start, :end, :visibility, :participation, { :problem_ids => [] }, { :invited_user_ids => [] })
  end

  def only_admin
    redirect_to contests_path unless signed_in? && current_user.admin?
  end

  def must_be_signed_in
    redirect_to contests_path unless signed_in?
  end

  def correct_access
    redirect_to contests_path unless Contest.find(params[:id]).visible_to?(current_user)
  end
end
