require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Magnet
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    unless Rails.env.development?
      config.middleware.use Rack::Throttle::Hourly, :cache => Redis.new, :key_prefix => :throttle
    end

    config.middleware.use Rack::Cors do
      allow do
        origins '*'
        resource '*',
          :headers => :any,
          :methods => [:get, :options],
          :expose => ['Content-Range', 'Accept-Ranges']
      end
    end

    config.action_cable.mount_path = '/cable'
    config.action_cable.disable_request_forgery_protection = true
  end

  def self.capture_exception(e, context = {})
    Rails.logger.error e
  end
end
