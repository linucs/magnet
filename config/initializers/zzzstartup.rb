# Initialize custom fonts list
fonts = [
  '"Georgia","serif"',
  '"Palatino Linotype","Book Antiqua","Palatino","serif"',
  '"Times New Roman","Times","serif"',
  '"Arial","Helvetica","sans-serif"',
  '"Arial Black","Gadget","sans-serif"',
  '"Comic Sans MS","cursive","sans-serif"',
  '"Impact","Charcoal","sans-serif"',
  '"Lucida Sans Unicode","Lucida Grande","sans-serif"',
  '"Tahoma","Geneva","sans-serif"',
  '"Trebuchet MS","Helvetica","sans-serif"',
  '"Verdana","Geneva","sans-serif"',
  '"Courier New","Courier","monospace"',
  '"Lucida Console","Monaco","monospace"'
]
CUSTOM_FONT_FAMILIES = {}
GOOGLE_FONTS = {}
JSON.parse(open('db/fonts.json').read)['items'].each do |i|
  f = i['family']
  GOOGLE_FONTS[f] = "\"#{f}\",\"#{i['category']}\""
  fonts << GOOGLE_FONTS[f]
end
fonts.sort.each { |f| CUSTOM_FONT_FAMILIES[f.split(',').first.tr('"', '')] = f }
