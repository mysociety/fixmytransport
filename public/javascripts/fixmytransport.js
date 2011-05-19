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

  // support campaign click
  $("#login-to-support").click(function() {
      next_action = $(this).parent().find("#next_action");
      next_action.clone().appendTo($('#login-form'));
      next_action.clone().appendTo($('#create-account-form'))
      $('#login-landing').show();
      $('.login-box .pane').not('#login-landing').hide();
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

  //facebook
  $('.facebook').click(function(e){
  	e.preventDefault();
  	$('.pane:visible').fadeOut(500, function(){
  		$('#login-facebook').fadeIn();
  	});
	});

		/* Comment but not logged in */
  $('.comment-button').click(function(e){
  	e.preventDefault();
  	$('.login-box .pane').hide();
  	$('#comment-and-login').show();
    // Add the index of the last campaign event being shown to the form
  	var last_campaign_event_index = $('#campaign-thread li:last-child .thread-item .num').text();
    $('#comment-form').append($('<input/>')
                .attr('type', 'hidden')
                .attr('name', 'last_campaign_event_index')
                .val(last_campaign_event_index));
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

	// ajax submission of comment form
	function setupCommentForm(form_selector) {
	  options = defaultFormOptions();
	  options['error'] = function() {
	    $(form_selector + ' #error-text').html( "There was a problem contacting the server. Please reload the page and try again." );
      $(form_selector + ' #error-text' ).show();
	  }
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
    		
        // clear the comment field
        $(form_selector + " #comment_text").val("");
          
        }else{
          // load the new comment into the campaign history
          $('#campaign-thread').append(response.html);

          // set up the new comment events
          var new_comment = $('ul#campaign-thread li:last-child a.thread-item');
          new_comment.click(function(e){
        		e.preventDefault();
        		thread($(this).parent('li'));
        	});
          // open it
        	new_comment.click();
          // clear the comment field
          $(form_selector + " #comment_text").val("");
          // close the dialog box
          $("#login-box").dialog("close");
        }
      } else {
        showFormErrors(form_selector, response);
      }
	  }
	  $(form_selector).ajaxForm(options);
	}

  // ajax submission of login/create account forms
  function ajaxifyForm(form_selector) {
    options = defaultFormOptions();
    options['error'] = function() {
	    $(form_selector + ' #error-base').html( "There was a problem contacting the server. Please reload the page and try again." );
      $(form_selector + ' #error-base' ).show();
	  }
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

  setupCommentForm('#comment-form');
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

	//the tabbing function
	//requires a pane's unique id to be passed
	function tabbage(p){
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
	$('.formitem input, .formitem textarea').focus(function(){
		var parent = $(this).parent();
		$('.tipbox').not('.fixed').css({'right':'-999999em'});
		$('.tipbox', parent).not('.fixed').css({'right':'-450px', 'opacity':'0'}).animate({'opacity':'1'}, {duration: 500, queue: false});
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


