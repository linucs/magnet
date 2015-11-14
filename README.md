# Magnet
An open source Social Hub, that can be used to collect, moderate and display posts from various social-network.

## Main features
- Content fetching from Facebook, Twitter (streaming API are supported), Instagram, Tumblr or a RSS feed
- Content moderation: stopwords, user ban list and whitelist
- Three built-in layouts: deck (cascading grid - using Masonry), timeline (infinite scrolling - using Angular UI) and wall (slideshow - using Reveal.js)
- Social Hubs management can be shared among users
- Contents can be streamed to remotely controlled Chromecast devices
- Analytics and reporting: tagcloud, top contributors, influencers, most engaging, most liked, shared and commented (where avilable)
- Adv campaings can be injected inside the flow of downloaded posts

## Why did you do this? There are a number of Social Hubs out there!
I'm probably somehow depressed, and coding has always kept my brain busy at night, that's it :)

## Requirements
- MRI 2.1.5 - other versions/VMs are untested but might work fine
- [MySQL](http://dev.mysql.com/) 5.6.x (used for metadata storage) - other RDBMS are untested but might work fine
- [Redis](http://redis.io/) 3.0.x (needed by Sidekiq and websocket-rails gem)
- [MongoDB](https://www.mongodb.org/) 3.0.x (used for contents storage)
- [Elasticsearchx](https://www.elastic.co/) 1.5. (optional - used for text indexing)
- [Logstash](https://www.elastic.co/products/logstash) 1.5.0 (optional)

## Getting started
See the Getting Started wiki page and follow the simple setup process.

## Acknowledgements
While developing even a simple application, it'a easy to forget of how many hours people spent developing those awesome libraries included in the project buildfiles.

Among all those exceptional developers, a special thanks goes to [Abdullah Almsaeed](https://github.com/almasaeed2010/AdminLTE) for the control panel theme used in the project.

## License
Please see [LICENSE](LICENSE.txt) for licensing details.

## Author
Lino Moretto, [@linucs](https://twitter.com/linucs)
