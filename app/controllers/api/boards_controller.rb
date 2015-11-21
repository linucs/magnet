class API::BoardsController < API::BaseController
  include Swagger::Blocks

  swagger_path '/boards' do
    operation :get do
      key :description, 'Returns all boards in the system accessible by the calling user'
      key :operationId, 'findBoards'
      key :tags, [
        'board'
      ]
      parameter do
        key :name, :label
        key :in, :query
        key :description, 'board label to filter by'
        key :required, false
        key :type, :string
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
        key :name, :'Range'
        key :in, :header
        key :description, 'pagination range'
        key :required, false
        key :type, :string
        key :default, "0-#{Board::PER_PAGE - 1}"
      end
      response 200 do
        key :description, 'boards listing'
        schema do
          key :type, :array
          items do
            key :'$ref', :Board
          end
        end
      end
    end
  end

  swagger_path '/boards/{id}' do
    operation :get do
      key :description, 'Returns a single board, when accessible by the calling user'
      key :operationId, 'findByBoardId'
      key :tags, [
        'board'
      ]
      parameter do
        key :name, :id
        key :in, :path
        key :description, 'ID (or slug) of the board to fetch'
        key :required, true
        key :type, :string
      end
      response 200 do
        key :description, 'board detail'
        schema do
          key :'$ref', :Category
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
    options[:label] = params[:label] if params[:label].present?
    boards = params[:category_id].present? ? Category.enabled.friendly.find(params[:category_id]).boards : Board
    boards = boards.includes(:users).enabled.where(options).search(params[:q]).result.rank(:row_order)
    paginate(boards.count, Board::PER_PAGE, allow_render: false) do |limit, offset|
      @boards = boards.offset(offset).limit(limit)
      track_event("User #{current_user.id}", 'List boards', nil, 2 * offset + limit)
      respond_with(@boards, format: :json)
    end
  end

  def show
    options = { users: { id: current_user } }
    boards = params[:category_id].present? ? Category.enabled.friendly.find(params[:category_id]).boards : Board
    @board = boards.includes(:users).enabled.where(options).friendly.find(params[:id])
    track_event("User #{current_user.id}", 'View board detail', @board.name)
    respond_with(@board, :json)
  end
end
