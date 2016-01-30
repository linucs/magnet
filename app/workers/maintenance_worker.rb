class MaintenanceWorker
  include Sidekiq::Worker
  include Sidekiq::Benchmark::Worker

  def perform
    benchmark do |bm|
      bm.boards_cleanup { Card.cleanup_dead_boards }
      bm.feeds_cleanup { Card.cleanup_dead_feeds }
      Feed.restart_dead!
    end
  end
end
