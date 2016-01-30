require 'sidekiq/api'
require 'sidekiq/logging/json'

Sidekiq.logger.formatter = Sidekiq::Logging::Json::Logger.new

module Sidekiq
  def self.is_running?
    Sidekiq::ProcessSet.new.size > 0
  end
end

schedule_file = "config/schedule.yml"

if File.exists?(schedule_file) && Sidekiq.server?
  Sidekiq::Cron::Job.load_from_hash YAML.load_file(schedule_file)
end
