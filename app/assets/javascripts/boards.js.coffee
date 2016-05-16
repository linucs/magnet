# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$.fn.rebindCardsListingPage = () ->
  $('.dropdown-toggle').dropdownHover()
  $('.rating').rating()
  salvattore.recreateColumns(document.getElementById('grid'))

jQuery ->
  $('#boards').sortable(
    axis: 'y'
    items: '.sortable-item'
    handle: '.handle'
    cursor: 'move'

    update: (e, ui) ->
      item_id = ui.item.data('item-id')
      position = ui.item.index() # this will not work with paginated items, as the index is zero on every page
      $.ajax(
        type: 'PATCH'
        url: '/boards/' + item_id,
        dataType: 'json'
        data: { board: { row_order_position: position } }
      )
  )

  $(document).on 'change', '.card-bulk-select', (e) ->
    $target = $(e.target)
    if $target.is ':checked'
      $('<input>').attr(
        type: 'hidden'
        id: "bulk-update-#{$target.val()}"
        name: 'card_ids[]'
        value: $target.val()
      ).appendTo('#bulk-update-form')
      $target.closest('.box').effect('highlight', {color: '#d2d6de'}, 1000)
    else
      $("#bulk-update-#{$target.val()}").remove()

  $(document).on 'shown.bs.modal', '#new-board-dialog', (e) ->
    map = $('#new-board-dialog .geocomplete').geocomplete('map')
    google.maps.event.trigger map, "resize"
  $(document).on 'shown.bs.modal', '#edit-board-dialog', (e) ->
    map = $('#edit-board-dialog .geocomplete').geocomplete('map')
    location = map.getCenter()
    google.maps.event.trigger map, "resize"
    map.setCenter(location)

  $(document).on 'click', '.sidebar li.treeview > a[data-remote]', (e) ->
    $('.sidebar li.treeview').removeClass('active')
    $(e.target).parent().parent().addClass('active')

  $(document).on 'click', '#grid .card', (e) ->
    $cb = $(e.target).find('#card_ids_')
    $cb.prop('checked', !$cb.prop('checked')).trigger('change')

  $(document).on 'click', '.bulk-action.label-cards', (e) ->
    $target = $(e.target)
    label = prompt $target.data('prompt')
    if label
      $.addBulkAction(e, label).submit()
