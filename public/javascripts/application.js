// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

// Run jquery in no-conflict mode so it doesn't use jQuery()
jQuery.noConflict();

jQuery(document).ready(function() {
  jQuery('#story_location_attributes_name').autofill({
       value: 'e.g. London Euston',
       defaultTextColor: '#595454',
       activeTextColor: '#000000'
     });
  jQuery('#story_location_attributes_route_number').autofill({
      value: 'e.g. C10, Cardiff to Exeter',
      defaultTextColor: '#595454',
      activeTextColor: '#000000'
     });
  jQuery('#story_location_attributes_area').autofill({
       value: 'e.g. Bristol',
       defaultTextColor: '#595454',
       activeTextColor: '#000000'
     });
});

