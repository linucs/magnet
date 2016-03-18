# Changelog

## 1.0.1 (2016-01-30)

**Enhancements**:

* Upgraded to Rails 4.2.5
* Upgraded to Devise 3.5
* Upgraded to Sidekiq 3.5
* Switched from sidetiq to sidekiq-cron
* Added polling failures notifications
* Added Bootstrap themes to deck, timeline and wall layouts

## 1.0.2 (2016-03-18)

**Enhancements**:

* Added time-based board polling
* Added time-based campaign activation
* Added user management for admins
* Users can now expire
* The API authentication token can now be specified with the X-API-KEY header attribute
* Added support for Swagger 2
* Geo-tagged Instagram posts can now be searched based on distance from the event location
* Improved RSS feeds support

**Bug fixes**:

* Word wrapping on cards is now working as expected
* Video icons are not correctly vertically aligned on thumbnails
* Fixed a bug when calculating stats for top influencer for an empty board
