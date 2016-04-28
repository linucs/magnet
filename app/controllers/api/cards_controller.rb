class API::CardsController < API::BaseController
  include Swagger::Blocks

  swagger_path '/boards/{id}/cards' do
    operation :get do
      key :description, 'Returns all cards belonging to a given board in the system, accessible by the calling user'
      key :operationId, 'findCards'
      key :tags, [
        'board'
      ]
      parameter do
        key :name, :id
        key :in, :path
        key :description, 'board internal ID (or slug) to filter by'
        key :required, true
        key :type, :string
      end
      parameter do
        key :name, :layout
        key :in, :query
        key :description, 'implicit display layout (used to trigger appropriate advertising campaigns)'
        key :required, false
        key :type, :string
        key :enum, %W(deck timeline wall)
      end
      parameter do
        key :name, :latitude
        key :in, :query
        key :description, 'card latitude to filter by (returns only geotagged contents)'
        key :required, false
        key :type, :float
      end
      parameter do
        key :name, :longitude
        key :in, :query
        key :description, 'card longitude to filter by (returns only geotagged contents)'
        key :required, false
        key :type, :float
      end
      parameter do
        key :name, :'Range-Unit'
        key :in, :header
        key :description, 'pagination range unit'
        key :required, false
        key :type, :string
        key :default, 'items'
      end
      parameter do
        key :name, :Range
        key :in, :header
        key :description, 'pagination range'
        key :required, false
        key :type, :string
        key :default, "0-#{Card::PER_PAGE - 1}"
      end
      response 200 do
        key :description, 'cards listing'
        schema do
          key :type, :array
          items do
            key :'$ref', :Card
          end
        end
      end
      response 404 do
        key :description, 'board not found or not accessible by the calling user'
      end
    end
  end

  respond_to :json

  def index
    options = { users: { id: current_user } }
    @cards = @ads = []
    @board = params[:category_id].present? ? Category.of_teammates(current_user).enabled.friendly.find(params[:category_id]).boards : Board
    @board = @board.includes(:users).enabled.where(options).friendly.find(params[:board_id])
    cards = @board.cards.online
    cards = if params[:latitude].present? && params[:longitude].present?
              cards.near(location: [params[:longitude].to_f, params[:latitude].to_f])
            else
              cards.default_order
            end
    paginate(cards.count, Card::PER_PAGE, allow_render: false) do |limit, offset|
      @cards = cards.offset(offset).limit(limit)
      @board.campaigns.triggered_on(params[:adv] || 100).rank(:row_order).each { |c| @ads << c.as_card if c.displayable?(params[:layout]) }
      track_event("User #{current_user.id}", 'List cards', @board.name, 2 * offset + limit)
      respond_with(@cards)
    end
  end
end
