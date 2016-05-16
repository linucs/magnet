class CardsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_board
  before_action :set_card, only: [:show, :edit, :update, :destroy, :trust, :ban, :cta]

  respond_to :js

  def new
    @card = Card.new
    respond_with(@card)
  end

  def show
    respond_with(@card)
  end

  def edit
  end

  def create
    @card = Card.new(card_params) do |c|
      c.external_id = SecureRandom.uuid
      c.from = current_user.email
      c.profile_image_url = gravatar_url(current_user)
    end
    Chewy.strategy(:atomic) do
      @card.for_board(@board.id).save
    end
    respond_with(@card) do |format|
      format.js { load_cards }
    end
  end

  def update
    @card.for_board(@board.id).update({ user_id: current_user.id }.merge(card_params))
    respond_with(@card)
  end

  def destroy
    @card.for_board(@board.id).update_attribute(:enabled, false)
    respond_with(@card) do |format|
      format.js { load_cards }
    end
  end

  def trust
    @board.trust_user(@card.from)
    @board.cards.where(from: @card.from).update_all(enabled: true, online: true)
    respond_with(@card) do |format|
      format.js { load_cards }
    end
  end

  def ban
    @board.ban_user(@card.from)
    @board.cards.where(from: @card.from).update_all(enabled: false)
    respond_with(@card) do |format|
      format.js { load_cards }
    end
  end

  def cta
  end

  def bulk_update
    card_ids = params[:card_ids]
    if card_ids.is_a?(Array) && card_ids.size > 0
      case params[:bulk_action]
      when 'publish'
        @board.cards.where(:id.in => card_ids).update_all(online: true)
      when 'un-publish'
        @board.cards.where(:id.in => card_ids).update_all(online: false)
      when 'delete'
        @board.cards.where(:id.in => card_ids).update_all(enabled: false)
      when 'refresh'
        @board.cards.where(:id.in => card_ids).each { |c| c.refresh rescue nil }
      when 'label'
        label = params[:value]
        if label.present?
          @board.cards.where(:id.in => card_ids).each do |c|
            labels = c.label.to_s.split ','
            c.for_board(@board.id).update_attribute(:label, (labels << label).join(',')) unless labels.include?(label)
          end
        end
      when 'un-label'
        @board.cards.where(:id.in => card_ids).each do |c|
          c.for_board(@board.id).update_attribute(:label, nil)
        end
      end
      respond_to do |format|
        format.js { load_cards }
      end
    else
      respond_to do |format|
        format.js { render js: 'alert("No cards were selected.\nClick on the top-right checkbox on each card, to perform this action on all selected ones.")' }
      end
    end
  end

  private

  def set_board
    @board = available_boards.friendly.find(params[:board_id]) rescue Board.transient.friendly.find(params[:board_id])
  end

  def set_card
    @card = @board.all_cards.find(params[:id])
  end

  def load_cards
    @cards = @board.search_cards(params[:q], params[:order]).page(params[:page])
  end

  def card_params
    params.require(:card).permit(:provider_name, :content, :content_source,
      :content_type, :original_content_url, :from, :profile_image_url, :online,
      :pinned, :content, :media_url, :embed_code, :thumbnail_image_url,
      :label, :rating, :notes, :custom_profile_image, :remove_custom_profile_image,
      :custom_media, :remove_custom_media, :custom_thumbnail_image,
      :remove_custom_thumbnail_image, :cta)
  end
end
