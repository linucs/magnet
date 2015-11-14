class MaintenanceWorker
  include Sidekiq::Worker
  include Sidetiq::Schedulable
  include Sidekiq::Benchmark::Worker

  recurrence { daily }

  def perform
    benchmark do |bm|
      bm.boards_cleanup { Card.cleanup_dead_boards }
      bm.feeds_cleanup { Card.cleanup_dead_feeds }
      Feed.restart_dead!
    end
  end
end
