// Mapping functions

var map;

function problem_init() {
  var problemCoords = new OpenLayers.LonLat(problem_lon, problem_lat);
  createMap(problemCoords);
  addProblemMarker(problemCoords);
}

function stop_init() {
  var stopCoords = new OpenLayers.LonLat(stop_lon, stop_lat);
  createMap(stopCoords);
  bounds = new OpenLayers.Bounds();
  var markers = new OpenLayers.Layer.Markers( "Markers" );
  map.addLayer(markers);
  addRouteMarker(stopCoords, bounds, markers);
}

function route_init() {
  var firstCoords = new OpenLayers.LonLat(centre[0], centre[1]);
  createMap(firstCoords);
  var stopCoords;
  bounds = new OpenLayers.Bounds();
  var markers = new OpenLayers.Layer.Markers( "Markers" );
  map.addLayer(markers);
  for (var i=0; i < routeStops.length; i++){
    var coords = routeStops[i];
    stopCoords = new OpenLayers.LonLat(coords[1], coords[0]);
    addRouteMarker(stopCoords, bounds, markers);
  }
  map.zoomToExtent(bounds, false);
}

function createMap(centerCoords) {
  map = new OpenLayers.Map('map');
  var gmap = new OpenLayers.Layer.Google( "Google Streets", {numZoomLevels: 20});
  map.addLayer(gmap);
  map.setCenter(centerCoords, 12);  
}

function addRouteMarker(stopCoords, bounds, markers) {
  var problemIconWidth = 6;
  var problemIconHeight = 6;
  bounds.extend(stopCoords)
  var size = new OpenLayers.Size(problemIconWidth, problemIconHeight);
  var offset = new OpenLayers.Pixel(-(size.w/2), -size.h);
  var stopIcon = new OpenLayers.Icon('/images/circle-icon-sm.png', size, offset);
  markers.addMarker(new OpenLayers.Marker(stopCoords, stopIcon));  
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

