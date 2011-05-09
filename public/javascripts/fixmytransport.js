/*
 * Project: Fix My Transport
 * Authors: Josh Angell
 */
 
$(document).ready(function(){
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
		width: "700px"
	});
	
	//login click
	$(".auth").click(function() {
    $('#login-landing').show();
		$("#login-box").dialog("open");
		return false;
	});
	
	/* Login Options */
	$('.login-box .pane').not('#login-landing').hide();
	
	//create account
	$('#create-account').click(function(e){
		e.preventDefault();
		$('#login-landing').fadeOut(function(){
			$('#login-create-account').fadeIn();
		});
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
		$('.tipbox', parent).not('.fixed').css({'right':'0', 'opacity':'0'}).animate({'opacity':'1'}, {duration: 500, queue: false});
	});
});