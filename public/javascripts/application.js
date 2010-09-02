// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

var feedbackTab;

// Close the feedback form panel on success,
// display error messages on failure
function feedbackCallback(response) {
  if (response.success) {
      feedbackTab.hideTab();
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
  jQuery('.new_problem #name').autofill({
       value: jQuery('#guidance-name').text(),
       defaultTextColor: '#595454',
       activeTextColor: '#000000'
     });
  jQuery('#guidance-route').hide();
  jQuery('.new_problem #route_number').autofill({
      value: jQuery('#guidance-route').text(),
      defaultTextColor: '#595454',
      activeTextColor: '#000000'
     });
  jQuery('#guidance-area').hide();
  jQuery('.new_problem #area').autofill({
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
  feedbackTab = {
       speed:800,
       containerWidth:jQuery('#feedback-panel-container').outerWidth(),
       containerHeight:jQuery('#feedback-panel-container').outerHeight(),
       tabWidth:jQuery('#feedback-tab').outerWidth(),
       showTab:function(){
         jQuery('#feedback-panel-container').animate({left:'0'},  feedbackTab.speed,  function(){jQuery('#feedback-tab').removeClass().addClass('feedback-tab-open')})
       },
       hideTab:function(){
         jQuery('#feedback-panel-container').animate({left:"-" + feedbackTab.containerWidth}, feedbackTab.speed, function(){jQuery('#feedback-tab').removeClass().addClass('feedback-tab-closed')});
         clearFormElements('#ajax-feedback');
         jQuery('#ajax-feedback .form-field-error').html('')
       },
       init:function(){
           jQuery('#feedback-tab').addClass('feedback-tab-closed');
           jQuery('#feedback-panel-container').css('height',feedbackTab.containerHeight + 'px');
           jQuery('#feedback-tab').click(function(event){
               if (jQuery('#feedback-tab').hasClass('feedback-tab-open')) {
                 feedbackTab.hideTab()
               } else {
                feedbackTab.showTab()
               }
               event.preventDefault();
           });
       }
   };

  feedbackTab.init();
  var options = {
     success: feedbackCallback,
     data: {
       _method: 'post'
     },
     dataType: 'json'
   };
  jQuery('#ajax-feedback').ajaxForm(options);
  
  jQuery('.feedback-cancel').click(function() {
    feedbackTab.hideTab();
    event.preventDefault();
  });  
  
}
// Run jquery in no-conflict mode so it doesn't use jQuery()
jQuery.noConflict();

jQuery(document).ready(function() {
  
  addSearchGuidance();  
  setupFeedbackForm();
});

