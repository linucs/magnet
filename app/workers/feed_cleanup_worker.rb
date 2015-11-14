class FeedCleanupWorker
  include Sidekiq::Worker
  include Sidekiq::Benchmark::Worker

  sidekiq_options retry: true, backtrace: true

  def perform(board_id, id)
    benchmark do |bm|
      bm.purge_destroyed_feed_contents do
        Chewy.strategy(:atomic) do
          Card.for_board(board_id).where(feed_id: id).destroy_all
        end
      end
    end
  end
end
