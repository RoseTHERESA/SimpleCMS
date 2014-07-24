class Task < ActiveRecord::Base
  belongs_to :problem
  has_many :submissions
  has_and_belongs_to_many :solvers, :class_name => "User", :join_table => "solved_tasks"

  def solved_by?(user)
    solvers.include?(user)
  end

  def attempted_by?(user)
    user.submissions.where("task_id = #{id}").any?
  end

  def cache_solved_status(user)
    if solved_by?(user)
      self.solvers |= [user]
    else
      self.solvers.delete(user)
    end
  end
end
