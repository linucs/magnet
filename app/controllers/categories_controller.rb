class CategoriesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_category, only: [:edit, :update, :destroy]

  add_crumb('Content folders') { |instance| instance.send :categories_path }

  respond_to :js

  def index
    load_categories
    authorize! :index, Category
    @category = Category.new
    respond_with(@categories) do |format|
      format.html { render }
    end
  end

  def new
    @category = Category.new
    respond_with(@category)
  end

  def edit
    authorize! :edit, @category
  end

  def create
    @category = Category.new(category_params)
    @category.team_id = current_user.team_id
    authorize! :create, @category
    @category.save
    respond_with(@category) do |format|
      format.js do
        load_categories
      end
    end
  end

  def update
    authorize! :update, @category
    @category.update(category_params)
    respond_with(@category) do |format|
      format.js { load_categories }
    end
  end

  def destroy
    authorize! :destroy, @category
    @category.destroy
    respond_with(@category) do |format|
      format.js { load_categories }
    end
  end

  private

  def load_categories
    @categories = Category.of_teammates(current_user).rank(:row_order).page(params[:page])
  end

  def set_category
    @category = Category.of_teammates(current_user).friendly.find(params[:id])
  end

  def category_params
    params.require(:category).permit(:name, :slug, :row_order_position, :description, :label, :parent_id, :image, :remove_image, :cover, :remove_cover, :enabled)
  end
end
