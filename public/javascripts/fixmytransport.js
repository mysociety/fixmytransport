/*
 * Project: Fix My Transport
 * Authors: Josh Angell
 */

$(document).ready(function(){
    
    if ($('#other-country-notice').length > 0) {
      $.ajax({
        url: "/request_country",
        dataType: 'html',
        success: function(country_code){
          if (country_code != 'GB'){
            $('#other-country-notice').html("Want to set up a site like this in your country? Get <a href='advice'>our advice</a>");
            $('#other-country-notice').show();
          }
        }
      }) 
    }
    
	/* Goto top
	   ================================================== */
  	$('.goto-top').click(function(e){
  		e.preventDefault();
  		 $('html, body').animate({scrollTop : 0},'slow');
  	});

	/* Frontpage problem scroller
	   ================================================== */
	$('#frontpage-problem-scroller').cycle();

	/* Thread
	   ================================================== */
	function thread(li){
		if(li.hasClass('open')){
			$('.thread-details', li).hide('blind', '', 1000, function(){
				li.removeClass('open');
			});
		}else{
			li.addClass('open');
			$('.thread-details', li).show('blind', '', 1000);
		}
	}
	
	//main toggle
	$('ul#campaign-thread li a.thread-item').click(function(e){
		e.preventDefault();
		thread($(this).parent('li'));
	});

	//show all
	$('.thread-controls .expand-all').click(function(e){
		e.preventDefault();
		thread($('ul#campaign-thread li:not(:has(.compact))').not('.open'));
	});

	//collapse all
	$('.thread-controls .collapse-all').click(function(e){
		e.preventDefault();
		thread($('ul#campaign-thread li.open:not(:has(.compact))'));
	});



	/* Dialog Boxes
	   ================================================== */

	$("#login-box").dialog({
		autoOpen: false,
		show: "fade",
		hide: "fade",
		modal: true,
		width: 500,
		title: "Sign In",
		beforeClose: function(event, ui) {
      // get rid of any next actions
		  $("#login-box form").find("#next_action").remove();
      // clear form errors
		  $("#login-box .error").html();
		  $("#login-box .error").hide();
		  $('#login-box input[type=text]').val("");
		  $('#login-box input[type=password]').val("");
		   }
	  });

	//login click
	$(".auth").click(function(e) {
	  e.preventDefault();
  	$('.login-box .pane').hide();
  	$('#login-landing').show();
		$("#login-box").dialog({title: "Sign In"});
		$("#login-box").dialog("open");
		return false;
	});

	/* Login Options */
	$('.login-box .pane').not('#login-landing').hide();

  //create account
  $('#create-account').click(function(e){
  	e.preventDefault();
  	$('.pane:visible').fadeOut(500, function(){
  	  $("#login-box").dialog({title: "Create Account"});
  		$('#login-create-account').fadeIn();
  	});
  });
  
  //login
  $('#login-to-account').click(function(e){
  	e.preventDefault();
  	$('.pane:visible').fadeOut(500, function(){
  	  $("#login-box").dialog({title: "Sign In"});
  		$('#login-landing').fadeIn();
  	});
  });

  //facebook
  $('.facebook-trigger').click(function(e){
    e.preventDefault();
    $('.login-box .pane').hide();
    $('#social-message').empty().append('<b>Tell the world you&rsquo;re a supporter</b><br/>' +
       'Post to your Facebook wall and let everyone know!').show(); 
    $('#social-share').show();
  	$("#login-box").dialog({title: "Facebook"});
  	$("#login-box").dialog("open");
  	return false;    
  });

  $('.fb-feed-button').click(function(e){
      e.preventDefault();
     $('#social-message').fadeOut().empty();
      FB.ui(
          {
              method:  'feed',
              display: 'popup',
              name:    'FixMyTransport campaign: ' + campaign_data.title,
              link:    campaign_data.url,
              picture: document.location.protocol + '//' + document.location.host + '/images/facebook-feed-logo.gif',
              caption: campaign_data.description,
              description: "Please help this FixMyTransport campaign by spreading the word and encouraging your friends to support it.",
              message: "I'm supporting this FixMyTransport campaign: "  + campaign_data.title + " ...will you join me?"
          },
          function(response) {
              $('.login-box .pane').hide();
              $('#social-message').empty(); 
              if (response && response.post_id) {
                  $('<b>Posted on Facebook!</b><br/>' +
                    'Thanks for spreading the word about this campaign!<br/>').appendTo('#social-message');
              } else {
                  $('<b>Oops &mdash; didn&rsquo;t post on Facebook</b><br/>' +
                    'You cancelled your post this time...<br/>but please do spread the word about this campaign.<br/>').appendTo('#social-message');
              }
              $('#social-share').show();
              $("#login-box").dialog({title: "Facebook"});
              $("#login-box").dialog("open");
              $('#social-message').fadeIn();
          }
      );
     return false;
  });

    /* Advice request */
  $('.advice-trigger').click(function(e){
    	e.preventDefault();
    	$('.login-box .pane').hide();
    	$('#campaign-update').show();
    	// Add the index of the last campaign event being shown to the form
    	var last_thread_index = $('#campaign-thread li:last-child .thread-item .num').text();
      $('#campaign-update-form-modal').append($('<input/>')
                  .attr('type', 'hidden')
                  .attr('name', 'last_thread_index')
                  .attr('class', 'last_thread_index')
                  .val(last_thread_index));

    	$("#login-box").dialog({title: "Ask for advice:"});
      // Set the button text
      $('#campaign-update-form-modal button[type=submit]').html("Ask for advice")
      // Add the hidden field
      $('#campaign-update-form-modal').append($('<input/>')
                  .attr('type', 'hidden')
                  .attr('id', 'campaign_update_is_advice_request')
                  .attr('name', 'campaign_update[is_advice_request]')
                  .val('true'));

    	$("#login-box").dialog("open");
    	return false;
    });

    /* Update */
  $('.update-trigger').click(function(e){
  	e.preventDefault();
  	$('.login-box .pane').hide();
  	$('#campaign-update').show();
  	// Add the index of the last campaign event being shown to the form
  	var last_thread_index = $('#campaign-thread li:last-child .thread-item .num').text();
    $('#campaign-update-form').append($('<input/>')
                .attr('type', 'hidden')
                .attr('name', 'last_thread_index')
                .attr('class', 'last_thread_index')
                .val(last_thread_index));

  	$("#login-box").dialog({title: "Update:"});
  	// Set the button text
    $('#campaign-update-form button[type=submit]').html("Add Update")
    
  	$("#login-box").dialog("open");
  	return false;
  });

		/* Comment */
  $('.comment-trigger').click(function(e){
  	e.preventDefault();
  	$('.login-box .pane').hide();
  	$('#comment-and-login').show();
  	// Add the index of the last campaign event being shown to the form
  	var last_thread_index = $('#campaign-thread li:last-child .thread-item .num').text();
    $('#comment-form').append($('<input/>')
                .attr('type', 'hidden')
                .attr('name', 'last_thread_index')
                .attr('class', 'last_thread_index')
                .val(last_thread_index));
  	$("#login-box").dialog({title: "Comment:"});
  	$("#login-box").dialog("open");
  	return false;
  });

	/* Add Photos */
	$('.add-photos-trigger').click(function(e){
	  	e.preventDefault();
	  	$('.login-box .pane').hide();
	  	$('#campaign-add-photos').show();
	
	  	$("#login-box").dialog({title: "Add images:"});
	  	$("#login-box").dialog("open");
	  	return false;
	  });
	

  /* Static Login Options for campaign creation page*/

	//create account
	$('#static-create-account').click(function(e){
		e.preventDefault();
		$('.login-box .pane').hide();
		$('#login-create-account').show();
		$("#login-box").dialog({title: "Create Account"});
		$("#login-box").dialog("open");
		return false;
	});

  function showFormErrors(form_selector, response) {
    $(form_selector + " .error").html();
    $(form_selector + " .error").hide();
    for (var key in response.errors){
      $(form_selector + ' .error-' + key).html( response.errors[key] );
      $(form_selector + ' .error-' + key).show();
    }
  }

  function defaultFormOptions() {
    var options = {
       data: {
         _method: 'post'
       },
       dataType: 'json'
     };
     return options;
  }


  // ajax submission of support form
  function setupSupportForm(form_selector) {
	  options = defaultFormOptions();

    options['success'] = function(response) {

      // add the notice to the login form
      $('#login-landing .notice').text(response.notice);
      $('#login-landing .notice').show();

      // show the login form
      $('.login-box .pane').hide();
      $("#login-box").dialog({title: "Sign In"});
  		$('#login-landing').show();
  		$("#login-box").dialog("open");

	  };
	  $(form_selector).ajaxForm(options);

  }

  // ajax submission of update/advice form
  function setupUpdateForm(form_selector) {
    options = defaultFormOptions();
	  options['error'] = function() { generalError(form_selector + ' .error-text'); }
	  options['success'] = function(response) {
	    if (response.success) {
        // close the dialog box
      
        $("#login-box").dialog("close");
        // clear the update field
        $(form_selector + " #campaign_update_text").val("");
        // remove the hidden thread index field
        $(form_selector + " .last_thread_index").remove();

        // remove the advice flag
        $(form_selector + " #campaign_update_is_advice_request").remove();
        addCampaignItem(response.html);
      } else {
        showFormErrors(form_selector, response);
      }
	  }
	  $(form_selector).ajaxForm(options);

  }

  // ajax submission of non-modal dialog update form
  function setupStaticUpdateForm(form_selector) {
    options = defaultFormOptions();
    options['error'] = function() { generalError(form_selector + ' .error-text'); }
    options['beforeSubmit'] = function(formData, jQueryForm, options) {
     // Add the index of the last campaign event being shown to the form
     var last_thread_index = $('#campaign-thread li:last-child .thread-item .num').text();
      formData[formData.length] = { "name": "last_thread_index", "value": last_thread_index };
    }
     options['success'] = function(response) {
       if (response.success) {
         // clear any error
         $(form_selector + " .error-text").html('');
         $(form_selector + " .error-text").hide()
        // clear the update field
        $(form_selector + " #campaign_update_text").val("");
        // remove the hidden thread index field
        $(form_selector + " .last_thread_index").remove();
        addCampaignItem(response.html);
      } else {
        showFormErrors(form_selector, response);
      }
     }
     $(form_selector).ajaxForm(options);
    
  }

  function generalError(selector) {
    $(selector).html( "There was a problem contacting the server. Please reload the page and try again." );
    $(selector).show();
  }

  // ajax submission of problem form 
  function setupProblemForm(form_selector) {
    options = defaultFormOptions();
	  options['error'] = function() { generalError(form_selector + ' .error-text'); }
	  options['success'] = function(response) {
	    if (response.success) {

        if (response.requires_login) {
          // add the notice to the login form
          $('#login-create-account .notice').text(response.notice);
          $('#login-create-account .notice').show();

          // show the login form
          $('.login-box .pane').hide();
          $("#login-box").dialog({title: "Create a FixMyTransport Account"});
        	$('#login-create-account').fadeIn();
        	$("#login-to-account").before("Got an account? ")
        	$("#login-to-account").html("Sign in")
      		$("#login-box").dialog("open");

        }else{
          window.location = response.redirect;
        }
      } else {
        showFormErrors(form_selector, response);
      }
	  }
	  $(form_selector).ajaxForm(options);
	  
  }
	// ajax submission of comment form
	function setupCommentForm(form_selector) {
	  options = defaultFormOptions();
	  options['error'] = function() { generalError(form_selector + ' .error-text'); }
	  options['success'] = function(response) {
	    if (response.success) {
        // clear the comment field
        $(form_selector + " #comment_text").val("");

        // clear the hidden thread index field
        $(form_selector + " .last_thread_index").remove();

        if (response.requires_login) {
          // add the notice to the login form
          $('#login-landing .notice').text(response.notice);
          $('#login-landing .notice').show();

          // show the login form
          $('.login-box .pane').hide();
          $("#login-box").dialog({title: "Sign In"});
      		$('#login-landing').show();

        }else{

          // close the dialog box
          $("#login-box").dialog("close");

          addCampaignItem(response.html);

        }
      } else {
        showFormErrors(form_selector, response);
      }
	  }
	  $(form_selector).ajaxForm(options);
	}

  function addCampaignItem(html) {
    // load the new comment into the campaign history
    $('#campaign-thread').append(html);

    // set up the new item events
    var new_item = $('ul#campaign-thread li:last-child a.thread-item');
    new_item.click(function(e){
  		e.preventDefault();
  		thread($(this).parent('li'));
  	});

    // open the comment
  	new_item.click();

  }

  // ajax submission of login/create account forms
  function ajaxifyForm(form_selector) {
    options = defaultFormOptions();
    options['error'] = function() { generalError(form_selector + ' #error-base' ) };
    options['success'] = function(response) {
       if (response.success) {
           if (response.redirect) {
             window.location = response.redirect;
           }
           else if (response.html){
             $(form_selector).html(response.html);
           }else{
             window.location.reload();
           }
        } else {
          showFormErrors(form_selector, response);
        }
   	};
	  $(form_selector).ajaxForm(options);
	}

  setupUpdateForm('#campaign-update-form-modal');
  setupStaticUpdateForm('#campaign-update-form-static');
  setupProblemForm('#create-problem');
  setupCommentForm('.pane #comment-form');
  setupSupportForm('.login-to-support');
  ajaxifyForm('.pane #login-form');
  ajaxifyForm('.pane #create-account-form');

  /* Twitter button 
     ================================================== */

  $('.twitter-popup').click(function(event) {
   var width  = 575,
       height = 400,
       left   = ($(window).width()  - width)  / 2,
       top    = ($(window).height() - height) / 2,
       url    = this.href,
       opts   = 'status=1' +
                ',width='  + width  +
                ',height=' + height +
                ',top='    + top    +
                ',left='   + left;

   window.open(url, 'twitter', opts);

   return false;
  });


	/* Tip Box
	   ================================================== */
	//needs to include an if already showing thing when we focus
	$('.tipbox').prepend('<div class="tip-nub"></div>');

	$('.form-1 input, .form-1 textarea').focus(function(){
		var parent = $(this).parent();
		$('.tipbox').not('.fixed').css({'right':'-999999em'});
		$('.tipbox', parent).not('.fixed').css({'right':'-350px', 'opacity':'0'}).animate({'opacity':'1'}, {duration: 500, queue: false});
	});
	
	$('.tip-close').click(function(e){
		e.preventDefault();
		$('.tipbox').not('.fixed').animate({'opacity':'0'}, {duration: 500, queue: false});
	});

  /* Campaign photo lightboxing
     ================================================== */
  if ($('.gallery a').length > 0){
    $('.gallery a').lightBox( {
      imageLoading:  '/images/lightbox-ico-loading.gif',
     	imageBtnClose: '/images/lightbox-btn-close.gif',
     	imageBtnPrev:  '/images/lightbox-btn-prev.gif',
     	imageBtnNext:  '/images/lightbox-btn-next.gif'
    });
  }

  /* Campaign description 'more' link
     ================================================== */
  $('.more-info').click(function(event){
    event.preventDefault();
    $('#truncated-description').html($('#full-description').html());
    $('.more-info').hide();
  });

  /* Email quoting folding and unfolding
  ================================================== */
  function swap_copy(thread_element) {
    var copy = thread_element.find('.thread-copy');
    var alternative_copy = thread_element.find('.thread-alternative-copy');
    var copy_contents = copy.html();
    var alt_copy_contents = alternative_copy.html();
    copy.html(alt_copy_contents);
    alternative_copy.html(copy_contents);
    copy.find('.unfold_link').click(function(event){
        event.preventDefault();
        swap_copy($(this).parents('.thread-details'));
    });
  }
  
  $('.unfold_link').click(function(event){
      event.preventDefault();
      swap_copy($(this).parents('.thread-details'));
  });
  /* Campaign Supporter 'View all' link
     ================================================== */
  $('#campaign-supporters .view-all').click(function(event){
    event.preventDefault();
    $.ajax({
      url: $(this).attr('url'),
      success: function(data) {
        $('#campaign-supporters').html(data);
      }
    });
  });

	/* Operator hide/show
	   ================================================== */
	$('.operator-trigger').click(function(){
		var parent = $(this).parent();
		$('ul', parent).slideToggle(1500);
	});
	
	/* Fancy buttons - :active and IE don't play nice so lets do it js
	    ================================================== */
	$('.fancybutton').mousedown(function(){
		$(this).addClass('mousedown');
	}).mouseup(function(){
		$(this).removeClass('mousedown');
	}).mouseout(function(){
		$(this).removeClass('mousedown');
	});
});

/* External authentication
   ================================================== */

// fmt_facebook_app_id declared in header (layouts/application.erb)

function externalAuth(authParams) {
  var url = window.location.protocol + "//" + window.location.host + "/user_sessions/external";
  var form = $('<form action="'+url+'" method="POST"></form>');
  for (authParam in authParams) {
    form.append($('<input type="hidden" name="'+authParam+'" value="'+authParams[authParam]+'">'));
  }
  form.append($('<input type="hidden" name="path" value="'+window.location.pathname+window.location.search+'">'));
  $('body').append(form)
  form.submit();
}

window.fbAsyncInit = function() {
	// fmt_facebook_app_id declared in layouts/application.erb 
    FB.init({appId: fmt_facebook_app_id, status: false, cookie: true, xfbml: true});      
};
(function() {
    var e = document.createElement('script'); e.async = true;
    e.src = document.location.protocol + '//connect.facebook.net/en_US/all.js';
    document.getElementById('fb-root').appendChild(e);
    if (document.getElementById('fb-like')) {
      FB.XFBML.parse(document.getElementById('fb-like'));
    }
}());
