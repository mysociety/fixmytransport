// js used for fixmytransport geo-locating, tied in with the CSS
// adding class "fmt-has-geolocation" to the parent of the label, input, etc, adds a button

$(function() {
  if (geo_position_js.init()) {
    $('.fmt-has-geolocation').each(function(index){
		var inputId = $(this).find('input').attr("id") || index;
		$(this).find('label').after('<div class="geolocate-container"><span class="geolocate-button" id="geolocate-button-' + inputId + '">Use your current location</span></div>');
	    $('.geolocate-button').click(function(e){ doGeolocate(e, inputId) });
	});
  }
});

function doGeolocate(e, inputId) {
  e.preventDefault();
  $('.geolocate-button').replaceWith("<p class='geolocate-status'>OK... fetching location...</p>");
  if (geo_position_js.init()) { // overkill
    geo_position_js.getCurrentPosition(
      function(position) {
        $('.geolocate-status').html("<span>OK... fetching location done, loading...</span>");
        if ($('#bus_route_form').size()) { // this is find_bus_route: get locality of nearest stop
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
        $('.geolocate-status').html("<span>" + errMsg + "</span>");
      }
    );
  } else {
    $('.geolocate-status').html("<span>Sorry... can't auto-locate you.</span>");
  }
}

