// Run jquery in no-conflict mode so it doesn't use $()
jQuery.noConflict();

function setupAssignAllAndNone(){
  jQuery('.check-all-route-operators').click(function(){
    var operators = jQuery(this).closest('.route-operators').find('.check-route-operator')
    operators.attr('checked', true);
    operators.parents('tr').toggleClass("selected");
    event.preventDefault();
  })
  
  jQuery('.uncheck-all-route-operators').click(function(){
    var operators = jQuery(this).closest('.route-operators').find('.check-route-operator')
    operators.attr('checked', false);
    operators.parents('tr').toggleClass("selected");
    event.preventDefault();
  })
}

function setupIndexSelectAllAndNone(){
  jQuery('.index-select-all').click(function(){
    var items = jQuery('.index-list').find('.select-item');
    items.attr('checked', true);
    items.parents('tr').toggleClass("selected");
    event.preventDefault();
  })

  jQuery('.index-select-none').click(function(){
    var items = jQuery('.index-list').find('.select-item');
    items.attr('checked', false);
    items.parents('tr').toggleClass("selected");
    event.preventDefault();
  })
}

function setupItemSelection(class_name){
  jQuery(class_name).click(function(){
    jQuery(this).parents('tr').toggleClass("selected");
  });
}

function setupAutocomplete(text_input_selector, url_input_selector, target_selector) {
  jQuery(text_input_selector).autocomplete({
    source: function(request, response){
      	jQuery.ajax({
  				url: jQuery(url_input_selector).val(),
  				dataType: "json",
  				data: { term: request.term, transport_mode_id: jQuery('select#route_transport_mode_id').val() },
  				success: function(data){
  				  response(jQuery.map(data, function(item) {
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
  			jQuery(this).next(target_selector).val(ui.item.id);
  		},
  		search: function(event, ui) {
  		  jQuery(this).next(target_selector).val('');
  		  if (jQuery(this).val().length == 0){
  		    return false;
  		  }
  		}
  });
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


// link to add new route segments 
function setupAddSegmentLink(){
  jQuery('.add-segment-link').click(function(){
    // copy the hidden template
    var template_segment_row = jQuery('.add-segment-template')
    var new_segment_row = template_segment_row.clone();
    new_segment_row.removeClass('add-segment-template');
    new_segment_row.addClass('add-segment-row');
    // set the display class
    var last_segment_row = jQuery('.add-segment-row:last');
    if (last_segment_row.hasClass('odd')){
      new_segment_row.addClass('even');
    } else {
      new_segment_row.addClass('odd');
    }
    // insert into the DOM
    last_segment_row.after(new_segment_row);
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
    event.preventDefault();
  });
}

function setupSectionControls() {
  jQuery('.admin-section').hide();
  jQuery('.admin-section-control').click(function(){
    var section = jQuery(this).next('.admin-section');
    var imgUrl = jQuery(this).toggleClass('active').css("background-image");
    if (imgUrl.search(/close/) > 0){
      imgUrl = imgUrl.replace('_close', '_open');
    } else {
      imgUrl = imgUrl.replace('_open', '_close'); 
    }
    jQuery(this).toggleClass('active').css("background-image", imgUrl);
    section.slideToggle('slow');
  });
}

function setupDestroyLink(){
  jQuery('.destroy-link').submit(function(){
    if (confirm(jQuery('input#destroy_confirmation').val())){
      return true;
    }else{
      return false;
    }
  });
}

function setupShowRoute(){
  setupOperatorAutocomplete();
  setupStopAutocompletes();
  setupAssignAllAndNone();
  setupItemSelection('.check-route-operator');
  setupItemSelection('.check-route-segment');
  setupAddSegmentLink();
  route_init();
  setupSectionControls();
  setupDestroyLink();
}

function setupNewRoute(){
  setupOperatorAutocomplete();
  setupStopAutocompletes();
  setupAssignAllAndNone();
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
