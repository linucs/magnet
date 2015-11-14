class BoardCleanupWorker
  include Sidekiq::Worker
  include Sidekiq::Benchmark::Worker

  sidekiq_options retry: true, backtrace: true

  def perform(id)
    benchmark do |bm|
      bm.drop_cards_collection do
        Card.for_board(id).collection.drop
        Card.index_for_board(id).delete if Figaro.env.enable_elasticsearch_indexing.to_b
      end
    end
  end
end
