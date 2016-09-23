# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
# Rails.application.config.assets.precompile += %w( search.js )

# Bower asset paths
Rails.application.config.root.join('vendor', 'assets', 'bower_components').to_s.tap do |bower_path|
  Rails.application.config.sass.load_paths << bower_path
  Rails.application.config.assets.paths << bower_path
end

# Minimum Sass number precision required by bootstrap-sass
::Sass::Script::Number.precision = [8, ::Sass::Script::Number.precision].max

Rails.application.config.assets.precompile << %r(.*.(?:eot|svg|ttf|woff|woff2)$)
Rails.application.config.assets.precompile += %w( deck/themes/* timeline/themes/* wall/themes/* reveal.js/lib/font/*.css fancybox/source/*.png fancybox/source/*.gif )
