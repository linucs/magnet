# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

AuthenticationProvider.create(name: 'facebook', features: 'ALSC')
AuthenticationProvider.create(name: 'twitter', features: 'ALSX')
AuthenticationProvider.create(name: 'instagram', features: 'ALC')
AuthenticationProvider.create(name: 'tumblr', features: 'ALSC')
AuthenticationProvider.create(name: 'rss')

User.create(email: 'admin@example.com', password: 'i_am_an_admin!',
  password_confirmation: 'i_am_an_admin!', admin: true, max_feeds: 0, confirmed_at: Time.now)
User.create(email: 'user@example.com', password: 'i_am_a_user!',
  password_confirmation: 'i_am_a_user!', confirmed_at: Time.now)

["Film, music and books",
 "Food and Drink",
 "Fashion",
 "Art",
 "Photography",
 "Design",
 "Travel",
 "Home decor",
 "Humor",
 "Products",
 "Animals and pets",
 "Architecture",
 "Cars and motorcycles",
 "Celebrities",
 "DIY and crafts",
 "Education",
 "Gardening",
 "Geek",
 "Hair and Beauty",
 "Health and Fitness",
 "History",
 "Holidays and Events",
 "Illustrations and Posters",
 "Kids and Parenting",
 "Outdoors",
 "Quotes",
 "Science and Nature",
 "Sports",
 "Tattoos",
 "Technology",
 "Weddings"].each { |n| Category.create(name: n) }
