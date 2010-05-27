// Mapping functions

var map;
var proj = new OpenLayers.Projection("EPSG:4326");

function problem_init() {
  var problemCoords = new OpenLayers.LonLat(problem_lon, problem_lat).transform(proj, map.getProjectionObject());
  createMap();
  map.setCenter(problemCoords, 12); 
  addProblemMarker(problemCoords);
}

function stop_init() {
  createMap();
  var stopCoords = new OpenLayers.LonLat(stop_lon, stop_lat).transform(proj, map.getProjectionObject());
  map.setCenter(stopCoords, 17); 
  bounds = new OpenLayers.Bounds();
  var markers = new OpenLayers.Layer.Markers( "Markers" );
  map.addLayer(markers);
  addRouteMarker(stopCoords, bounds, markers);
}

function random_colour() 
{ 
   var red = Math.floor(Math.random() * 255); 
   var green = Math.floor(Math.random() * 255); 
   var blue = Math.floor(Math.random() * 255); 
   return 'rgb('+red+','+green+','+blue+')'; 

} 

function area_init() {
  createMap();
  var stopCoords;
  bounds = new OpenLayers.Bounds();
  var markers = new OpenLayers.Layer.Markers( "Markers" );
  map.addLayer(markers);
  for (var i=0; i < areaStops.length; i++){
    var coords = areaStops[i];
    stopCoords = new OpenLayers.LonLat(coords[1], coords[0]).transform(proj, map.getProjectionObject());
    addRouteMarker(stopCoords, bounds, markers);
  }
  map.zoomToExtent(bounds, false);
}

function createMap() {
  var options = { 
        projection: new OpenLayers.Projection("EPSG:900913"),
        displayProjection: new OpenLayers.Projection("EPSG:4326"),
        units: "m",
        numZoomLevels: 18,
        maxResolution: 156543.0339,
        maxExtent: new OpenLayers.Bounds(-20037508, -20037508,
                                          20037508, 20037508.34)
      };
  map = new OpenLayers.Map('map', options);
  var gmap = new OpenLayers.Layer.Google("Google Streets",{'sphericalMercator': true});
  map.addLayer(gmap); 
}

function addRouteMarker(stopCoords, bounds, markers) {
  var problemIconWidth = 6;
  var problemIconHeight = 6;
  bounds.extend(stopCoords);
  var size = new OpenLayers.Size(problemIconWidth, problemIconHeight);
  var offset = new OpenLayers.Pixel(-(size.w/2), -size.h/2);
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

