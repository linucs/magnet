Recaptcha.configure do |config|
  config.public_key  = Figaro.env.google_recaptcha_key
  config.private_key = Figaro.env.google_recaptcha_secret
  # Uncomment the following line if you are using a proxy server:
  # config.proxy = 'http://myproxy.com.au:8080'
end
