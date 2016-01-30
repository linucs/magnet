class PollWorker
  include Sidekiq::Worker

  def perform
    Board.poll_enabled
  end
end
