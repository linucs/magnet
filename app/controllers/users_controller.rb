class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, only: [:edit, :update, :destroy]

  add_crumb('Platform users') { |instance| instance.send :users_path }

  respond_to :js

  def index
    load_users
    authorize! :index, User
    respond_with(@users) do |format|
      format.html { render }
    end
  end

  def new
    @user = User.new
    respond_with(@user)
  end

  def edit
    authorize! :edit, @user
  end

  def create
    @user = User.new(user_params)
    authorize! :create, @user
    @user.save
    respond_with(@user) do |format|
      format.js do
        load_users
      end
    end
  end

  def update
    authorize! :update, @user
    @user.update(user_params)
    respond_with(@user) do |format|
      format.js { load_users }
    end
  end

  def destroy
    authorize! :destroy, @user
    @user.destroy
    respond_with(@user) do |format|
      format.js { load_users }
    end
  end

  private

  def load_users
    @users = User.search(params[:q]).result.page(params[:page])
  end

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation,
      :admin, :notify_exceptions, :max_feeds, :expires_at)
  end
end
