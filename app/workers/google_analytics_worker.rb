class GoogleAnalyticsWorker
  include Sidekiq::Worker

  def perform(code, options = {})
    defaults = {
      document_location: options['referer'],
      referrer: options['referer'],
      user_ip: options['remote_ip'],
      user_agent: options['user_agent']
    }
    Staccato.tracker(code, nil, defaults).event(category: options['category'],
                                                action: options['action'],
                                                label: options['label'],
                                                value: options['value'])
    tracker = Staccato.tracker(Figaro.env.google_analytics_code, nil, defaults)
    tracker.pageview(title: options['label'])
    tracker.timing(page_load_time: options['time']) if options['time']
  end
end
