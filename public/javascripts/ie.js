$(document).ready(function(){
	$.ifixpng('images/pixel.gif');
	$(document).ifixpng();
	
	/* Tip Box - explicitly declares .tip-nub's so they don't get left visible in ie8
	   ================================================== */
	$('.form-1 input, .form-1 textarea').focus(function(){
		var parent = $(this).parent();
		$('.tipbox').not('.fixed').css({'right':'-999999em'});
		$('.tipbox, .tip-nub', parent).not('.fixed').css({'right':'-350px', 'opacity':'0'}).animate({'opacity':'1'}, {duration: 500, queue: false});
	});

	$('.tip-close').click(function(e){
		e.preventDefault();
		$('.tipbox, .tip-nub').not('.fixed').animate({'opacity':'0'}, {duration: 500, queue: false});
	});
});