module CategoriesHelper
  def category_tree(json, category, options = {})
    json.id category.id
    json.name category.name
    json.slug category.slug
    json.description category.description
    json.label category.label
    json.image_url image_url(category.image.url)
    json.cover_url image_url(category.cover.url)
    json.ancestry category.ancestry
    json.boards_count category.boards.count
    unless options[:skip_children]
      children = category.children
      unless children.empty?
        json.children do
          json.array! children do |child|
            category_tree(json, child) if child.enabled?
          end
        end
      end
    end
  end
end
