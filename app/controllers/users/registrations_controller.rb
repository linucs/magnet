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
    devise_parameter_sanitizer.permit(:sign_up, keys: User::WHITELISTED_ATTRIBUTES)
  end

  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update, keys: User::WHITELISTED_ATTRIBUTES)
  end
end
