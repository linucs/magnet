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
//= require bootsy
//= require jquery-ui/sortable
//= require jquery-ui/effect-highlight
//= require jquery.remotipart
//= require awesomecloud/jquery.awesomeCloud-0.2
//= require angular/angular
//= require action_cable
//= require moment/min/moment.min
//= require bootstrap-sass/assets/javascripts/bootstrap-sprockets
//= require bootstrap-hover-dropdown/bootstrap-hover-dropdown.min
//= require bootstrap-rating-input/build/bootstrap-rating-input.min
//= require bootstrap-colorpicker/js/bootstrap-colorpicker
//= require eonasdan-bootstrap-datetimepicker/build/js/bootstrap-datetimepicker.min
//= require jasny-bootstrap/dist/js/jasny-bootstrap
//= require selectize/dist/js/standalone/selectize
//= require outdated-browser/outdatedbrowser/outdatedbrowser
//= require jspdf/dist/jspdf.min
//= require dropzone/dist/dropzone
//= require jquery-geocomplete/jquery.geocomplete
//= require salvattore/dist/salvattore
//= require admin-lte/dist/js/app
//= require bootstrap-tour/build/js/bootstrap-tour
//= require bootbox/bootbox
//= require boards
//= require categories
//= require feeds
//= require campaigns
//= require pages
//= require_self

$.flash = function(msg, level) {
  $('#flash_messages').html('<div class="alert alert-' + (level || 'success') + ' alert-dismissible fade in"><button aria-label="Close" class="close" data-dismiss="alert" type="button"><span aria-hidden="true">&times;</span></button>' + msg + '</div>');
}

$.addBulkAction = function(e, val) {
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
  if (val) {
    $('<input>').attr({
      type: 'hidden',
      name: 'value',
      value: val
    }).appendTo($form);
  }
  return $form;
}

$(function() {
  outdatedBrowser({
    bgColor: '#f25648',
    color: '#ffffff',
    lowerThan: 'IE8',
    languagePath: ''
  });

  $(document).on('change', '.submit-on-change', function(e) {
    $.addBulkAction(e).submit();
    e.preventDefault();
  });

  $(document).on('click', '.submit-on-click', function(e) {
    $.addBulkAction(e).submit();
    e.preventDefault();
  });

  window.alert = function(message) {
    return bootbox.alert(message);
  }

  $.rails.allowAction = function(element) {
  	var message = element.data('confirm'), answer = false, callback;
  	if (!message) { return true; }

    if (confirm && $.rails.fire(element, 'confirm')) {
  		myCustomConfirmBox(message, function() {
  			callback = $.rails.fire(element, 'confirm:complete', [answer]);
  			if(callback) {
  				var oldAllowAction = $.rails.allowAction;
  				$.rails.allowAction = function() { return true; };
  				element.trigger('click');
  				$.rails.allowAction = oldAllowAction;
  			}
  		});
  	}
  	return false;
	}

	function myCustomConfirmBox(message, callback) {
		bootbox.confirm(message, function(confirmed) {
			if (confirmed) {
				callback();
			}
		});
	}
});
