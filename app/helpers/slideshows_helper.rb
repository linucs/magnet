module SlideshowsHelper
  def custom_fonts_init(f)
    google_webfonts_init(google: [f]) if GOOGLE_FONTS[f]
  end
end
