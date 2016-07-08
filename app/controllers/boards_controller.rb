class BoardsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_board, only: [:show, :edit, :update, :destroy, :poll, :users, :filters, :options, :analytics, :charts, :tag_cloud, :wall]

  add_crumb('Social collections') { |instance| instance.send :boards_path }

  helper_method :editing_in_place?

  respond_to :js

  class AnalyticsOptions < Struct.new(:provider_name, :since, :until, :by)
    include ActiveModel::Model

    def self.from_hash(h)
      obj = self.new
      obj.provider_name = h ? h[:provider_name] : nil
      obj.since = h ? (DateTime.parse(h[:since]) rescue 1.month.ago) : 1.month.ago
      obj.until = h ? (DateTime.parse(h[:until]) rescue Time.zone.now) : Time.zone.now
      obj.by = h ? h[:by] || 'day' : 'day'
      obj
    end

    def to_hash
      { provider_name: self.provider_name, since: self.since, until: self.until, by: self.by }
    end
  end

  def index
    load_boards
    respond_with(@boards) do |format|
      format.html { render }
    end
  end

  def new
    @board = Board.new
    respond_with(@board)
  end

  def show
    add_crumb @board.name, board_path(@board)
    @search_term = params[:s][:content] if params[:s]
    collection = if @search_term.present? && Figaro.env.enable_elasticsearch_indexing.to_b
      Card.index_for_board(@board.id).filter(or: [
        { term: { from: @search_term.strip } },
        { term: { content: @search_term.strip } }
      ]).load
    else
      @board.search_cards(params[:q], params[:order])
    end
    @cards = collection.page(params[:page])
    @feeds = @board.feeds.order('created_at DESC').page(params[:page])
    respond_with(@cards) do |format|
      format.html { render }
    end
  end

  def edit
  end

  def users
  end

  def filters
  end

  def options
  end

  def create
    @board = current_user.boards.create(board_params)
    respond_with(@board) do |_format|
      # format.js do
      #   load_boards
      #   @board = Board.new if @board.valid?
      # end
    end
  end

  def update
    @board.update(board_params)
    respond_with(@board) do |format|
      format.js { load_boards }
    end
  end

  def destroy
    @board.destroy
    respond_with(@board) do |format|
      format.js { load_boards }
    end
  end

  def editing_in_place?
    params[:in_place].present?
  end

  def poll
    authorize! :poll, @board
    @board.poll(oldest: params[:oldest].present?)
    respond_with(@board) do |format|
      format.js { render nothing: true }
      format.html { redirect_to @board, notice: 'Searching new contents from any configured feed. Reload this page to get updates.' }
    end
  end

  def upload
    authorize! :upload, Board
    upload_params = params.require(:upload).permit(:file, :create_missing_categories, :poll_immediately, :include_text_only_cards, :discard_obscene_contents)
    if upload_params[:file].present?
      @upload_errors = []
      Board.create_from_csv(upload_params[:file], current_user,
                            upload_params[:create_missing_categories] == '1',
                            upload_params[:poll_immediately] == '1',
                            include_text_only_cards: upload_params[:include_text_only_cards] == '1',
                            discard_obscene_contents: upload_params[:discard_obscene_contents] == '1') do |discarded|
        @upload_errors << discarded
      end
    end
    load_boards
    respond_with(@boards)
  end

  def analytics
    @options = AnalyticsOptions.from_hash(params[:options])
  end

  def charts
    @options = AnalyticsOptions.from_hash(params[:options])
    @data = case params[:chart_id]
      when 'topics_summary' then @board.topics_summary(@options.to_hash)
      when 'top_contributors' then @board.top_contributors(@options.to_hash)
      when 'most_liked_people' then @board.most_liked_people(@options.to_hash)
      when 'most_shared_people' then @board.most_shared_people(@options.to_hash)
      when 'most_commented_people' then @board.most_commented_people(@options.to_hash)
      when 'top_influencers' then @board.top_influencers(@options.to_hash)
      when 'most_engaging_people' then @board.most_engaging_people(@options.to_hash)
      when 'buzz' then @board.feeds.map { |f| { name: "#{f.name}", data: @board.buzz({ feed_id: f.id }.merge(@options.to_hash || {})) } }
      when 'hashtags' then @board.hashtags(@options.to_hash)
    end

    respond_with(@board) do |format|
      format.json { render json: @data }
    end
  end

  def tag_cloud
    @limit = params[:limit].to_i > 0 ? params[:limit] : 100
    @tags = @board.hashtags(params[:options])
  end

  def wall
    @board.send_notification(params[:remote])
    render nothing: true
  end

  def hashtag
    if params[:persist].present?
      @hashtag = params[:persist]
      @board = Board.where(hashtag: @hashtag).first
      if @board
        @board.feeds.each { |f| f.update_attribute(:enabled, false) }
        @board.update_attributes(enabled: true, hashtag: nil)
        @board.users << current_user unless @board.user_ids.include?(current_user.id)
      end
    else
      @hashtag = params.require(:board).permit(:hashtag)[:hashtag].to_s.parameterize
      if @hashtag.size > 2
        @board = Board.where(hashtag: @hashtag).first || Board.create_for_hashtag(@hashtag, current_user)
        unless params[:commit] == 'Refresh' || @board.cards.count >= Card::PER_PAGE * 3
          @board.poll(high_priority: true, oldest: true)
        end
        @cards = @board.search_cards(params[:q], params[:order]).page(params[:page])
      end
    end

    respond_with(@cards)
  end

  private

  def load_boards
    @boards = available_boards.search(params[:q]).result.rank(:row_order).page(params[:page])
  end

  def set_board
    @board = available_boards.friendly.find(params[:id]) rescue Board.transient.friendly.find(params[:id])
  end

  def board_params
    params.require(:board).permit(:name, :slug, :row_order_position, :description, :icon, :remove_icon, :image, :remove_image,
    :cover, :remove_cover, :enabled, :label, :moderated, :include_text_only_cards, :discard_identical_images,
    :discard_obscene_contents, :polling_interval, :category_id, :trusted_users, :banned_users, :banned_words,
    :max_tags_per_card, :host, :full_street_address, :latitude, :longitude, :start_polling_at, :end_polling_at,
    user_ids: []).tap do |whitelisted|
      whitelisted[:options] = (@board.try(:options) || {}).to_h.merge(params[:board][:options] || {})
    end
  end
end
