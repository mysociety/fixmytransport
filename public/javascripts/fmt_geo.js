// js used for fixmytransport geo-locating, tied in with the CSS
// adding class "fmt-has-geolocation" to the parent of the label, input, etc, adds a button

$(function() {
  if (geo_position_js.init()) {
    $('.fmt-has-geolocation').each(function(index){
      var inputId = $(this).find('input, select').not(":hidden").attr("id") || index; // ignore hidden inputs
      $(this).find('label').after('<div class="geolocate-container" id="geolocate-container-' + inputId 
            + '"><span class="geolocate-button" id="geolocate-button-' + inputId
            + '">' + $().fmt_translate('shared.geolocate.use_current_location') + '</span></div>');
      $('#geolocate-button-' + inputId).click(function(e){ doGeolocate(e, inputId) });
    });
  }
});


function doGeolocate(e, inputId) {
  e.preventDefault();
  $('#geolocate-button-' + inputId).replaceWith("<p class='geolocate-status geolocate-busy' id='geolocate-status-" + inputId 
    + "'>" + $().fmt_translate('shared.geolocate.fetching') + "</p>");
  $(".geolocate-container").not("#geolocate-container-" + inputId).fadeOut('slow'); // if there are multiple buttons, hide the other(s)  
  $("#geolocate-container-" + inputId).parent().find(".error").fadeOut('slow'); // error message probably no longer applies
  if (geo_position_js.init()) { // overkill?
    var verySlow = 4800; // if message fades too quickly, discombobulated user thinks: "wha--? did I miss something?"
    geo_position_js.getCurrentPosition(
      function(position) {
        if ($('.fmt-has-geolocation').size()==2) { 
          // page with two geolocates: train/ferry/metro: no auto submit here, user must press Go, using title to determine mode
          var transport_mode = 'train';
          if (document.title.search(/metro/i) != -1) {
              transport_mode = 'other'
          } else if (document.title.search(/ferry/i) != -1) {
              transport_mode = 'ferry'
          }
          $('#geolocate-status-' + inputId).text($().fmt_translate('shared.geolocate.loading_'+transport_mode));
          $.getJSON(
            '/request_nearest_stop',
            {lon:position.coords.longitude, lat:position.coords.latitude, transport_mode:transport_mode}, 
            function(stop_data){
              var $input =  $("#"+inputId);
              if ($input[0].nodeName.toLowerCase() == 'select') { // replace select with an input
                $input.replaceWith("<input type='text' id='" + inputId + "'\>");
                $input =  $("#"+inputId);
              }
              $input.val(stop_data.name);
              $input.closest('form').find("input:text, select").not("#" + inputId).focus(); // ugh: the other input(s) in this form
            }
          );
        } else if ($('#bus_route_form').size()) { // this is find_bus_route: get locality of nearest stop, auto submits if we have a route number
          $('#geolocate-status-' + inputId).text($().fmt_translate('shared.geolocate.loading_bus'));
          $.getJSON(
            '/request_nearest_stop',
            {lon:position.coords.longitude, lat:position.coords.latitude},
            function(stop_data){
              $("#"+inputId).val(stop_data.area);
              if ($("#route_number").val() == $("#guidance-route-number").text()) {
                $('#route_number').focus();
              }
            }
          );
        } else { // this is find_stop (goes straight to lon/lat)
          $('#geolocate-status-' + inputId).text($().fmt_translate('shared.geolocate.loading')); // fleeting
          document.location.href = document.location.href + "?lon=" + position.coords.longitude + "&lat=" + position.coords.latitude
        }
        $('#geolocate-status-' + inputId).text($('#geolocate-status-' + inputId).text() + ' ' + $().fmt_translate('shared.geolocate.loading_done'));
        $('.geolocate-status').removeClass('geolocate-busy').addClass('geolocate-done');
        $('.geolocate-container').fadeOut(verySlow);
      }, 
      function(err) {
        var errMsg;
        if (err.code == 1) { // User said no
          errMsg = $().fmt_translate('shared.geolocate.cancelled');
        } else if (err.code == 2) { // No position
          errMsg = $().fmt_translate('shared.geolocate.no_lookup');
        } else if (err.code == 3) { // Too long
          errMsg = $().fmt_translate('shared.geolocate.no_result');
        } else { // Unknown
          errMsg = $().fmt_translate('shared.geolocate.unknown_error');
        }
        $('#geolocate-status-' + inputId).removeClass('geolocate-busy').text(errMsg);
      }
    );
  } else {
    $('#geolocate-status-' + inputId).removeClass('geolocate-busy').text($().fmt_translate('shared.geolocate.cannot_locate'));
  }
}

