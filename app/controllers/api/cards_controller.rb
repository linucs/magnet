class API::CardsController < API::BaseController
  respond_to :json

  def index
    options = { users: { id: current_user } }
    @cards = @ads = []
    @board = params[:category_id].present? ? Category.enabled.friendly.find(params[:category_id]).boards : Board
    @board = @board.includes(:users).enabled.where(options).friendly.find(params[:board_id])
    cards = @board.cards.online
    cards = if params[:latitude].present? && params[:longitude].present?
              cards.near(location: [params[:longitude].to_f, params[:latitude].to_f])
            else
              cards.default_order
    end
    paginate(cards.count, Card::PER_PAGE, allow_render: false) do |limit, offset|
      @cards = cards.offset(offset).limit(limit)
      @board.campaigns.triggered_on(params[:adv] || 100).rank(:row_order).each { |c| @ads << c.as_card }
      track_event("User #{current_user.id}", 'List cards', @board.name, 2 * offset + limit)
      respond_with(@cards)
    end
  end
end
