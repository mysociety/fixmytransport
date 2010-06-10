/*
* Auto-Fill Plugin
* Written by Joe Sak 
* Website: http://www.joesak.com/
* Article: http://www.joesak.com/2008/11/19/a-jquery-function-to-auto-fill-input-fields-and-clear-them-on-click/
* GitHub: http://github.com/joemsak/jQuery-AutoFill
*/
(function($){
	$.fn.autofill=function(options){
		var defaults={
			value:'First Name',
			prePopulate:'',
			defaultTextColor:"#666",
			activeTextColor:"#333"};
			
			
			var options=$.extend(defaults,options);
			return this.each(function(){
				var obj=jQuery(this);
				var pfield = (obj.attr('type')=='password');
				var p_obj = false;
				if(pfield){
					obj.hide();
					obj.after('<input type="text" id="'+this.id+'_autofill" class="'+jQuery(this).attr('class')+'" />');
					p_obj = obj;
					obj = obj.next();
				} 
				 if(document.activeElement != obj[0] && obj.val() == '') {
					 obj.css({color:options.defaultTextColor})
						.val(options.value);					
				 }
				 obj.each(function() {
					 jQuery(this.form).submit(function() {
					   if (obj.val() == options.value) {
						   obj.val(options.prePopulate);
						 }
				   });
				 });
				 obj.focus(function(){
						if(obj.val()==options.value){
							if(pfield) {
								obj.hide();
								p_obj.show()
								.focus()
							}
							obj.val(options.prePopulate)
							.css({color:options.activeTextColor});
						}
					})
					.blur(function(){
						if(obj.val()==options.prePopulate || obj.val() == ''){
							obj.css({color:options.defaultTextColor})
							.val(options.value);
						}
					});
					if(p_obj && p_obj.length > 0){
						p_obj.blur(function(){
							if(p_obj.val()==""){
								p_obj.hide();
								obj.show()
								.css({color:options.defaultTextColor})
								.val(options.value);
							}
						});
					}
				});
			};
		})(jQuery);