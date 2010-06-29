// Run jquery in no-conflict mode so it doesn't use jQuery()
jQuery.noConflict();

jQuery(document).ready(function() {
  jQuery('#assign-all-routes').click(function(){
    jQuery('.assign-route').attr('checked', true);
    event.preventDefault();
  })
  jQuery('#unassign-all-routes').click(function(){
    jQuery('.assign-route').attr('checked', false);
    event.preventDefault();
  })
});
