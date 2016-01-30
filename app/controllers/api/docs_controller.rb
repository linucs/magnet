class API::DocsController < ApplicationController
  include Swagger::Blocks

  swagger_root do
    key :swagger, '2.0'
    info do
      key :version, '1.0.0'
      key :title, 'Magnet Social Hub'
      contact do
        key :name, 'Lino Moretto'
        key :email, 'lino.moretto@gmail.com'
      end
      license do
        key :name, 'MIT'
        key :url, 'https://opensource.org/licenses/MIT'
      end
    end
    tag do
      key :name, 'category'
      key :description, 'Categories operations'
    end
    tag do
      key :name, 'board'
      key :description, 'Boards operations'
    end
    key :host, URI(Figaro.env.api_host).host
    key :basePath, '/'
    key :consumes, ['application/vnd.magnet+json', 'application/json']
    key :produces, ['application/json']
  end

  # A list of all classes that have swagger_* declarations.
  SWAGGERED_CLASSES = [
    API::CategoriesController,
    API::BoardsController,
    API::CardsController,
    Category,
    Board,
    Card,
    self,
  ].freeze

  def index
    render json: Swagger::Blocks.build_root_json(SWAGGERED_CLASSES)
  end
end
