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

## 1.1 (2016-05-16)

**Enhancements**:

* Updated to Rails 4.2.6
* Added product tour
* Adv campaigns content can now be edited with a wysiwyg editor
* Added user-agent detection support and optional redirection to the timeline layout for mobile deck_detect_mobile_devices
* Added support for CTAs attached to a single card
* Added an initial hashtag-search page (transient collections)
* Added support for time-based polling of boards
* Added support for user grouping via teams
* Cards can now be bulk-labelled and searched (content curation)
* Removed default headers for deck and timeline layouts

**Bug fixes**:

* Better error handling on the wall layout

## 1.1.1 (2016-07-06)

**Enhancements**:

* Statistics can now be filtered by date and grouped by day, hour or minute
* ADV campaigns can be enabled on wall, deck and timeline layouts
* Users can now be added by admins
* CTAs can be individually added to any card
* CTAs and ADV Campagn contents can be edited with a WYSIWYG editor

**Bug fixes**:

* Fixed a bug that prevented the 'Notify exceptions' flag to be managed on the user's profile management page
* Fixed a layout bug in full-screen wall backgrounds
