// Mapping functions

var map;
var proj = new OpenLayers.Projection("EPSG:4326");
var selectControl;
var openPopup;
var stopsById = new Array();
var segmentStyle =
{
  strokeColor: "#CC0000",
  strokeOpacity: 0.7,
  strokeWidth: 4
};
    
var segmentSelectedStyle =
{
  strokeColor: "#000000",
  strokeOpacity: 0.7,
  strokeWidth: 4
};

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

function route_init() {
		  
  createMap();
  bounds = new OpenLayers.Bounds();
  var markers = new OpenLayers.Layer.Markers( "Markers", {projection: proj});
  var vectorLayer = new OpenLayers.Layer.Vector("Vector Layer",{projection: proj});
  map.addLayer(markers);
  map.addLayer(vectorLayer);
  addSelectedHandler(vectorLayer);
  for (var i=0; i < routeSegments.length; i++){
     var coords = routeSegments[i];
     var fromCoords = new OpenLayers.LonLat(coords[0][1], coords[0][0]);
     var toCoords = new OpenLayers.LonLat(coords[1][1], coords[1][0]);
     fromCoords.transform(proj, map.getProjectionObject());
     toCoords.transform(proj, map.getProjectionObject());     
     var fromPoint = new OpenLayers.Geometry.Point(fromCoords.lon, fromCoords.lat);
     var toPoint = new OpenLayers.Geometry.Point(toCoords.lon, toCoords.lat);
     var points = [];
     points.push(fromPoint);
     points.push(toPoint)
     bounds.extend(fromPoint);
     bounds.extend(toPoint);
     addRouteMarker(fromCoords, bounds, markers, coords[0][2], coords[0][3], coords[0][4], 0);
     addRouteMarker(toCoords, bounds, markers, coords[1][2], coords[1][3], coords[1][4], 0);
     lineString = new OpenLayers.Geometry.LineString(points);
     lineFeature = new OpenLayers.Feature.Vector(lineString, {projection: proj}, segmentStyle);
     lineFeature.segment_id = coords[2];
     vectorLayer.addFeatures([lineFeature]);
   }
   map.zoomToExtent(bounds, false); 

}

function addSelectedHandler(vectorLayer) {
  vectorLayer.events.on({
      'featureselected': segmentSelected,
      'featureunselected': segmentUnselected
  });
  selectControl = new OpenLayers.Control.SelectFeature(vectorLayer, {multiple: false,
                                                                     toggleKey: "ctrlKey",
                                                                     multipleKey: "shiftKey"});
  map.addControl(selectControl);
  selectControl.activate();
}

function segmentSelected(event) {
  segment = event.feature;
  segment.style = segmentSelectedStyle;
  this.drawFeature(segment);
  var row = jQuery("#route_segment_" + segment.segment_id);
  row.toggleClass("selected");
  row.find(".check-route-segment").attr('checked', 'true');
}

function segmentUnselected(event) {
  segment = event.feature;
  segment.style = segmentStyle;
  this.drawFeature(segment);
  jQuery("#route_segment_" + segment.segment_id).toggleClass("selected");
  
}

function createMap() {

  var options = { 
        'projection': new OpenLayers.Projection("EPSG:900913"),
        'units': "m",
        'numZoomLevels': 18,
        'maxResolution': 156543.0339,
        'maxExtent': new OpenLayers.Bounds(-20037508.34, -20037508.34,
                                          20037508.34, 20037508.34)
      };
  jQuery('.static-map-element').hide();    
  map = new OpenLayers.Map('map', options);
  var layer = new OpenLayers.Layer.Google("Google Streets",{'sphericalMercator': true,
                                                           'maxExtent': new OpenLayers.Bounds(-20037508.34, -20037508.34,
                                                                                            20037508.34, 20037508.34)});
  map.addLayer(layer); 
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
  marker.events.register("click", marker, stopSelected);
  markers.addMarker(marker);
}

// Run jquery in no-conflict mode so it doesn't use $()
jQuery.noConflict();

