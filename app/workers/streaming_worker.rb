# Sidekiq worker for Twitter streming

class StreamingWorker
  include Sidekiq::Worker

  def perform(id)
    return unless Feed.exists?(id)
    @id = id
    Feed.find(id).stream(foreground: true) do |_client, _tweet|
      !cancelled?
    end
  end

  def cancelled?
    Sidekiq.redis { |c| c.del("cancelled-streaming-#{@id}") > 0 }
  end

  def self.cancel!(id)
    Sidekiq.redis { |c| c.setex("cancelled-streaming-#{id}", 86_400, 1) }
  end
end
