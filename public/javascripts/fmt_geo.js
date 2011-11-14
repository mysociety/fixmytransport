// js used for fixmytransport geo-locating, tied in with the CSS
// adding class "fmt-has-geolocation" to the parent of the label, input, etc, adds a button

$(function() {
  if (geo_position_js.init()) {
    $('#issues-near-you').click(function(e){ doGeolocate(e, this) });
    $('.fmt-has-geolocation').each(function(index){
      var inputId = $(this).find('input, select').not(":hidden").attr("id") || index; // ignore hidden inputs
      $(this).find('label').after('<div class="geolocate-container" id="geolocate-container-' + inputId
            + '"><span class="geolocate-button button" id="geolocate-button-' + inputId
            + '">' + $().fmt_translate('shared.geolocate.use_current_location') + '</span></div>');
      $('#geolocate-button-' + inputId).click(function(e){ doGeolocate(e, inputId) });
    });
  }
});


function doGeolocate(e, inputId) {
  e.preventDefault();
  $('#issues-near-you').parent().append(' <img src="/images/busy_spinner_24_x_24_white.gif" alt="">');
  $('#geolocate-button-' + inputId).replaceWith("<p class='geolocate-status geolocate-busy' id='geolocate-status-" + inputId
    + "'>" + $().fmt_translate('shared.geolocate.fetching') + "</p>");
  $(".geolocate-container").not("#geolocate-container-" + inputId).fadeTo('slow', 0); // if there are multiple buttons, hide the other(s)
  $("#geolocate-container-" + inputId).parent().find(".error").fadeOut('slow'); // error message probably no longer applies
  if (geo_position_js.init()) { // overkill?
    var verySlow = 4800; // if message fades too quickly, discombobulated user thinks: "wha--? did I miss something?"
    geo_position_js.getCurrentPosition(
      function(position) {
        if ($('.fmt-has-geolocation').size()==2) {
          // page with two geolocates: train/ferry/metro:
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
        } else if ($('#bus_route_form').size()) { // this is find_bus_route: get locality of nearest stop
          $('#geolocate-status-' + inputId).text($().fmt_translate('shared.geolocate.loading_bus'));
          $.getJSON(
            '/request_nearest_stop',
            {lon:position.coords.longitude, lat:position.coords.latitude},
            function(stop_data){
              $("#"+inputId).val(stop_data.area);
              // add hidden fields: id and area name (to detect edits *after* geolocation)
              if ($("#lat").size() == 0) {
                $('#bus_route_form').append("<input type='hidden' name='lat' id='lat'/>");
              }
              if ($("#lon").size() == 0) {
                $('#bus_route_form').append("<input type='hidden' name='lon' id='lon'/>");
              }
              if ($("#accuracy").size() == 0) {
                $('#bus_route_form').append("<input type='hidden' name='accuracy' id='accuracy'/>");
              }
              if ($("#geo_area_name").size() == 0) {
                $('#bus_route_form').append("<input type='hidden' name='geo_area_name' id='geo_area_name'/>");
              }
              $("#lat").val(position.coords.latitude);
              $("#lon").val(position.coords.longitude);
              $("#accuracy").val(position.coords.accuracy);
              $("#geo_area_name").val(stop_data.area);
              if ($("#route_number").val() == $("#guidance-route-number").text()) {
                $('#route_number').focus();
              }
            }
          );
        } else if ($('#issues-near-you').size()){
          document.location.href = "/issues/browse?lon="+ position.coords.longitude + "&lat=" + position.coords.latitude
        } else { // this is find_stop (goes straight to lon/lat)
          $('#geolocate-status-' + inputId).text($().fmt_translate('shared.geolocate.loading')); // fleeting
          param_join_char = "&"
          if (document.location.href.indexOf("?") == -1){
            param_join_char = "?"
          }
          document.location.href = document.location.href + param_join_char +"lon=" + position.coords.longitude + "&lat=" + position.coords.latitude

        }
        $('#geolocate-status-' + inputId).text($('#geolocate-status-' + inputId).text() + ' ' + $().fmt_translate('shared.geolocate.loading_done'));
        $('.geolocate-status').removeClass('geolocate-busy').addClass('geolocate-done');
        $('.geolocate-container').fadeTo('slow', 0);
      },
      function(err) {
        var errMsg;
        if (err.code == err.PERMISSION_DENIED) {
          errMsg = $().fmt_translate('shared.geolocate.cancelled');
        } else if (err.code == err.POSITION_UNAVAILABLE) {
          errMsg = $().fmt_translate('shared.geolocate.no_lookup');
        } else if (err.code == err.TIMEOUT) {
          errMsg = $().fmt_translate('shared.geolocate.no_result');
        } else { // Unknown
          errMsg = $().fmt_translate('shared.geolocate.unknown_error');
        }
        if ($('#issues-near-you').size()){
          document.location.href = "/issues/browse?geolocate_error="+err.code;
        }else {
          $('#geolocate-status-' + inputId).removeClass('geolocate-busy').text(errMsg);
        }
      }, { timeout:10000 }
    );
  } else {
    $('#geolocate-status-' + inputId).removeClass('geolocate-busy').text($().fmt_translate('shared.geolocate.cannot_locate'));
  }
}

