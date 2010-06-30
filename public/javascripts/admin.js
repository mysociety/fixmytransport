// Run jquery in no-conflict mode so it doesn't use $()
jQuery.noConflict();

function setupAssignAllAndNone(){
  jQuery('#assign-all-routes').click(function(){
    jQuery('.assign-route').attr('checked', true);
    event.preventDefault();
  })
  
  jQuery('#unassign-all-routes').click(function(){
    jQuery('.assign-route').attr('checked', false);
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
  
  setupOperatorAutocomplete();
  
  setupDestroyOperator();

});
