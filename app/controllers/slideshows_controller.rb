class SlideshowsController < ApplicationController
  before_action :set_board
  after_action :allow_iframe, if: :externally_embedded?

  layout false
  respond_to :html

  helper_method :unless_external_asset?
  helper_method :externally_embedded?

  def show
    deck
    render action: :deck
  end

  def wall
    gon.header_url = @board.options.wall_custom_header_url.present? ? @board.options.wall_custom_header_url : nil
    gon.template_url = @board.options.wall_custom_template_url.present? ? @board.options.wall_custom_template_url : Board::DEFAULT_WALL_TEMPLATE_URL
    gon.footer_url = @board.options.wall_custom_footer_url.present? ? @board.options.wall_custom_footer_url : nil
    gon.wall_width = @board.options.wall_width.present? ? @board.options.wall_width : Board::DEFAULT_WALL_WIDTH
    gon.wall_height = @board.options.wall_height.present? ? @board.options.wall_height : Board::DEFAULT_WALL_HEIGHT
    gon.wall_page_size = @board.options.wall_page_size.present? ? @board.options.wall_page_size : Board::DEFAULT_WALL_PAGE_SIZE
    gon.wall_auto_slide = @board.options.wall_auto_slide.present? ? @board.options.wall_auto_slide.to_i * 1000 : Board::DEFAULT_WALL_AUTO_SLIDE
    gon.wall_center = @board.options.wall_center == '1'
    if @board.options.wall_custom_background_image_style == 'parallax'
      gon.wall_background_image_size = @board.options.wall_background_image_size.present? ? @board.options.wall_background_image_size : "#{gon.wall_width.to_i * 2}px #{gon.wall_height}px"
    end
    gon.websocketUrl = "#{Figaro.env.websocket_host}:#{Figaro.env.websocket_port}/websocket"
  end

  def timeline
    gon.header_url = @board.options.timeline_custom_header_url.present? ? @board.options.timeline_custom_header_url : nil
    gon.template_url = @board.options.timeline_custom_template_url.present? ? @board.options.timeline_custom_template_url : Board::DEFAULT_TIMELINE_TEMPLATE_URL
    gon.footer_url = @board.options.timeline_custom_footer_url.present? ? @board.options.timeline_custom_footer_url : nil
  end

  def deck
    redirect_to(slideshow_path(@board, :timeline)) and return if @board.options.deck_detect_mobile_devices.to_b && browser.mobile?

    gon.header_url = @board.options.deck_custom_header_url.present? ? @board.options.deck_custom_header_url : nil
    gon.template_url = @board.options.deck_custom_template_url.present? ? @board.options.deck_custom_template_url : Board::DEFAULT_DECK_TEMPLATE_URL
    gon.footer_url = @board.options.deck_custom_footer_url.present? ? @board.options.deck_footer_url : nil
  end

  def sample
    @layout = params[:layout] || 'deck'
    send_data render_to_string(template: "slideshows/samples/#{@layout}"), filename: "#{@layout}-sample.html"
  end

  private

  def set_board
    @board = params[:id] ? Board.enabled.friendly.find(params[:id]) : Board.enabled.where(host: request.host).first
    if @board
      gon.api_host = Figaro.env.api_host
      gon.user_token = @board.users.first.try(:authentication_token)
      gon.board_id = @board.id
      gon.board_name = @board.name
      gon.board_description = @board.description
      gon.board_image_url = @board.image.url
      gon.board_cover_url = @board.cover.url
    else
      render 'cover', layout: 'application'
    end
  end

  def unless_external_asset?(path)
    file = File.join(Rails.root, 'public', 'system', 'boards', @board.id.to_s, path)
    File.exist?(file) ? render_to_string(file) : yield
  end

  def externally_embedded?
    params[:embed]
  end

  def allow_iframe
    response.headers.except! 'X-Frame-Options'
  end
end
