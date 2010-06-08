// Mapping functions

var map;
var proj = new OpenLayers.Projection("EPSG:4326");
var selectControl;
var openPopup;
var stopsById = new Array();

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
  addRouteMarker(stopCoords, bounds, markers, stop_id, '', stop_name, 0);
}

function area_init() {
  createMap();
  var stopCoords;
  bounds = new OpenLayers.Bounds();
  var markers = new OpenLayers.Layer.Markers( "Markers" );
  map.addLayer(markers);
  for (var i=0; i < areaStops.length; i++){
    var item = areaStops[i];
    if (item[0] instanceof Array){
      for (var j=0; j < item.length; j++){
        coords = item[j];
        stopCoords = new OpenLayers.LonLat(coords[1], coords[0]).transform(proj, map.getProjectionObject());
        addRouteMarker(stopCoords, bounds, markers, coords[2], coords[3], coords[4], i);
      }
    }else{
      coords = item;
      stopCoords = new OpenLayers.LonLat(coords[1], coords[0]).transform(proj, map.getProjectionObject());
      addRouteMarker(stopCoords, bounds, markers, coords[2], coords[3], coords[4], i);
    }
    
    
  }
  map.zoomToExtent(bounds, false);
}

function addSelectedHandler(vectorLayer) {
  vectorLayer.events.on({
      'featureselected': stopSelected,
      'featureunselected': stopUnselected
  });
  selectControl = new OpenLayers.Control.SelectFeature(vectorLayer);
  map.addControl(selectControl);
  selectControl.activate();
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

function onPopupClose(evt) {
  stopUnselected(this.stop);
}

function stopUnselected(stop) {
  if (stop && stop.popup) {
      popup.stop = null;
      map.removePopup(stop.popup);
      stop.popup.destroy();
      stop.popup = null;
  }
}
function stopSelected () {
  selectStop(this);
}

function selectStop(stop) {
  if (openPopup){
    stopUnselected(openPopup.stop);
    openPopup = null;
  }
  popup = new OpenLayers.Popup.AnchoredBubble("stopPopup",
                                            stop.lonlat,
                                            new OpenLayers.Size(50,50),
                                            '<a href="' + stop.url + '">'+
                                            stop.name + '</a>',
                                            null, true, onPopupClose);
  popup.autoSize = true;
  stop.popup = popup;
  popup.stop = stop;
  map.addPopup(popup);
  openPopup = popup;  
}

function addRouteMarker(stopCoords, bounds, markers, id, url, name, index) {
  bounds.extend(stopCoords);
  var size = new OpenLayers.Size(6, 6);
  var offset = new OpenLayers.Pixel(-(size.w/2), -size.h);
  var stopIcon = new OpenLayers.Icon('/images/circle-icon-sm_'+index+'.png', size, offset);
  var marker = new OpenLayers.Marker(stopCoords, stopIcon);
  marker.url = url;
  marker.name = name;
  marker.id = id;
  stopsById[id] = marker;
  marker.events.register("mouseover", marker, stopSelected);
  markers.addMarker(marker);
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

jQuery(document).ready(function() {
  jQuery("li.active-stop").hover(function(stop){
    selectStop(stopsById[this.id]);
  })
});

