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
				setEqualHeight($('.thread-details > div', li));
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
		thread($('ul#campaign-thread li:not(:has(.compact))').not('.open'));
	});

	//collapse all
	$('.thread-controls .collapse-all').click(function(e){
		e.preventDefault();
		thread($('ul#campaign-thread li.open:not(:has(.compact))'));
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
  
  //login
  $('#login-to-account').click(function(e){
  	e.preventDefault();
  	$('.pane:visible').fadeOut(500, function(){
  	  $("#login-box").dialog({title: "Sign In"});
  		$('#login-landing').fadeIn();
  	});
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
  	// Set the button text
    $('#campaign-update-form .button').html("Add Update")
    
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

  // ajax submission of problem form 
  function setupProblemForm(form_selector) {
    options = defaultFormOptions();
	  options['error'] = function() { generalError(form_selector + ' #error-text'); }
	  options['success'] = function(response) {
	    if (response.success) {

        if (response.requires_login) {
          // add the notice to the login form
          $('#login-landing #notice-base').text(response.notice);
          $('#login-landing #notice-base').show();

          // show the login form
          $('.login-box .pane').hide();
          $("#login-box").dialog({title: "Sign In"});
      		$('#login-landing').show();
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

  setupUpdateForm('#campaign-update-form');
  setupProblemForm('#create-problem');
  setupCommentForm('#comment-form');
  setupSupportForm('.login-to-support');
  ajaxifyForm('#login-form');
  ajaxifyForm('#create-account-form');

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


/* Make all columns equal height - quick fix
   ================================================== */

function setEqualHeight(columns){
	var tallestcolumn = 0;
	columns.each(
		function(){
			currentHeight = $(this).height();
			if(currentHeight > tallestcolumn){
				tallestcolumn = currentHeight;
			}
		}
	);
	columns.height(tallestcolumn);
}