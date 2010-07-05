// Run jquery in no-conflict mode so it doesn't use $()
jQuery.noConflict();

function setupAssignAllAndNone(){
  jQuery('.check-all-route-operators').click(function(){
    jQuery(this).closest('.route-operators').find('.check-route-operator').attr('checked', true);
    event.preventDefault();
  })
  
  jQuery('.uncheck-all-route-operators').click(function(){
    jQuery(this).closest('.route-operators').find('.check-route-operator').attr('checked', false);
    event.preventDefault();
  })
}

function setupIndexSelectAllAndNone(){
  jQuery('.index-select-all').click(function(){
    jQuery('.index-list').find('.select-item').attr('checked', true);
    event.preventDefault();
  })

  jQuery('.index-select-none').click(function(){
    jQuery('.index-list').find('.select-item').attr('checked', false);
    event.preventDefault();
  })
}

function setupOperatorAutocomplete(){
  jQuery('input#operator_name_auto').autocomplete({
		source: function(request, response) {
			jQuery.ajax({
				url: jQuery("input#operator_name_autocomplete_url").val(),
				dataType: "json",
				data: { term: request.term },
				success: function(data) {
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
			jQuery('input#operator-id').val(ui.item.id);
		},
		search: function(event, ui) {
		  jQuery('input#operator-id').val('');
		  if (jQuery(this).val().length == 0){
		    return false;
		  }
		}
  }); 
}

function setupDestroyOperator(){
  jQuery('.destroy-operator').submit(function(){
    if (confirm(jQuery('input#destroy_operator_confirmation').val())){
      return true;
    }else{
      return false;
    }
  });
}

jQuery(document).ready(function() {
  
  setupAssignAllAndNone();
  setupIndexSelectAllAndNone();
  setupOperatorAutocomplete();
  setupDestroyOperator();

});
