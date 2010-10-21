// Mapping functions

var map;
var markers;
var otherMarkers;
var stopsById = new Array();
var proj = new OpenLayers.Projection("EPSG:4326");
var selectControl;
var openPopup;
var segmentStyle =
{
  strokeColor: "#CC0000",
  strokeOpacity: 0.2,
  strokeWidth: 4
};
    
var segmentSelectedStyle =
{
  strokeColor: "#000000",
  strokeOpacity: 0.5,
  strokeWidth: 4
};

function area_init() {
  createMap();
  bounds = new OpenLayers.Bounds();
  markers = new OpenLayers.Layer.Markers( "Markers" );
  otherMarkers = new OpenLayers.Layer.Markers( "Other Markers" );
  map.addLayer(otherMarkers);
  map.addLayer(markers);
  addMarkerList(areaStops, markers, false);
  if (findOtherLocations == true) {
    map.events.register('moveend', map, updateLocations); 
  }
  centerCoords =  new OpenLayers.LonLat(lon, lat);
  centerCoords.transform(proj, map.getProjectionObject());
  map.setCenter(centerCoords, zoom);
}

function updateLocations(event) {
  center = map.getCenter();
  center = center.transform(map.getProjectionObject(), proj);
  OpenLayers.loadURL("/locations/" + map.getZoom() + "/" + center.lat + "/" + center.lon, {}, this, loadNewMarkers, markerFail);
}

function loadNewMarkers(response) {
  json = new OpenLayers.Format.JSON();
  newMarkers = json.read(response.responseText);
  addMarkerList(newMarkers, otherMarkers, true);
}

function markerFail(){
}

function addMarkerList(list, markers, others) {
  var stopCoords;

  for (var i=0; i < list.length; i++){
    var item = list[i];
    if (item instanceof Array){
      for (var j=0; j < item.length; j++){
        addMarker(item[j], bounds, markers, others);
      }
    }else{
      addMarker(item, bounds, markers, others);
    }
  }
}

function addMarker(current, bounds, layer, other){
  stopCoords = pointCoords(current.lon, current.lat);
  addRouteMarker(stopCoords, bounds, layer, current, other);
}

function pointCoords(lon, lat) {
  return new OpenLayers.LonLat(lon, lat).transform(proj, map.getProjectionObject());
}

function route_init() {
		  
  createMap();
  bounds = new OpenLayers.Bounds();
  
  var vectorLayer = new OpenLayers.Layer.Vector("Vector Layer",{projection: proj});
  var markers = new OpenLayers.Layer.Markers( "Markers", {projection: proj});
  map.addLayer(vectorLayer);
  map.addLayer(markers);
  
  addSelectedHandler(vectorLayer);
  for (var i=0; i < routeSegments.length; i++){
     var coords = routeSegments[i];
     var fromCoords = pointCoords(coords[0].lon, coords[0].lat);
     var toCoords = pointCoords(coords[1].lon, coords[1].lat);
     var fromPoint = new OpenLayers.Geometry.Point(fromCoords.lon, fromCoords.lat);
     var toPoint = new OpenLayers.Geometry.Point(toCoords.lon, toCoords.lat);
     var points = [];
     points.push(fromPoint);
     points.push(toPoint)
     bounds.extend(fromPoint);
     bounds.extend(toPoint);
     addRouteMarker(fromCoords, bounds, markers, coords[0], false);
     addRouteMarker(toCoords, bounds, markers, coords[1], false);
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

function addRouteMarker(stopCoords, bounds, markers, item, other) {
  if (stopsById[item.id] == undefined) {
    bounds.extend(stopCoords);
    var size = new OpenLayers.Size(item.width, item.height);
    var offset = new OpenLayers.Pixel(-(size.w/2), -size.h/2);
    var stopIcon = new OpenLayers.Icon("/images/" + item.icon + ".png", size, offset);
    var marker = new OpenLayers.Marker(stopCoords, stopIcon);
    marker.url = item.url;
    marker.name = item.description;
    marker.id = item.id;
    stopsById[item.id] = marker;
    marker.events.register("click", marker, stopSelected);
    markers.addMarker(marker);
  }
}

// Run jquery in no-conflict mode so it doesn't use $()
jQuery.noConflict();

