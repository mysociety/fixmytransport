// Mapping functions

var map;
function init() {
  var problemCoords = new OpenLayers.LonLat(problem_lon, problem_lat);
  createMap(problemCoords);
  addProblemMarker(problemCoords);
}

function createMap(centerCoords) {
  map = new OpenLayers.Map('map');
  var gmap = new OpenLayers.Layer.Google( "Google Streets", {numZoomLevels: 20});
  map.addLayer(gmap);
  map.setCenter(centerCoords,19);  
}

function addProblemMarker(problemCoords) {
  var problemIconWidth = 50;
  var problemIconHeight = 38;
  var markers = new OpenLayers.Layer.Markers( "Markers" );
  map.addLayer(markers);
  var size = new OpenLayers.Size(problemIconWidth, problemIconHeight);
  var offset = new OpenLayers.Pixel(-(size.w/2), -size.h);
  var problemIcon = new OpenLayers.Icon('/images/warning-sign-sm.png', size, offset);
  markers.addMarker(new OpenLayers.Marker(problemCoords, problemIcon));
  
}

// Run jquery in no-conflict mode so it doesn't use $()
jQuery.noConflict();

jQuery(document).ready(function(){
   init();
});
