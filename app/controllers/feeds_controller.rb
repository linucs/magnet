class FeedsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_board
  before_action :set_feed, only: [:edit, :update, :destroy, :poll, :toggle_streaming]

  add_crumb('Collections') { |instance| instance.send :boards_path }

  helper_method :editing_in_place?

  respond_to :js

  def index
    load_feeds
    add_crumb @board.name, board_path(@board)
    add_crumb 'Feeds', board_feeds_path(@board)
    @feed = Feed.new
    respond_with(@feeds) do |format|
      format.html { render }
    end
  end

  def new
    @feed = Feed.new(authentication_provider: AuthenticationProvider.find(params[:authentication_provider_id]))
    respond_with(@feed)
  end

  def edit
  end

  def create
    @feed = Feed.new(feed_params)
    @feed.user = current_user
    @board ||= current_user.boards.create(name: @feed.board_name.present? ? @feed.board_name : @feed.name)
    if @board.persisted?
      @feed.board = @board
      @feed.poll(high_priority: true) if @feed.save
    else
      @board = nil
      @feed.valid?
    end
    respond_with(@feed) do |format|
      format.js do
        load_feeds unless editing_in_place?
        # @feed = Feed.new if @feed.valid? && !editing_in_place?
      end
    end
  end

  def update
    @feed.update(feed_params)
    respond_with(@feed) do |format|
      format.js { load_feeds }
    end
  end

  def destroy
    @feed.destroy
    respond_with(@feed) do |format|
      format.js { load_feeds }
    end
  end

  def poll
    @feed.poll
    respond_with(@feed)
  end

  def editing_in_place?
    params[:in_place].present?
  end

  def toggle_streaming
    if @feed.live_streaming?
      @feed.stop_streaming
      @feed.update_attribute(:live_streaming, false)
      @feed.update_attribute(:polling, false)
    else
      @feed.update_attribute(:live_streaming, true)
      @feed.stream
    end
    respond_with(@feed) do |format|
      format.js { load_feeds }
    end
  end

  private

  def set_board
    @board = available_boards.friendly.find(params[:board_id]) rescue nil
  end

  def load_feeds
    @feeds = @board.feeds.order('created_at DESC').page(params[:page])
  end

  def set_feed
    @feed = @board.feeds.find(params[:id])
  end

  def feed_params
    params.require(:feed).permit(:authentication_provider_id, :user_id, :name,
                                 :label, :enabled, :board_name, :live_streaming,
                                 options: Providers::Facebook.options.keys + Providers::Instagram.options.keys +
                                 Providers::Rss.options.keys + Providers::Tumblr.options.keys +
                                 Providers::Twitter.options.keys).tap do |whitelisted|
      whitelisted.delete(:user_id) if @board && !@board.user_ids.include?(params[:feed][:user_id].to_i)
    end
  end
end
