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

function addGuidanceField(guidance_selector, field_selector){
  jQuery(guidance_selector).hide();
  jQuery(field_selector).autofill({
       value: jQuery(guidance_selector).text(),
       defaultTextColor: '#595454',
       activeTextColor: '#000000'
     });  
}

// Put guidance text as default in search boxes
function addSearchGuidance() {
  
  addGuidanceField('#guidance-name', '#stop_name_form #name');
  addGuidanceField('#guidance-route-number', '#bus_route_form #route_number');
  addGuidanceField('#guidance-area', '#bus_route_form #area');
  addGuidanceField('#guidance-to', '#train_route_form #to');
  addGuidanceField('#guidance-to', '#other_route_form #to');
  addGuidanceField('#guidance-from', '#train_route_form #from');
  addGuidanceField('#guidance-from', '#other_route_form #from');
  
}

// For an ongoing issue, don't show the date and time fields
function hideProblemDateTimeForOngoing() {
  if (jQuery('#is_campaign_1').is(':checked')){
    jQuery('#date-field').hide();
    jQuery('#time-field').hide();    
  }
  jQuery('input[name=is_campaign]').click(function(){
    if (jQuery('#is_campaign_1').is(':checked')){
      jQuery('#date-field').hide();
      jQuery('#time-field').hide();
    }else{
      jQuery('#date-field').show();
      jQuery('#time-field').show();
    }
  })
}

// Add listeners for link click events
function addLinkActions() {
  jQuery('#ask-advice-link').click(function(){
    if(jQuery('#advice-request-form').length == 0){
      return true;
    }else{
      jQuery('#advice-request-form').show();
      return false;
    }
  })
  jQuery('.campaign-comment-link').live('click', function(){
    id = jQuery(this).attr('id').split('_')[1];
    if(jQuery('#commentbox_' + id).length == 0) {
      return true;
    }else{
      jQuery('#commentbox_' + id).show();
      return false;
    }
  })

  setupForm('.campaign-info .ajax_new_campaign_comment', updateCommentCallback);
  setupForm('.campaign-info #campaign-update-form form', updateCallback);
  setupForm('.campaign-info #advice-request-form form', adviceCallback);
}

function setupForm(selector, callback) {
  var options = {
    success: callback,
    data: {  _method: 'post' },
    dataType: 'json',
    beforeSubmit: highlightEmptyTextArea
  };
  jQuery(selector).ajaxForm(options);
}

function highlightEmptyTextArea(arr, form, options){
  textarea = jQuery('textarea', form);
  if (jQuery.trim(textarea.val()) == ''){
    textarea.parent().prepend('<div class="form-field-error">Please enter some text</div>')
    return false;  
  }else {
    return true; 
  }  
}

function show_error(element, message){
  element.parent().prepend('<div class="form-field-error">'+message+'</div>');
}

function adviceCallback(response){
  jQuery('.latest-news').after(response.html);
  jQuery('#advice-request-form textarea').val('');
  jQuery('#advice-request-form').hide();
  setupForm('.new_campaign_comment', updateCommentCallback);
}

function updateCallback(response){
  jQuery('.latest-news').after(response.html);
  jQuery('#campaign-update-form textarea').val('');
  setupForm('.new_campaign_comment', updateCommentCallback);
}

function updateCommentCallback(response){
  commentbox_div = jQuery('#commentbox_' + response.commented_id);
  commentbox = jQuery("#comment_text_" + response.commented_id);
  jQuery('.form-field-error', commentbox_div).remove();
  
  if (response.success){
    commentbox.val("");
    comments_ul = commentbox_div.prev('.campaign-comments');
    comments_ul.append(response.html);  
  } else {
   
    for (var key in response.errors){
      show_error(jQuery('#comment_'+ key + '_' + response.commented_id), response.errors[key] );
    }
  }
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

// Always send the authenticity_token with ajax
$(document).ajaxSend(function(event, request, settings) {
  if ( settings.type == 'post' ) {
      settings.data = (settings.data ? settings.data + "&" : "")
          + "authenticity_token=" + encodeURIComponent( AUTH_TOKEN );
  }
});

// Run jquery in no-conflict mode so it doesn't use $()
jQuery.noConflict();

jQuery(document).ready(function() {
  addSearchGuidance();  
  setupFeedbackForm();
  hideProblemDateTimeForOngoing();
  addLinkActions();
});

