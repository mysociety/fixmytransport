function setupAssignAllAndNone(all_selector, none_selector, table_selector, check_selector){
  $(all_selector).click(function(event){
    var operators = $(this).closest(table_selector).find(check_selector)
    operators.attr('checked', true);
    operators.parents('tr').addClass("selected");
    event.preventDefault();
  })

  $(none_selector).click(function(event){
    var operators = $(this).closest(table_selector).find(check_selector)
    operators.attr('checked', false);
    operators.parents('tr').removeClass("selected");
    event.preventDefault();
  })
}

function setupIndexSelectAllAndNone(){
  $('.index-select-all').click(function(event){
    var items = $('.index-list').find('.select-item');
    items.attr('checked', true);
    items.closest('tr').addClass("selected");
    event.preventDefault();
  })

  $('.index-select-none').click(function(event){
    var items = $('.index-list').find('.select-item');
    items.attr('checked', false);
    items.closest('tr').removeClass("selected");
    event.preventDefault();
  })
}

function setupItemSelection(class_name){
  $(class_name).click(function(){
    $(this).closest('tr').toggleClass("selected");
  });
}

function setupAutocomplete(text_input_selector, url_input_selector, target_selector) {
  $(text_input_selector).autocomplete({
    source: function(request, response){
        $.ajax({
          url: $(url_input_selector).val(),
          dataType: "json",
          data: { term: request.term, transport_mode_id: $('select#route_transport_mode_id').val() },
          success: function(data){
            response($.map(data, function(item) {
              return {
                label: item.name,
                value: item.name,
                id: item.id
              }
            }))
          }
        })
      },
      minLength: 0,
      select: function(event, ui) {
        $(this).nextAll(target_selector+":first").val(ui.item.id);
      },
      search: function(event, ui) {
        $(this).nextAll(target_selector+":first").val('');
        if ($(this).val().length == 0){
          return false;
        }
      }
  });
}

function setupOrganizationAutocomplete(){
  setupAutocomplete('input.organization_name_auto',
                    'input#operator_name_autocomplete_url',
                    'input.organization-id');
}

function setupStopAutocompletes(){
  setupAutocomplete('input.from_stop_name_auto',
                    'input#stop_name_autocomplete_url',
                    'input.from-stop-id');
  setupAutocomplete('input.to_stop_name_auto',
                    'input#stop_name_autocomplete_url',
                    'input.to-stop-id');
}

function setupOperatorAutocomplete(){
  setupAutocomplete('input.operator_name_auto',
                    'input#operator_name_autocomplete_url',
                    'input.operator-id');
}

function setupLocalityAutocomplete(){
  setupAutocomplete('input.locality_name_auto',
                    'input#locality_name_autocomplete_url',
                    'input.locality-id');
}

// link to add new route segments to a journey pattern
function setupAddSegmentLink(){
  $('.add-segment-link').click(function(event){

    // copy the hidden template
    var template_segment_row = $(this).closest('tr').next('.add-segment-template');
    var new_segment_row = template_segment_row.clone();
    // set the display class
    var route_segment_table = template_segment_row.closest('table.route-segments');
    var last_segment_row = route_segment_table.find('tr').last();
    if (last_segment_row.hasClass('odd')){
      display_class = 'even';
    } else {
      display_class = 'odd';
    }
    var last_segment_order;
    if (last_segment_row.length == 1){
      last_segment_order = last_segment_row.find('.segment-order-input').val();
    }

    new_segment_row = popoutRouteSegmentRow(new_segment_row, display_class);
    // insert into the DOM
    route_segment_table.append(new_segment_row);
    var last_segment_order = parseInt(last_segment_order);
    if (!isNaN(last_segment_order)){
      new_segment_order = last_segment_order + 1;
    }else{
      new_segment_order = 0;
    }
    new_segment_row.find('.segment-order-input').val(new_segment_order);

    event.preventDefault(event);

  });
}

function popoutRouteSegmentRow(new_segment_row, class_name){
  new_segment_row.removeClass('add-segment-template');
  new_segment_row.addClass('add-segment-row');
  // set the display class
  new_segment_row.addClass(class_name);
  // make visible
  new_segment_row.css('display', 'table-row');
  // give fields a unique index
  var new_id = new Date().getTime();
  var regexp = new RegExp("new_route_segment", "g");
  new_segment_row.html(function(index, html){
    return html.replace(regexp, new_id);
  });
  // add autocomplete events
  setupAutocomplete(new_segment_row.find('input.from_stop_name_auto'),
                        "input#stop_name_autocomplete_url",
                        new_segment_row.find('input.from-stop-id'));
  setupAutocomplete(new_segment_row.find('input.to_stop_name_auto'),
                        "input#stop_name_autocomplete_url",
                        new_segment_row.find('input.to-stop-id'));
  return new_segment_row;
}

function setupSectionControls() {
  $('.admin-section').hide();
  $('.admin-section-control').click(function(){
    var section = $(this).next('.admin-section');
    var imgUrl = $(this).toggleClass('active').css("background-image");
    if (imgUrl.search(/close/) > 0){
      imgUrl = imgUrl.replace('_close', '_open');
    } else {
      imgUrl = imgUrl.replace('_open', '_close');
    }
    $(this).toggleClass('active').css("background-image", imgUrl);
    section.slideToggle('slow');
  });
}

function setupDestroyLink(){
  $('.destroy-link').submit(function(){
    if (confirm($('input#destroy_confirmation').val())){
      return true;
    }else{
      return false;
    }
  });
}

function setupShowRoutes() {
  for (index in routeSegments) {
    route_init('map_' + index, routeSegments[index]);
  }
}

function setupShowRoute(){
  setupOperatorAutocomplete();
  setupStopAutocompletes();
  setupAssignAllAndNone('.check-all-route-operators', '.uncheck-all-route-operators', '.route-operators','.check-route-operator');
  setupItemSelection('.check-route-operator');
  setupItemSelection('.check-route-segment');
  setupAddSegmentLink();
  route_init('map', routeSegments);
  setupSectionControls();
  setupDestroyLink();
}

function setupNewRoute(){
  setupOperatorAutocomplete();
  setupStopAutocompletes();
  setupAssignAllAndNone('.check-all-route-operators','.uncheck-all-route-operators', '.route-operators','.check-route-operator');
  setupItemSelection('.check-route-operator');
  setupItemSelection('.check-route-segment');
  setupAddSegmentLink();
}

function setupShowStop(){
  setupLocalityAutocomplete();
  setupDestroyLink();
}

function setupNewStop(){
  setupLocalityAutocomplete();
}


function setupShowStopArea(){
  setupAssignAllAndNone('.check-all-stop-area-operators', '.uncheck-all-stop-area-operators', '.stop-area-operators','.check-stop-area-operator');
  setupOperatorAutocomplete();
  setupLocalityAutocomplete();
  setupDestroyLink();
}

function setupNewStopArea(){
  setupLocalityAutocomplete();
}

function setupShowProblem(){
  setupOrganizationAutocomplete();
}

function setupShowIncomingMessage(){
  setupDestroyLink();
}
