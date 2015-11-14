require 'sidekiq/api'
require 'sidekiq/logging/json'

Sidekiq.logger.formatter = Sidekiq::Logging::Json::Logger.new

module Sidekiq
  def self.is_running?
    Sidekiq::ProcessSet.new.size > 0
  end
end
