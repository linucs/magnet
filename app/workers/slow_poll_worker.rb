class SlowPollWorker
  include Sidekiq::Worker
  include Sidekiq::Benchmark::Worker

  sidekiq_options retry: false, backtrace: true, queue: :slow_poll

  def perform(id, oldest)
    if Feed.exists?(id)
      benchmark do |bm|
        bm.feed_poll { Feed.find(id).poll(oldest: oldest, foreground: true) }
      end
    end
  end
end
