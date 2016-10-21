# This is a manifest file that'll be compiled into app.js, which will include all the files
# listed below.
#
# Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
# or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
#
# It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
# compiled file.
#
# Read Sprockets README (https://github.com/sstephenson/sprockets#sprockets-directives) for details
# about supported directives.
#
#= require jquery
#= require jquery_ujs
#= require angular/angular
#= require angular-animate/angular-animate
#= require angular-resource/angular-resource
#= require angular-sanitize/angular-sanitize
#= require fancybox/source/jquery.fancybox.pack
#= require reveal.js/js/reveal
#= require action_cable
#= require_self

window.onerror = (msg, url, lineNo, columnNo, error) ->
  console.log 'Unhandled exception: ', msg, url, lineNo, columnNo, error
  false

magnet = angular
  .module('magnet', [
    'ngAnimate',
    'ngResource',
    'ngSanitize'
  ])
  .filter('to_trusted', ['$sce', ($sce) ->
    (text) ->
      $sce.trustAsHtml(text);
  ])
  .filter('to_src', () ->
    (tag) -> $(tag).attr('src')
  )
  .directive('onFinishRender', ['$timeout', ($timeout) ->
    {
        restrict: 'A'
        link: (scope, element, attr) ->
          if (scope.$last == true)
            $timeout () ->
              scope.$emit('ngRepeatFinished')
    }
  ])
  .controller('SlidesCtrl', ['$resource', '$scope', '$window', '$timeout', ($resource, $scope, $window, $timeout) ->
    $scope.board_id = gon.board_id
    $scope.board_name = gon.board_name
    $scope.board_description = gon.board_description
    $scope.board_image_url = gon.board_image_url
    $scope.header_url = gon.header_url
    $scope.template_url = gon.template_url
    $scope.footer_url = gon.footer_url
    transitions = ["default", "concave", "zoom", "linear", "fade"]
    transitions.randomElement = () ->
      this[Math.floor(Math.random() * (this.length - 1))]

    $(".fancybox").fancybox({
      helpers :
        media : {}
      })

    Card = $resource(gon.api_host + "/boards/#{gon.board_id}/cards.json", {},
      query:
        method: 'GET'
        isArray: true
        withCredentials: true
        headers:
          'Range-Unit': 'items'
          'Range': '0-' + ((gon.wall_page_size || 30) - 1)
        params:
          user_token: gon.user_token
          layout: 'wall'
    )

    loadCards = () ->
      $scope.cards = Card.query()
      $scope.cards.$promise.then (cards) ->
        cards.push {}
      , (error) ->
        console.log 'Loading error: ', error
        $timeout () ->
          loadCards()
        , 10000

    initializeReveal = true
    $scope.$on('ngRepeatFinished', (event) ->
      if initializeReveal
        initializeReveal = false
        Reveal.initialize({
          controls: false
          progress: false
          slideNumber: false
          history: false
          keyboard: true
          overview: true
          center: gon.wall_center || false
          touch: true
          loop: true
          rtl: false
          fragments: true
          embedded: false
          help: false
          autoSlide: gon.wall_auto_slide || 0
          autoSlideStoppable: false
          mouseWheel: false
          hideAddressBar: true
          previewLinks: false
          transition: 'default'
          transitionSpeed: 'default'
          backgroundTransition: 'default'
          viewDistance: 3
          parallaxBackgroundImage: gon.wall_background_image_size? && gon.board_cover_url || ''
          parallaxBackgroundSize: gon.wall_background_image_size || ''
          width: gon.wall_width
          height: gon.wall_height
          margin: 0
        })
      else
        Reveal.slide(0)
      $(window).trigger('slidesloaded')
    )

    Reveal.addEventListener "slidechanged", (event) ->
      Reveal.configure({
        transition: transitions.randomElement()
      })
      loadCards() if Reveal.isLastSlide()

    loadCards()

    ActionCable.createConsumer(gon.websocketUrl).subscriptions.create channel: "BoardsChannel", id: gon.board_id,
      connected: ->
        # Called when the subscription is ready for use on the server
        console.log 'Websocket connection has been established'

      disconnected: ->
        # Called when the subscription has been terminated by the server
        console.log 'Websocket connection has been lost'

      received: (data) ->
        # Called when there's incoming data on the websocket for this channel
        switch data.msg
          when 'reload' then $window.location.reload()
          when 'togglePause' then Reveal.togglePause()
          when 'toggleAutoSlide' then Reveal.toggleAutoSlide()
          when 'toggleOverview' then Reveal.toggleOverview()
          when 'prev' then Reveal.prev()
          when 'next' then Reveal.next()
          when 'slide' then Reveal.slide(obj)
    ])
