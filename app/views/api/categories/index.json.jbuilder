json.array! @categories do |category|
  category_tree(json, category, skip_children: true)
end
