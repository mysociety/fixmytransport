// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

// Close the feedback form panel on success,
// display error messages on failure
function feedbackCallback(response) {
  if (response.success) {
      jQuery('.feedback-panel').hide();
   } else {
     jQuery('.form-field-error').html('');
     for (var key in response.errors){
       jQuery('#form-field-error-' + key).html( response.errors[key] );
     }
   }
}

function clearFormElements(element) {
  jQuery(element).find(':input').each(function() {
      switch(this.type) {
          case 'password':
          case 'select-multiple':
          case 'select-one':
          case 'text':
          case 'textarea':
              jQuery(this).val('');
              break;
          case 'checkbox':
          case 'radio':
              this.checked = false;
      }
  });
}

// Put guidance text as default in search boxes
function addSearchGuidance() {
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
  
}

// Make the feedback tab popup the form, 
// make the form submit via AJAX,
// setup the cancel button to clear fields
// and close the panel
function setupFeedbackForm() {
  jQuery('.feedback-tab').click(function() {
    jQuery('.feedback-panel').show();
    event.preventDefault();
  });
  var options = {
     success: feedbackCallback,
     data: {
       _method: 'post'
     },
     dataType: 'json'
   };
  jQuery('#ajax-feedback').ajaxForm(options);
  
  jQuery('.feedback-cancel').click(function() {
    jQuery('.feedback-panel').hide();
    clearFormElements('#ajax-feedback');
    jQuery('#ajax-feedback .form-field-error').html('');
    event.preventDefault();
  });  
}
// Run jquery in no-conflict mode so it doesn't use jQuery()
jQuery.noConflict();

jQuery(document).ready(function() {
  
  addSearchGuidance();  
  setupFeedbackForm();
});

