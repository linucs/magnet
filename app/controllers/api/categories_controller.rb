class API::CategoriesController < API::BaseController
  include Swagger::Blocks

  swagger_path '/categories' do
    operation :get do
      key :description, 'Returns all board categories in the system accessible by the calling user'
      key :operationId, 'findCategories'
      key :tags, [
        'category'
      ]
      parameter do
        key :name, :label
        key :in, :query
        key :description, 'category label to filter by'
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
        key :default, "0-#{Category::PER_PAGE - 1}"
      end
      response 200 do
        key :description, 'categories listing'
        schema do
          key :type, :array
          items do
            key :'$ref', :Category
          end
        end
      end
    end
  end

  swagger_path '/categories/tree' do
    operation :get do
      key :description, 'Returns all board categories in the system accessible by the calling user'
      key :operationId, 'findCategories'
      key :tags, [
        'category'
      ]
      parameter do
        key :name, :label
        key :in, :query
        key :description, 'category label to filter by'
        key :required, false
        key :type, :string
      end
      response 200 do
        key :description, 'categories tree'
        schema do
          key :type, :array
          items do
            key :'$ref', :CategoryTreeNode
          end
        end
      end
    end
  end

  swagger_path '/categories/{id}' do
    operation :get do
      key :description, 'Returns a single category, when accessible by the calling user'
      key :operationId, 'findByCategoryId'
      key :tags, [
        'category'
      ]
      parameter do
        key :name, :id
        key :in, :path
        key :description, 'ID (or slug) of the category to fetch'
        key :required, true
        key :type, :string
      end
      response 200 do
        key :description, 'category detail'
        schema do
          key :'$ref', :Category
        end
      end
      response 404 do
        key :description, 'category not found or not accessible by the calling user'
      end
    end
  end

  respond_to :json

  def index
    options = {}
    options[:label] = params[:label] if params[:label].present?
    categories = Category.of_teammates(current_user).enabled.where(options).search(params[:q]).result.rank(:row_order)
    paginate(categories.count, Category::PER_PAGE, allow_render: false) do |limit, offset|
      @categories = categories.offset(offset).limit(limit)
      track_event("User #{current_user.id}", 'List categories', nil, 2 * offset + limit)
      respond_with(@categories)
    end
  end

  def tree
    options = {}
    options[:label] = params[:label] if params[:label].present?
    @categories = Category.of_teammates(current_user).enabled.roots.where(options).rank(:row_order)
    track_event("User #{current_user.id}", 'List root categories')
    respond_with(@categories)
  end

  def show
    @category = Category.of_teammates(current_user).enabled.friendly.find(params[:id])
    track_event("User #{current_user.id}", 'View category detail', @category.name)
    respond_with(@category)
  end
end
