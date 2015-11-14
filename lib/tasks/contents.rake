namespace :contents do
  desc 'Remove all boards and categories'
  task :destroy_all => :environment do
    Board.destroy_all
    Category.destroy_all
  end

  desc 'Reindexes all boards'
  task :reindex_all => :environment do
    Card.rebuild_indexes_for_all_boards
  end
end
