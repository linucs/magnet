# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

jQuery ->
  $('#categories').sortable(
    axis: 'y'
    items: '.sortable-item'
    cursor: 'move'

    update: (e, ui) ->
      item_id = ui.item.data('item-id')
      position = ui.item.index() # this will not work with paginated items, as the index is zero on every page
      $.ajax(
        type: 'PATCH'
        url: '/categories/' + item_id,
        dataType: 'json'
        data: { category: { row_order_position: position } }
      )
  )
