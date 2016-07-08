class Users::RegistrationsController < Devise::RegistrationsController
  before_filter :configure_sign_up_params, only: [:create]
  before_filter :configure_account_update_params, only: [:update]

  def create
    if verify_recaptcha
      super
    else
      build_resource(sign_up_params)
      clean_up_passwords(resource)
      flash.now[:alert] = 'Invalid Recaptcha verification. Please try again.'
      flash.delete :recaptcha_error
      render :new
    end
  end

  protected

  def configure_sign_up_params
    User::WHITELISTED_ATTRIBUTES.each { |a| devise_parameter_sanitizer.for(:sign_up) << a }
  end

  def configure_account_update_params
    User::WHITELISTED_ATTRIBUTES.each { |a| devise_parameter_sanitizer.for(:account_update) << a }
  end
end
