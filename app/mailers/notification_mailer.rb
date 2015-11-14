class NotificationMailer < ActionMailer::Base
  default from: Figaro.env.notification_mailer_sender

  def token_expired(f)
    @feed = f

    mail to: @feed.user.email, subject: "Expired #{@feed.authentication_provider.title} credentials"
  end
end
