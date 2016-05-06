class MaintenanceWorker
  include Sidekiq::Worker
  include Sidekiq::Benchmark::Worker

  def perform
    benchmark do |bm|
      bm.boards_cleanup do
        Board.transient.where('boards.created_at < ?', 1.day.ago).destroy_all
        Card.cleanup_dead_boards
      end
      bm.feeds_cleanup { Card.cleanup_dead_feeds }
      Feed.restart_dead!
    end
  end
end
