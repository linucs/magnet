class API::CategoriesController < API::BaseController
  respond_to :json

  def index
    options = {}
    options[:label] = params[:label] if params[:label].present?
    categories = Category.enabled.where(options).search(params[:q]).result.rank(:row_order)
    paginate(categories.count, Category::PER_PAGE, allow_render: false) do |limit, offset|
      @categories = categories.offset(offset).limit(limit)
      track_event("User #{current_user.id}", 'List categories', nil, 2 * offset + limit)
      respond_with(@categories)
    end
  end

  def tree
    options = {}
    options[:label] = params[:label] if params[:label].present?
    @categories = Category.enabled.roots.where(options).rank(:row_order)
    track_event("User #{current_user.id}", 'List root categories')
    respond_with(@categories)
  end

  def show
    @category = Category.enabled.friendly.find(params[:id])
    track_event("User #{current_user.id}", 'View category detail', @category.name)
    respond_with(@category)
  end
end
