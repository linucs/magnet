require 'sidekiq/api'

module Sidekiq
  def self.is_running?
    Sidekiq::ProcessSet.new.size > 0
  end
end

Sidekiq.configure_server do |config|
  schedule_file = "config/schedule.yml"

  if File.exists?(schedule_file) && Sidekiq.server?
    Sidekiq::Cron::Job.load_from_hash YAML.load_file(schedule_file)
  end
end
