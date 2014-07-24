class Submission < ActiveRecord::Base
  belongs_to :user, :validate => false
  belongs_to :task, :validate => false

  before_save do
    # Should this part be moved to bg worker?
    # One single such operation should be relatively cheap,
    # but what happens if we have lots of submissions coming in?
    # BTW, we do have a bg worker (sidekiq).
    # It is currently experimental and is available on the sidekiq-bg-worker branch

    self.accepted = correct_input?

    if user && task
      user.solved_tasks << task if accepted && !user.solved_tasks.include?(task)
      user.save

      if task.problem
        if task.problem.tasks.all? { |t| t.solvers.include?(user) }
          task.problem.solvers |= [user]
        end
      end
    end
  end

  def correct_input?
    input == task.output
  end
end
