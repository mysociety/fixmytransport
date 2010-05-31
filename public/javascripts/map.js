// Mapping functions

var map;
var proj = new OpenLayers.Projection("EPSG:4326");
var selectControl;

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
  var vectorLayer = new OpenLayers.Layer.Vector("Vector Overlay");
  map.addLayer(vectorLayer);  
  addRouteMarker(stopCoords, bounds, vectorLayer, '', stop_name);
  addSelectedHandler(vectorLayer);
}

function area_init() {
  createMap();
  var stopCoords;
  bounds = new OpenLayers.Bounds();
  var vectorLayer = new OpenLayers.Layer.Vector("Vector Overlay");
  map.addLayer(vectorLayer);
  for (var i=0; i < areaStops.length; i++){
    var coords = areaStops[i];
    stopCoords = new OpenLayers.LonLat(coords[1], coords[0]).transform(proj, map.getProjectionObject());
    addRouteMarker(stopCoords, bounds, vectorLayer, coords[2], coords[3]);
  }
  addSelectedHandler(vectorLayer);
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
  selectControl.unselect(this.feature);
}

function stopUnselected(evt) {
  feature = evt.feature;
  if (feature.popup) {
      popup.feature = null;
      map.removePopup(feature.popup);
      feature.popup.destroy();
      feature.popup = null;
  }
}
function stopSelected (evt) {
  var feature = evt.feature;
  popup = new OpenLayers.Popup.FramedCloud("featurePopup",
                                            feature.geometry.getBounds().getCenterLonLat(),
                                            new OpenLayers.Size(100,100),
                                            '<h3><a href="' + feature.attributes.url + '">'+
                                            feature.attributes.name + '</a></h3>',
                                            null, true, onPopupClose);
  feature.popup = popup;
  popup.feature = feature;
  map.addPopup(popup);

}

function addRouteMarker(stopCoords, bounds, vectorLayer, url, name) {
  bounds.extend(stopCoords);
  var point = new OpenLayers.Geometry.Point(stopCoords.lon, stopCoords.lat);
  var marker = new OpenLayers.Feature.Vector(point,
                                            {url: url, 
                                             name: name},
                                            {externalGraphic: '/images/circle-icon-sm.png', 
                                            graphicHeight: 6, graphicWidth: 6});
  vectorLayer.addFeatures(marker);
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

