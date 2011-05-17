// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

var feedbackTab;

// Close the feedback form panel on success,
// display error messages on failure
function feedbackCallback(response) {
  if (response.success) {
      feedbackTab.hideTab();
   } else {
     $('.error').html('');
     for (var key in response.errors){
       $('#error-' + key).html( response.errors[key] );
     }
   }
}

function clearFormElements(element) {
  $(element).find(':input').each(function() {
      switch(this.type) {
          case 'password':
          case 'select-multiple':
          case 'select-one':
          case 'text':
          case 'textarea':
              $(this).val('');
              break;
          case 'checkbox':
          case 'radio':
              this.checked = false;
      }
  });
}

function addGuidanceField(guidance_selector, field_selector){
  $(guidance_selector).hide();
  $(field_selector).autofill({
       value: $(guidance_selector).text(),
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


// Add listeners for link click events
function addLinkActions() {
  $('#ask-advice-link').click(function(){
    if($('#advice-request-form').length == 0){
      return true;
    }else{
      $('#advice-request-form').show();
      return false;
    }
  })
  $('.campaign-comment-link').live('click', function(){
    id = $(this).attr('id').split('_')[1];
    if($('#commentbox_' + id).length == 0) {
      return true;
    }else{
      $('#commentbox_' + id).show();
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
  $(selector).ajaxForm(options);
}

function highlightEmptyTextArea(arr, form, options){
  textarea = $('textarea', form);
  if ($.trim(textarea.val()) == ''){
    textarea.parent().prepend('<div class="error">Please enter some text</div>')
    return false;  
  }else {
    return true; 
  }  
}

function show_error(element, message){
  element.parent().prepend('<div class="error">'+message+'</div>');
}

function adviceCallback(response){
  $('.latest-news').after(response.html);
  $('#advice-request-form textarea').val('');
  $('#advice-request-form').hide();
  setupForm('.new_campaign_comment', updateCommentCallback);
}

function updateCallback(response){
  $('.latest-news').after(response.html);
  $('#campaign-update-form textarea').val('');
  setupForm('.new_campaign_comment', updateCommentCallback);
}

function updateCommentCallback(response){
  commentbox_div = $('#commentbox_' + response.commented_id);
  commentbox = $("#comment_text_" + response.commented_id);
  $('.error', commentbox_div).remove();
  
  if (response.success){
    commentbox.val("");
    comments_ul = commentbox_div.prev('.campaign-comments');
    comments_ul.append(response.html);  
  } else {
   
    for (var key in response.errors){
      show_error($('#comment_'+ key + '_' + response.commented_id), response.errors[key] );
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
       containerWidth:$('#feedback-panel-container').outerWidth(),
       containerHeight:$('#feedback-panel-container').outerHeight(),
       tabWidth:$('#feedback-tab').outerWidth(),
       showTab:function(){
         $('#feedback-panel-container').animate({left:'0'},  feedbackTab.speed,  function(){$('#feedback-tab').removeClass().addClass('feedback-tab-open')})
       },
       hideTab:function(){
         $('#feedback-panel-container').animate({left:"-" + feedbackTab.containerWidth}, feedbackTab.speed, function(){$('#feedback-tab').removeClass().addClass('feedback-tab-closed')});
         clearFormElements('#ajax-feedback');
         $('#ajax-feedback .error').html('')
       },
       init:function(){
           $('#feedback-tab').addClass('feedback-tab-closed');
           $('#feedback-panel-container').css('height',feedbackTab.containerHeight + 'px');
           $('#feedback-tab').click(function(event){
               if ($('#feedback-tab').hasClass('feedback-tab-open')) {
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
  $('#ajax-feedback').ajaxForm(options);
  
  $('.feedback-cancel').click(function() {
    feedbackTab.hideTab();
    event.preventDefault();
  });  
  
}

function tabifyRouteLists() {
    if ($('#tabs').length > 0){
      $("#tabs").tabs();
      $("#tabs-bus").tabs();
      $("#tabs-coach").tabs();
      $("#tabs-train").tabs();
      $("#tabs-ferry").tabs();
      $("#tabs-metro").tabs();
    }
}


$(document).ready(function() {
  // Always send the authenticity_token with ajax
  $.ajaxSetup({
    'beforeSend': function(xhr) { xhr.setRequestHeader('X-CSRF-Token', $('meta[name=csrf-token]').attr('content')); }
  });
  tabifyRouteLists();
  addSearchGuidance();  
  setupFeedbackForm();
  addLinkActions();
});

