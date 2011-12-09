/*
 * Project: Fix My Transport
 * Authors: Josh Angell
 */

$(document).ready(function(){
  /* AJAX forms
     ================================================== */
     // Always send the authenticity_token with ajax
     $.ajaxSetup({
       'beforeSend': function(xhr) { xhr.setRequestHeader('X-CSRF-Token', $('meta[name=csrf-token]').attr('content')); }
     });

	/* Frontpage scroller
	   ================================================== */
  if($('#frontpage-problem-scroller').length > 0){
   //fix height to tallest child
   var h = 0;
   if($('#frontpage-problem-scroller li img').length > 0){h = 250;} //quick chrome hack
   $('#frontpage-problem-scroller').children('li').each(function(i){
     if($(this).height() > h){h = $(this).height();}
   });
   $('#frontpage-problem-scroller').children('li').css({'height': h});

   //hide all but first one
   $('#frontpage-problem-scroller li:not(:first)').addClass('hidden').hide();

   //add classes for use in the function - for some reason
   //the if statement didn't like the :first or :last's
   $('#frontpage-problem-scroller li:first').addClass('first');
   $('#frontpage-problem-scroller li:last').addClass('last');

   //run the function
   frontpageScroller(5000, 2000);
  }

  /* Route and operator lists
     ================================================== */

     function tabifyRouteLists() {
         if ($('#tabs').length > 0){
           $("#tabs").tabs();

           if ($('#tabs-bus .tabs-sub-nav').length > 0){
             $("#tabs-bus").tabs();
           }
           if ($('#tabs-coach .tabs-sub-nav').length > 0){
             $("#tabs-coach").tabs();
           }
           if ($('#tabs-train .tabs-sub-nav').length > 0){
             $("#tabs-train").tabs();
           }
           if ($('#tabs-ferry .tabs-sub-nav').length > 0){
             $("#tabs-ferry").tabs();
           }
           if ($('#tabs-metro .tabs-sub-nav').length > 0){
             $("#tabs-metro").tabs();
           }

           tabshook();
         }
     }

     function tabifyOperatorLists() {
         if ($('#operator-tabs').length > 0){
           $("#operator-tabs").tabs();
           tabshook();
         }
     }

     function tabshook(){
     	var activetab = 'childactive-'+$('#tabs-main-nav li.ui-state-active').attr('id');
     	$("#tabs-main-nav").removeClass (function (index, css) {
     	    return (css.match (/\bchildactive-\S+/g) || []).join(' ');
     	});
     	$('#tabs-main-nav').addClass(activetab);
     }
     tabifyRouteLists();
     tabifyOperatorLists();
     addSearchGuidance();

   	$('#tabs').bind('tabsshow', function(event, ui) {
   		tabshook();
   	});

   	$('#operator-tabs').bind('tabsshow', function(event, ui) {
   		tabshook();
   	});

	/* Region map
	   ================================================== */
	$('#RegionMap area').hover(function(){
		var regionclass = $(this).attr('id');
		$('#region-list li.'+regionclass).addClass('active');
	},function(){
		$('#region-list li').removeClass('active');
	});

	/* Goto top
	   ================================================== */
  	$('.goto-top').click(function(e){
  		e.preventDefault();
  		 $('html, body').animate({scrollTop : 0},'slow');
  	});

	/* Form focusses
	   ================================================== */
	$('#find-stop input, .form-list li input').focus(function(){
		$(this).parent().addClass('active');
	});
	$('#find-stop input, .form-list li input').blur(function(){
		$(this).parent().removeClass('active');
	});

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

	//init
	$('ul.closed-campaign-thread li').removeClass('open');

	//main toggle
	$('ul#campaign-thread li a.thread-item').click(function(e){
		e.preventDefault();
		if(!$(this).hasClass('compact'))
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


  /* Advice in input areas
     ================================================== */

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
       addGuidanceField('#guidance-from', '#train_route_form #from');
       addGuidanceField('#guidance-to', '#other_route_form #to');
       addGuidanceField('#guidance-from', '#other_route_form #from');
       addGuidanceField('#guidance-to', '#ferry_route_form #to');
       addGuidanceField('#guidance-from', '#ferry_route_form #from');
     }

	/* Dialog Boxes
	   ================================================== */

	$("#login-box").dialog({
		autoOpen: false,
		show: "fade",
		hide: "fade",
		modal: true,
		width: 500,
		title: "Sign In or Sign Up",
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
		$("#login-box").dialog({title: "Sign In or Sign Up"});
		$("#login-box").dialog("open");
		return false;
	});

	/* Login Options */
	$('.login-box .pane').not('#login-landing').hide();

  //create account
  $('.pane #create-account').click(function(e){
  	e.preventDefault();
  	$('.pane:visible').fadeOut(500, function(){
  	  $("#login-box").dialog({title: "Create Account"});
  		$('#login-create-account').fadeIn();
  	});
  });

  //login
  $('.pane #login-to-account').click(function(e){
  	e.preventDefault();
  	$('.pane:visible').fadeOut(500, function(){
  	  $("#login-box").dialog({title: "Sign In or Sign Up"});
  		$('#login-landing').fadeIn();
  	});
  });

  //forgot password
  $('.pane #forgot-password').click(function(e){
	  e.preventDefault();
	  $('.pane:visible').fadeOut(500, function(){
      $("#login-box").dialog({title: "Reset Password"});
      $('#login-forgot-password').fadeIn();
    });
  });

  function construct_message(title, description) {
    var message = '<b>' + title + '</b><br/>' + description + '<br/>';
    return message;
  }

  //facebook
  $('.facebook-trigger').click(function(e){
    if ($(window).width() > 600 ) {
      e.preventDefault();
      $('.login-box .pane').hide();
      $('#post-message').empty();
      var post_message = construct_message(campaign_data.facebook_post_title, campaign_data.facebook_post_description);
      $(post_message).appendTo('#post-message');
      $('#fb-share').show();
    	$("#login-box").dialog({title: "Facebook"});
    	$("#login-box").dialog("open");
    	return false;
	  }
  });

  //email
  $('.email-trigger').click(function(e){
    if ($(window).width() > 600 ) {
      e.preventDefault();
      $('.login-box .pane').hide();

      $('#email-share').show();
    	$("#login-box").dialog({title: "Email"});
    	$("#login-box").dialog("open");
    	return false;
    }
  });

  $('#email-share .email-body').click(function(){
    $(this).select();
  })

  function facebook_dialog_default_params() {
   var ui_params = {
        display: 'popup',
        name:    'FixMyTransport campaign: ' + campaign_data.title,
        link:    campaign_data.url,
        picture: document.location.protocol + '//' + document.location.host + '/images/facebook-feed-logo.gif',
        description: campaign_data.facebook_description
    };
    return ui_params;
  }

  function facebook_response(response, element_selector) {
    if ($(window).width() > 600) {
      $('.login-box .pane').hide();
    }
    $(element_selector).empty();
    if (response && response.post_id) {
        $('<b>Posted on Facebook!</b><br/>' +
          'Thanks for spreading the word about this campaign!<br/>').appendTo(element_selector);
    } else {
        $('<b>Oops &mdash; didn&rsquo;t post on Facebook</b><br/>' +
          'You cancelled this time...<br/>but please do spread the word about this campaign.<br/>').appendTo(element_selector);
    }
    if ($(window).width() > 600) {
      $('#fb-share').show();
      $("#login-box").dialog({title: "Facebook"});
      $("#login-box").dialog("open");
      $(element_selector).fadeIn();
    }
  }

  $('#fb-post-to-wall').click(function(e){
    e.preventDefault();
    var ui_params = facebook_dialog_default_params();
    ui_params['method'] = 'feed';
    ui_params['caption'] = campaign_data.description;
    ui_params['message'] = campaign_data.facebook_message;
    FB.ui(ui_params, function(response) { facebook_response(response, '#post-message'); });
    return false;
  });

  $('#fb-send').click(function(e){
    e.preventDefault();
    var ui_params = facebook_dialog_default_params();
    ui_params['method'] = 'send';
    FB.ui(ui_params);
    return false;
  });

    /* Advice request */
  $('.advice-trigger').click(function(e){
      if ($(window).width() > 600 ) {

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

      	$("#login-box").dialog({title: $('.advice-trigger').attr('data-title')});
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
      }
    });

    /* Update */
  $('.update-trigger').click(function(e){
    if ($(window).width() > 600 ) {

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
    }
  });

		/* Comment */
  $('.comment-trigger').click(function(e){
    if ($(window).width() > 600 ) {
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
  	  $("#login-box").dialog({title: $(this).attr('data-title')+":"});
    	$("#login-box").dialog("open");
    	return false;
	  }
  });

	/* Add Photos */
	$('.add-photos-trigger').click(function(e){
	    if ($(window).width() > 600 ) {
  	  	e.preventDefault();
  	  	$('.login-box .pane').hide();
  	  	$('#campaign-add-photos').show();

  	  	$("#login-box").dialog({title: "Add a photo"});
  	  	$("#login-box").dialog("open");
  	  	return false;
	    }
	  });

  function showFormErrors(form_selector, response) {
    $(form_selector + " .error").html('');
    $(form_selector + " .error").hide();
    for (var key in response.errors){
      error_class = key.replace('.', '_')
      var specific_error_element = $(form_selector + ' .error-' + error_class);
      if (specific_error_element.length > 0){
        specific_error_element.html( response.errors[key] );
        specific_error_element.show();
      }else{
        var first_error_element = $(form_selector + " .error").first();
        first_error_element.append( response.errors[key] );
        first_error_element.show();
      }
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
    if ($(window).width() > 600 ) {
  	  options = defaultFormOptions();

      options['success'] = function(response) {

        // add the notice to the login form
        $('#login-landing .notice').text(response.notice);
        $('#login-landing .notice').show();

        // show the login form
        $('.login-box .pane').hide();
        $("#login-box").dialog({title: "Sign In or Sign Up"});
    		$('#login-landing').show();
    		$("#login-box").dialog("open");

    		// record a hit on the login box in analytics
        _gaq.push(['_trackPageview', location.pathname + '/login']);
  	  };
  	  $(form_selector).ajaxForm(options);
    }
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
        $(form_selector + " #update-notice").html("Your update has been added to your problem history and will be sent to your supporters.");
         $(form_selector + " #update-notice").fadeIn(1000, function(){
           $(this).delay(5000).fadeOut(1000)
         });
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
          if ($(window).width() > 600 ) {
          // add the notice to the login form

            $('#login-create-account .notice').text(response.notice);
            $('#login-create-account .notice').show();

            // show the login form
            $('.login-box .pane').hide();
            $("#login-box").dialog({title: "Create a FixMyTransport Account"});
            $('#login-create-account').fadeIn();
            $("#login-box").dialog("open");

            // record a hit on the login box in analytics
            _gaq.push(['_trackPageview', location.pathname + '/login']);

          } else {
            window.location = response.redirect;
          }
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
        $(form_selector + " #comment_mark_fixed").attr("checked", false);
        $(form_selector + " #comment_mark_open").attr("checked", false);

        // mark a problem as fixed
        if (response.mark_fixed) {
          $("#banner .container").append('<div class="right"><span class="ribbon">Fixed</span></div>');
        }
        // mark a problem as open
        if (response.mark_open) {
          $("#banner .container .right").remove();
        }

        // clear the hidden thread index field
        $(form_selector + " .last_thread_index").remove();

        if (response.requires_login) {
          // add the notice to the login form
          $('#login-landing .notice').text(response.notice);
          $('#login-landing .notice').show();

          // show the login form
          $('.login-box .pane').hide();
          $("#login-box").dialog({title: "Sign In or Sign Up"});
      		$('#login-landing').show();

        }else{

          // close the dialog box
          $("#login-box").dialog("close");
          $(".no-comments-text").hide();
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
             $("#login-box").dialog("close");
             $('body').html(response.html);
           }else{
             window.location.reload();
           }
        } else {
          showFormErrors(form_selector, response);
        }
   	};
	  $(form_selector).ajaxForm(options);
	}

  setupUpdateForm('.pane #campaign-update-form-modal');
  setupStaticUpdateForm('#campaign-update-form-static');
  setupProblemForm('#create-problem');
  setupCommentForm('.pane #comment-form');
  setupSupportForm('.login-to-support');
  ajaxifyForm('.pane #login-form');
  ajaxifyForm('.pane #create-account-form');
  ajaxifyForm('.pane .password_reset_email');

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

  /* Login with Facebook
     ================================================== */
     $('.facebook-login').click(callFacebook);

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

  /* Ellipsis in campaign thread
  ================================================== */
  if ($('.campaign-content ul#campaign-thread li a.thread-item span.title').length > 0 && $(window).width() > 600){
   $(".campaign-content ul#campaign-thread li a.thread-item span.title").ellipsis();
  }

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

  $('#campaign-thread .unfold_link').click(function(event){
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


	/* Banner for people coming from other countries
	   ============================================== */
	if ($('#other-country-notice').length > 0) {
    $.ajax({
      url: "/request_country",
      dataType: 'html',
      success: function(country_code){
        if (country_code != 'GB'){
          $('#other-country-notice').html("Hola! Bonjour! Howdy! We have an <a href='advice'>important message for visitors from outside Great Britain </a>");
          $('#conditional-notice').show();
        }
      }
    })
  }
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
    FB.init({appId: fmt_facebook_app_id,
             status: false,
             cookie: false,
             xfbml: true,
             oauth: true,
             channelUrl: window.location.protocol + "//" + window.location.host + '/channel.html' });
      // If someone's already logged in, don't want to show the login popup.
     FB.getLoginStatus(function(response) {
       if (response.authResponse) {

         $('.facebook-login').unbind('click');
         $('.facebook-login').click(function(){ facebookLogin(response) });
       }
     });
};
(function() {
    var e = document.createElement('script'); e.async = true;
    e.src = document.location.protocol + '//connect.facebook.net/en_US/all.js';
    if (document.getElementById('fb-root')){
      document.getElementById('fb-root').appendChild(e);
    }
}());


/* Frontpage scroller function
   ================================================== */
function frontpageScroller(dsp, fsp){
	$('#frontpage-problem-scroller li:not(".hidden")').delay(dsp).fadeOut(fsp, function(){
		$(this).addClass('hidden');

		if($(this).hasClass('last')) {
			$('#frontpage-problem-scroller li.first').removeClass('hidden').fadeIn(fsp, function(){
				frontpageScroller(dsp, fsp);
			});
		} else {
			$(this).next().removeClass('hidden').fadeIn(fsp, function(){
				frontpageScroller(dsp, fsp);
			});
		}
	});
}
