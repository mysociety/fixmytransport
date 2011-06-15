/*
 * Project: Fix My Transport
 * Authors: Josh Angell
 */

$(document).ready(function(){

  	$('.goto-top').click(function(e){
  		e.preventDefault();
  		 $('html, body').animate({scrollTop : 0},'slow');
  	});
	/* Thread
	   ================================================== */

	//functions - look to interrupt
	function thread(li){
		if(li.hasClass('open')){
			$('.thread-details', li).hide('blind', '', 1000, function(){
				li.removeClass('open');
			});
		}else{
		  if ($('.thread-details', li).length > 0){
			  li.addClass('open');
			  $('.thread-details', li).show('blind', '', 1000);
		  }
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
		thread($('ul#campaign-thread li').not('.open'));
	});

	//collapse all
	$('.thread-controls .collapse-all').click(function(e){
		e.preventDefault();
		thread($('ul#campaign-thread li.open'));
	});



	/* Dialog Box
	   ================================================== */

	$("#login-box").dialog({
		autoOpen: false,
		show: "fade",
		hide: "fade",
		modal: true,
		width: "500px",
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

  //twitter
  $('.twitter').click(function(e){
  	e.preventDefault();
  	$('.pane:visible').fadeOut(500, function(){
			$('#login-twitter').fadeIn();
  	});
  });

  // NB handled explicitly in login code
  //facebook
  $('.facebook-trigger').click(function(e){

/*
  	e.preventDefault();
  	$('.login-box .pane').hide();
  	$('#social-share').empty(); 
    var fbUrl = 'http://www.facebook.com/dialog/apprequests';
  	var redirectUri = document.location.protocol + '//' + document.location.host + '/test_callback.html';
    var queryParams = [
        'app_id=' + fmt_facebook_app_id,
        'redirect_uri=' + encodeURI(redirectUri),
        'access_token=' + 
        'display=iframe'
        ];
    fbUrl = fbUrl + '?' + queryParams.join('&');

  	alert("adding iframe to url " + fbUrl);
  	$('<iframe />', {
        name:  'fbiframe',
        id:    'fbkiframe',
        src:   fbUrl,
        style: 'width: 480px; height:480px; margin:10px auto;'
    }).appendTo('#social-share');
  	$('#social-share').show();
  	$("#login-box").dialog({title: "Facebook:"});
  	$("#login-box").dialog("open");
 */
    e.preventDefault();
    var msg = "Please support me in my campaign";
    if (campaign_data && campaign_data.title) {
        msg = msg + " to " + campaign_data.title;
    }
    msg = msg + ".";
    var campaignId = campaign_data.id + " (" + campaign_data.slug + ")"; // only want ID... slug is human-readable hint
    // FB.ui({method: 'apprequests', message: msg, data: campaignId, title: 'Pick some friends to help you', app_id:fmt_facebook_app_id });
    FB.ui(
        {
            method:  'feed',
            name:    'FixMyTransport campaign: ' + campaign_data.title,
            link:    campaign_data.url,
            picture: document.location.protocol + '//' + document.location.host + '/images/facebook-feed-logo.gif',
            caption: campaign_data.description,
            description: "Help this FixMyTransport campaign by spreading the word and encouraging your friends to support it.",
            //message: "" // FB policy recommends: only set this if user is creator of the campaign
        },
        function(response) {
            $('.login-box .pane').hide();
            $('#social-share').empty(); 
            if (response && response.post_id) {
                $('<h2>Post was published</h2>').appendTo('#social-share');
                $('<p>Thanks for spreading the word about this campaign!</p>').appendTo('#social-share');
            } else {
                $('<h2>Post was not published</h2>').appendTo('#social-share');
                $('<p>You cancelled your post this time.<br/>But please do spread the word about this campaign!</p>').appendTo('#social-share');
            }
            $('#social-share').show();
            $("#login-box").dialog({title: "Facebook:"});
            $("#login-box").dialog("open");
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
      $('#campaign-update-form').append($('<input/>')
                  .attr('type', 'hidden')
                  .attr('name', 'last_thread_index')
                  .attr('class', 'last_thread_index')
                  .val(last_thread_index));

    	$("#login-box").dialog({title: "Ask for advice:"});
      // Set the button text
      $('#campaign-update-form .button').html("Ask for advice")
      // Add the hidden field
      $('#campaign-update-form').append($('<input/>')
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

	//twitter
	$('#static-twitter').click(function(e){
		e.preventDefault();
		$('.login-box .pane').hide();
		$('#login-twitter').show();
		$("#login-box").dialog("open");
		return false;
	});

	//facebook    
	$('#static-facebook').click(function(e){
		e.preventDefault();
		$('.login-box .pane').hide();
		$('#login-facebook').show();
		$("#login-box").dialog("open");
		return false;
	});

  function showFormErrors(form_selector, response) {
    $(form_selector + " .error").html();
    $(form_selector + " .error").hide();
    for (var key in response.errors){
      $(form_selector + ' #error-' + key).html( response.errors[key] );
      $(form_selector + ' #error-' + key).show();
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
      $('#login-landing #notice-base').text(response.notice);
      $('#login-landing #notice-base').show();

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
	  options['error'] = function() { generalError(form_selector + ' #error-text'); }
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

  function generalError(selector) {
    $(selector).html( "There was a problem contacting the server. Please reload the page and try again." );
    $(selector).show();
  }

	// ajax submission of comment form
	function setupCommentForm(form_selector) {
	  options = defaultFormOptions();
	  options['error'] = function() { generalError(form_selector + ' #error-text'); }
	  options['success'] = function(response) {
	    if (response.success) {
        // clear the comment field
        $(form_selector + " #comment_text").val("");

        // clear the hidden thread index field
        $(form_selector + " .last_thread_index").remove();

        if (response.requires_login) {
          // add the notice to the login form
          $('#login-landing #notice-base').text(response.notice);
          $('#login-landing #notice-base').show();

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
           if (response.html){
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

  setupUpdateForm('#campaign-update-form');
  setupCommentForm('#comment-form');
  setupSupportForm('.login-to-support');
  ajaxifyForm('#login-form');
  ajaxifyForm('#create-account-form');

	/* Process
	   ================================================== */
	//add the nav bar
	var processnav = $('<div><button href="#" class="process-back">Back</button><button href="#" class="process-next">Next</button></div>');
	$('#process-nav').append(processnav);

	//vars
	var $tabs			= $('.tabbed');
	var $pane			= $('.tabbed .pane');
	var $crumb			= $('.crumb li a');
	var $crumb_last		= $('.crumb li:last-child a');
	var $crumb_first	= $('.crumb li:first-child a');
	var $next			= $('.process-next');
	var $back			= $('.process-back');

	//init
	$tabs.each(function(){
		var h = 0;
		$(this).children('.pane').each(function(i){
			if($(this).height() > h){h = $(this).height();}
		});
		$(this).children('.pane').css({'height': h});
	});


	$pane.hide();
	$('.tabbed .pane:first-child').show().addClass('active');
	$crumb_first.addClass('current done');
	$back.hide();


	function validate_not_blank(form_input) {
	  if ($.trim(form_input.val()) == '') {
	    form_input.parent().find('.error').show();
	    return false;
	  } else {
	    return true;
	  }
	}

	function validate(panel_id) {
    var all_validations_passed = true;
	  var validations = {'general' : {'campaign_title' : [{'function' : validate_not_blank }],
	                                  'campaign_description' : [{'function' : validate_not_blank }]},
	                     'images' : [],
	                     'share' : []}

    for (var field_id in validations[panel_id]) {
      validation_requirements = validations[panel_id][field_id];
      for (var validation_requirement in validation_requirements) {
        var form_field = $("#"+field_id);
        form_field.parent().find('.error').hide();
        validation_function = validation_requirements[validation_requirement]['function'];
        if (! validation_function(form_field)) {
          all_validations_passed = false;
        }
      }
    }
    return all_validations_passed;
	}

	//the tabbing function
	//requires a pane's unique id to be passed
	function tabbage(p){
	  var old = $('.tabbed .pane.active').get(0);

    // don't change tab if the current tab doesn't validate
    if (! validate(old.id)) {
      return;
    }

		//breadcrumbs
		$crumb.removeClass('current done');
		$($crumb+"[href='#"+$(p).attr('id')+"']").addClass('current done');

		var $cur = $($crumb, '.current.done');
		$cur.parents('li').prevAll('li').each(function(){
			$('a', this).addClass('done');
		});

		//bit of a hack...gets the classes fixed on when returning to the first crumb item
		if($crumb_first.hasClass('current done')){
			$crumb.removeClass('current done');
			$crumb_first.addClass('current done');
		}


		//hide/show relavent pane
		$('.tabbed .pane.active').fadeOut(200, function(){
			$(this).removeClass('active');
			$(p).fadeIn(200, function(){
				$(this).addClass('active');
			});
		});

		//hide next or not
		if($crumb_last.hasClass('current')){$next.hide();}
		else{$next.show();}
		//hide back or not
		if($crumb_first.hasClass('current')){$back.hide();}
		else{$back.show();}
	}

	//next button
	$next.click(function(event){
		event.preventDefault();
		tabbage($('.tabbed .pane.active').next('.pane'));
	});

	//back button
	$back.click(function(event){
		event.preventDefault();
		tabbage($('.tabbed .pane.active').prev('.pane'));
	});

	//progress bar clicks
	$crumb.click(function(event){
		event.preventDefault();
		tabbage($(this).attr('href'));
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
     	imageBtnNext:  '/images/lightbox-btn-next.gif',
    });
  }

  /* Campaign description 'more' link
     ================================================== */
  $('.more-info').click(function(event){
    event.preventDefault();
    $('#truncated-description').html($('#full-description').html());
    $('.more-info').hide();
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
  form.append($('<input type="hidden" name="path" value="'+window.location.pathname+'">'));
  $('body').append(form)
  form.submit();
}

window.fbAsyncInit = function() {
	// fmt_facebook_app_id declared in layouts/application.erb 
    FB.init({appId: fmt_facebook_app_id, status: false, cookie: true, xfbml: true});      
};
(function() {
    var e = document.createElement('script'); e.async = true;
    // e.src = document.location.protocol + '//connect.facebook.net/en_US/all.js';
    e.src = '/javascripts/facebook_all.js';
    document.getElementById('fb-root').appendChild(e);
    if (document.getElementById('fb-like')) {
      FB.XFBML.parse(document.getElementById('fb-like'));
    }
}());

