// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/sstephenson/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs
//= require jquery-ui/sortable
//= require jquery-ui/effect-highlight
//= require jquery.remotipart
//= require awesomecloud/jquery.awesomeCloud-0.2
//= require angular/angular
//= require websocket_rails/main
//= require bootstrap-sass-official/assets/javascripts/bootstrap-sprockets
//= require bootstrap-hover-dropdown/bootstrap-hover-dropdown.min
//= require bootstrap-rating-input/build/bootstrap-rating-input.min
//= require bootstrap-colorpicker/js/bootstrap-colorpicker
//= require jasny-bootstrap/dist/js/jasny-bootstrap
//= require pace/pace.min
//= require selectize/dist/js/standalone/selectize
//= require iCheck/icheck
//= require outdated-browser/outdatedbrowser/outdatedbrowser
//= require jspdf/dist/jspdf.min
//= require dropzone/dist/dropzone
//= require jquery-geocomplete/jquery.geocomplete
//= require salvattore/dist/salvattore
//= require admin-lte/dist/js/app
//= require boards
//= require categories
//= require feeds
//= require campaigns
//= require pages
//= require_self

$.flash = function(msg, level) {
  $('#flash_messages').html('<div class="alert alert-' + (level || 'success') + ' alert-dismissable fade in"><button aria-hidden="true" class="close" data-dismiss="alert" type="button">×</button>' + msg + '</div>');
}

$(function() {
  var addFormAction = function(e) {
    var $element = $(e.target);
    var $form = $element.closest('form');
    var action = $element.data('action');
    if(action) {
      $('<input>').attr({
        type: 'hidden',
        name: 'bulk_action',
        value: action
      }).appendTo($form);
    }
    return $form;
  }

  outdatedBrowser({
    bgColor: '#f25648',
    color: '#ffffff',
    lowerThan: 'IE8',
    languagePath: ''
  });
  $(document).on('change', '.submit-on-change', function(e) {
    Pace.track(function(){
      addFormAction(e).submit();
    });
    e.preventDefault();
  });
  $(document).on('click', '.submit-on-click', function(e) {
    Pace.track(function(){
      addFormAction(e).submit();
    });
    e.preventDefault();
  });
  $(document).on('click', '.alert-on-click', function(e) {
    alert('This card has the following attached note:\n\n' + $(e.target).attr('title'));
    e.preventDefault();
  });
});
