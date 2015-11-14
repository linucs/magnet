module BoardsHelper
  def external_assets_base_url(board)
    asset_url("/system/boards/#{board.id}", only_path: false)
  end

  def tag_cloud(tags, classes)
    return [] if tags.empty?

    max_count = tags.sort_by(&:last).last.last.to_f

    tags.each do |tag|
      index = ((tag.last / max_count) * (classes.size - 1))
      yield tag, classes[index.nan? ? 0 : index.round]
    end
  end
end
