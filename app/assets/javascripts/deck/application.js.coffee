# This is a manifest file that'll be compiled into app.js, which will include all the files
# listed below.
#
# Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
# or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
#
# It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
# compiled file.
#
# Read Sprockets README (https:#github.com/sstephenson/sprockets#sprockets-directives) for details
# about supported directives.
#
#= require jquery
#= require jquery_ujs
#= require angular/angular
#= require angular-animate/angular-animate
#= require angular-resource/angular-resource
#= require angular-sanitize/angular-sanitize
#= require angular-ui-bootstrap-bower/ui-bootstrap-tpls
#= require ngInfiniteScroll/build/ng-infinite-scroll
#= require angular-masonry/angular-masonry
#= require masonry/dist/masonry.pkgd
#= require imagesloaded/imagesloaded.pkgd
#= require angular-rrssb/dist/angular-rrssb
#= require RRSSB/js/rrssb
#= require jquery.stellar/jquery.stellar
#= require fancybox/source/jquery.fancybox.pack
#= require angulartics/dist/angulartics.min
#= require angulartics/dist/angulartics-ga.min
#= require angular-social/angular-social
#= require_self

angular
  .module('magnet', [
    'ngAnimate',
    'ngResource',
    'ngSanitize',
    'ui.bootstrap',
    'wu.masonry',
    'infinite-scroll',
    'mvsouza.angular-rrssb',
    'angulartics',
    'angulartics.google.analytics',
    'ngSocial'
  ])
  .filter('to_trusted', ['$sce', ($sce) ->
    (text) ->
      $sce.trustAsHtml(text)
  ])
  .filter('to_trusted_url', ['$sce', ($sce) ->
    (src) ->
      $sce.trustAsResourceUrl(src)
  ])
  .filter('escape', () ->
    window.encodeURIComponent
  )
  .filter('to_src', () ->
    (tag) -> $(tag).attr('src')
  )
  .factory('Board', ['$resource', ($resource) ->
    class Board
      DEFAULT_LIMIT = 10

      constructor: (@count = DEFAULT_LIMIT) ->
        @page = 0
        @cards = []
        @busy = false

      client: ->
        $resource "#{gon.api_host}/boards/#{gon.board_id}/cards.json", {},
          query:
            method: 'GET'
            isArray: true
            withCredentials: true
            headers:
              'Range-Unit': 'items'
              'Range': (@page * @count) + '-' + (((@page + 1) * @count) - 1)
            params:
              user_token: gon.user_token
              layout: 'deck'

      fetchNextPage: ->
        if @count == DEFAULT_LIMIT or @page == 0
          @busy = true
          @client().query(
            ((response) =>
              Array::push.apply @cards, response
              @busy = false
              @page += 1
            ),
            ((error) ->
              @busy = false
            )
          )
  ])
  .controller('CardsCtrl', ['$scope', '$location', '$templateCache', '$compile', 'Board', ($scope, $location, $templateCache, $compile, Board) ->
    $scope.$location = $location
    $scope.cards_url = "#{gon.api_host}/boards/#{gon.board_id}/cards.json"
    $scope.cards_url_params = {
      user_token: gon.user_token
    }
    $scope.board_id = gon.board_id
    $scope.board_name = gon.board_name
    $scope.board_description = gon.board_description
    $scope.board_image_url = gon.board_image_url
    $scope.header_url = gon.header_url
    $scope.template_url = gon.template_url
    $scope.footer_url = gon.footer_url

    $scope.board = new Board($location.search().limit)

    $(".fancybox").fancybox({
      beforeShow: () ->
        @title ||= "<div></div>"
      afterShow: () ->
        scope = angular.element(@element).scope()
        template = $templateCache.get('share.html')
        fbox = $('.fancybox-title').append($compile(angular.element(template))(scope))
        scope.$digest()
      helpers :
        title:
          type: 'inside'
        media : {}
      })
  ])
