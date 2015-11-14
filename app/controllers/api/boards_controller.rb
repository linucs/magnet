class API::BoardsController < API::BaseController
  respond_to :json

  def index
    options = { users: { id: current_user } }
    options[:label] = params[:label] if params[:label].present?
    boards = params[:category_id].present? ? Category.enabled.friendly.find(params[:category_id]).boards : Board
    boards = boards.includes(:users).enabled.where(options).search(params[:q]).result.rank(:row_order)
    paginate(boards.count, Board::PER_PAGE, allow_render: false) do |limit, offset|
      @boards = boards.offset(offset).limit(limit)
      track_event("User #{current_user.id}", 'List boards', nil, 2 * offset + limit)
      respond_with(@boards)
    end
  end

  def show
    options = { users: { id: current_user } }
    boards = params[:category_id].present? ? Category.enabled.friendly.find(params[:category_id]).boards : Board
    @board = boards.includes(:users).enabled.where(options).friendly.find(params[:id])
    track_event("User #{current_user.id}", 'View board detail', @board.name)
    respond_with(@board)
  end
end
