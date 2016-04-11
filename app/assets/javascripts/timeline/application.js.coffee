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
#= require ui-utils/ui-utils
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
    'mvsouza.angular-rrssb',
    'ui.scroll',
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
  .factory('cards', ['$resource', '$timeout', ($resource, $timeout) ->
    client = (start, end) ->
      $resource gon.api_host + "/boards/:id/cards.json", {id: '@id'},
        query:
          method: 'GET'
          isArray: true
          withCredentials: true
          headers:
            'Range-Unit': 'items'
            'Range': start + '-' + end
          params:
            user_token: gon.user_token
    get = (index, count, success) ->
      if index >= 0
        $('#grid .panel').each ->
            $(this).parent().before(this)
        client(index - 1, index + count - 1).query({id: gon.board_id},
          ((response) ->
            success response
          ),
          ((error) ->
            success []
          )
        )
      else
        success []
    { get }
  ])
  .controller('CardsCtrl', ['$scope', '$location', '$templateCache', '$compile', ($scope, $location, $templateCache, $compile) ->
    $scope.$location = $location
    $scope.board_id = gon.board_id
    $scope.board_name = gon.board_name
    $scope.board_description = gon.board_description
    $scope.board_image_url = gon.board_image_url
    $scope.header_url = gon.header_url
    $scope.template_url = gon.template_url
    $scope.footer_url = gon.footer_url

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
