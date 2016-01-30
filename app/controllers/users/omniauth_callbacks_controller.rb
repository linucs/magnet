class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def destroy
    @authentication = UserAuthentication.find(params[:id])
    @authentication.destroy

    redirect_to edit_user_registration_path
  end

  def twitter
    create
  end

  def instagram
    create
  end

  def tumblr
    create
  end

  def facebook
    create
  end

  def failure
    fail failure_message
  end

  private

  def create
    auth_params = request.env['omniauth.auth']
    provider = AuthenticationProvider.where(name: auth_params.provider).first
    authentication = provider.user_authentications.where(uid: auth_params.uid).first
    existing_user = current_user || User.where('email = ?', auth_params['info']['email']).first

    if authentication
      sign_in_with_existing_authentication(authentication)
    elsif existing_user
      create_authentication_and_sign_in(auth_params, existing_user, provider)
    else
      create_user_and_authentication_and_sign_in(auth_params, provider)
    end
  end

  def sign_in_with_existing_authentication(authentication)
    flash[:alert] = 'Successfully authenticated. You can now start fetching contents!'
    sign_in_and_redirect(:user, authentication.user)
  end

  def create_authentication_and_sign_in(auth_params, user, provider)
    UserAuthentication.create_from_omniauth(auth_params, user, provider)

    flash[:alert] = "Successfully authenticated to #{provider.title}. You can now start fetching contents!"
    sign_in_and_redirect(:user, user)
  end

  def create_user_and_authentication_and_sign_in(auth_params, provider)
    user = User.create_from_omniauth(auth_params)
    if user.valid?
      create_authentication_and_sign_in(auth_params, user, provider)
    else
      flash[:error] = user.errors.full_messages.first
      redirect_to new_user_registration_url
    end
  end
end
