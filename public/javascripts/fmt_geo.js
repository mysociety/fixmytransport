// js used for fixmytransport geo-locating, tied in with the CSS
// adding class "fmt-has-geolocation" to the parent of the label, input, etc, adds a button

$(function() {
  if (geo_position_js.init()) {
    $('.fmt-has-geolocation').each(function(index){
      var inputId = $(this).find('input, select').not(":hidden").attr("id") || index; // ignore hidden inputs
      $(this).find('label').after('<div class="geolocate-container" id="geolocate-container-' + inputId 
            + '"><span class="geolocate-button" id="geolocate-button-' + inputId
            + '">Use your current location</span></div>');
      $('#geolocate-button-' + inputId).click(function(e){ doGeolocate(e, inputId) });
    });
  }
});

function doGeolocate(e, inputId) {
  e.preventDefault();
  $('#geolocate-button-' + inputId).replaceWith("<p class='geolocate-status' id='geolocate-status-" + inputId + "'>Fetching location...</p>");
  $(".geolocate-container").not("#geolocate-container-" + inputId).fadeOut('slow'); // if there are multiple buttons, hide the other(s)  
  $("#geolocate-container-" + inputId).parent().find(".error").fadeOut('slow'); // error message probably no longer applies
  if (geo_position_js.init()) { // overkill?
    geo_position_js.getCurrentPosition(
      function(position) {
        $('#geolocate-status-' + inputId).text("Fetching location done, loading...");
        if ($('.fmt-has-geolocation').size()==2) { // page with two geolocates: train/ferry/metro: no auto submit here, user must press Go
          $.getJSON(
            '/request_nearest_stop',
            {lon:position.coords.longitude, lat:position.coords.latitude},
            function(stop_data){
              var $input =  $("#"+inputId);
              if ($input[0].nodeName.toLowerCase() == 'select') { // replace select with an input
                $input.replaceWith("<input type='text' id='" + inputId + "'\>");
                $input =  $("#"+inputId);
              }
              $input.val(stop_data.area);
              $(".geolocate-container").hide(); // hide all geolocation buttons
              $input.closest('form').find("input:text, select").not("#" + inputId).focus(); // ugh: the other input(s) in this form
            }
          );
        } else if ($('#bus_route_form').size()) { // this is find_bus_route: get locality of nearest stop, auto submits if we have a route number
          $.getJSON(
            '/request_nearest_stop',
            {lon:position.coords.longitude, lat:position.coords.latitude},
            function(stop_data){
              $("#"+inputId).val(stop_data.area);
              if ($("#route_number").val() == $("#guidance-route-number").text()) {
                $('.geolocate-container').hide();
                $('#route_number').focus();
              } else {
                $('.geolocate-status').html("<span>OK... using " + stop_data.area +"...</span>");
                $("#bus_route_form").submit();                    
              }
            }
          );
        } else { // this is find_stop (goes straight to lon/lat)
          document.location.href = document.location.href + "?lon=" + position.coords.longitude + "&amp;lat=" + position.coords.latitude
        }
      }, 
      function(err) {
        var errMsg;
        if (err.code == 1) { // User said no
          errMsg = "Cancelled";
        } else if (err.code == 2) { // No position
          errMsg = "Could not look up location";
        } else if (err.code == 3) { // Too long
          errMsg = "No result returned";
        } else { // Unknown
          errMsg = "Unknown error";
        }
        $('.geolocate-status').text(errMsg);
      }
    );
  } else {
    $('.geolocate-status').html("<span>Sorry... can't auto-locate you.</span>");
  }
}

