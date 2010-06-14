// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

// Run jquery in no-conflict mode so it doesn't use jQuery()
jQuery.noConflict();

jQuery(document).ready(function() {
  jQuery('#guidance-name').hide();
  jQuery('#story_location_attributes_name').autofill({
       value: jQuery('#guidance-name').text(),
       defaultTextColor: '#595454',
       activeTextColor: '#000000'
     });
  jQuery('#guidance-route').hide();
  jQuery('#story_location_attributes_route_number').autofill({
      value: jQuery('#guidance-route').text(),
      defaultTextColor: '#595454',
      activeTextColor: '#000000'
     });
  jQuery('#guidance-area').hide();
  jQuery('#story_location_attributes_area').autofill({
       value: jQuery('#guidance-area').text(),
       defaultTextColor: '#595454',
       activeTextColor: '#000000'
     });
});

