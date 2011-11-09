// Mapping functions

var map;
var markers;
var otherMarkers;
var stopsById = new Array();
var proj = new OpenLayers.Projection("EPSG:4326");
var selectControl;
var openPopup;
var openHover;
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

// Handle a click on a marker - go to its URL
function markerClick(evt) {
  if (evt.feature.attributes.url) {
    window.location =  evt.feature.attributes.url;
  }
  OpenLayers.Event.stop(evt);
}

function area_init() {
  // Vector layers must be added onload for IE
  if ($.browser.msie) {
      $(window).load(createAreaMap);
  } else {
      createAreaMap();
  }
}

function createAreaMap(){
  createMap('map');
  bounds = new OpenLayers.Bounds();
  
  // layers for markers that are the current focus (markers), other markers in the area
  // (otherMarkers) and other markers that are significant (highlightedMarkers)
  // - e.g. locations with problem reports, rather than without when browsing 
  // an area.
  markers = new OpenLayers.Layer.Vector( "Markers" );
  otherMarkers = new OpenLayers.Layer.Vector( "Other Markers" );
  highlightedMarkers = new OpenLayers.Layer.Vector( "Highlighted Markers" );
  map.addLayer(otherMarkers);
  map.addLayer(highlightedMarkers);
  map.addLayer(markers);  

  // All markers should handle to a click event
  markers.events.register( 'featureselected', markers, markerClick );
  otherMarkers.events.register( 'featureselected', otherMarkers, markerClick );
  highlightedMarkers.events.register( 'featureselected', highlightedMarkers, markerClick );
  var select = new OpenLayers.Control.SelectFeature( [markers, otherMarkers, highlightedMarkers] );
  map.addControl( select );
  select.activate();
  
  // Load the main markers, and the background markers (in either the highlighted or other layer)
  addMarkerList(areaStops, markers, false, null);
  addMarkerList(otherAreaStops, otherMarkers, true, highlightedMarkers);

  centerCoords =  new OpenLayers.LonLat(lon, lat);
  centerCoords.transform(proj, map.getProjectionObject());
  map.setCenter(centerCoords, zoom);

  if (findOtherLocations == true) {
    map.events.register('moveend', map, updateLocations);
  }

  // if we're constrained to less than the expected map dimensions, try
  // to make sure the markers are all shown
  if (($('#map').width() < mapWidth || $('#map').height() < mapHeight) && (areaStops.length > 0)) {
    map.zoomToExtent(bounds, false);
  }
    
  // Enforce some zoom constraints
  map.events.register("zoomend", map, function() {
      // World zoom resets map
      if (map.getZoom() == 0) {
        map.setCenter(centerCoords, zoom);
        return;
      }
      if (map.getZoom() < minZoom) map.zoomTo(minZoom);
      if (map.getZoom() > maxZoom) map.zoomTo(maxZoom);
  });

  
}

function updateLocations(event) {
  var currentZoom = map.getZoom();
  if (currentZoom >= minZoomForOtherMarkers){
    if ($('#map-zoom-notice').length > 0) {
      $('#map-zoom-notice').fadeOut(500);
    }
    // Show other, non-highlighted markers
    otherMarkers.setVisibility(true)
  }else{
    if ($('#map-zoom-notice').length > 0) {
      $('#map-zoom-notice').fadeIn(500);
    }
    // Hide other, non-highlighted markers
    otherMarkers.setVisibility(false)
  }
  // Request and load markers by ajax
  if (currentZoom >= minZoomForOtherMarkers || highlight == 'has_content'){
    center = map.getCenter();
    center = center.transform(map.getProjectionObject(), proj);
    url = "/locations/" + map.getZoom() + "/" + Math.round(center.lat*1000)/1000 + "/" + Math.round(center.lon*1000)/1000 + "/" + linkType;
    params = "?height=" + $('#map').height() + "&width=" + $('#map').width();
    params = params + "&highlight=" + highlight;
    $.ajax({
      url: url + params,
      dataType: 'json',
      success: loadNewMarkers,
      failure: markerFail})
  }

}

function loadNewMarkers(markerData) {
  newMarkers = markerData['locations'];
  // load new background markers
  addMarkerList(newMarkers, otherMarkers, true, highlightedMarkers);
  // update any associated list of issues
  newContent = markerData['issue_content'];
  if ($('#issues-in-area').length > 0){
    $('#issues-in-area').html(newContent);
  }
}

function markerFail(){
// do nothing
}

function addMarkerList(list, layer, others, highlightedLayer) {
  for (var i=0; i < list.length; i++){
    var item = list[i];
    // an element in the list may be an individual marker or an array
    // of markers representing a route
    if (item instanceof Array){
      for (var j=0; j < item.length; j++){
        addMarker(item[j], bounds, layer, others, highlightedLayer);
      }
    }else{
      addMarker(item, bounds, layer, others, highlightedLayer);
    }
  }
}


function addMarker(current, bounds, layer, other, highlightedLayer){
  stopCoords = pointCoords(current.lon, current.lat);

  if (stopsById[current.id] == undefined) {
    bounds.extend(stopCoords);
    var marker = new OpenLayers.Feature.Vector(stopCoords, {
      url: current.url,
      name: current.description,
      id: current.id,
      highlight: current.highlight,
    },
    {externalGraphic: current.icon + ".png",
        graphicTitle: current.description,
        graphicWidth: current.width,
        graphicHeight: current.height,
        graphicOpacity: 1,
        graphicXOffset: -( current.width/2),
        graphicYOffset: -current.height,
        cursor: 'pointer'
    });    

    stopsById[current.id] = marker;
    if (current.highlight == true && other == true) {
      highlightedLayer.addFeatures( marker );
    }else{
      layer.addFeatures( marker );
    }
  }

}

function pointCoords(lon, lat) {
  return new OpenLayers.Geometry.Point(lon, lat).transform(proj, map.getProjectionObject());
}

function route_init(map_element, routeSegments) {

  createMap(map_element);
  bounds = new OpenLayers.Bounds();

  var vectorLayer = new OpenLayers.Layer.Vector("Vector Layer",{projection: proj});
  map.addLayer(vectorLayer);

  addSelectedHandler(vectorLayer);
  for (var i=0; i < routeSegments.length; i++){
     var coords = routeSegments[i];
     var fromCoords = pointCoords(coords[0].lon, coords[0].lat);
     var toCoords = pointCoords(coords[1].lon, coords[1].lat);
     var points = [];
     points.push(fromCoords);
     points.push(toCoords)
     bounds.extend(fromCoords);
     bounds.extend(toCoords);
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
  var row = $("#route_segment_" + segment.segment_id);
  row.toggleClass("selected");
  row.find(".check-route-segment").attr('checked', 'true');
}

function segmentUnselected(event) {
  segment = event.feature;
  segment.style = segmentStyle;
  this.drawFeature(segment);
  $("#route_segment_" + segment.segment_id).toggleClass("selected");

}

function createMap(map_element) {
  OpenLayers.ImgPath='/javascripts/img/';
  var options = {
        'projection': new OpenLayers.Projection("EPSG:900913"),
        'units': "m",
        'numZoomLevels': 18,
        'maxResolution': 156543.0339,
        'theme': null,
        'maxExtent': new OpenLayers.Bounds(-20037508.34, -20037508.34,
                                          20037508.34, 20037508.34)
      };
  $('.static-map-element').hide();
  map = new OpenLayers.Map(map_element, options);
  var layer = new OpenLayers.Layer.Google("Google Streets",{'sphericalMercator': true,
                                                           'maxExtent': new OpenLayers.Bounds(-20037508.34, -20037508.34,
                                                                                            20037508.34, 20037508.34)});
  map.addLayer(layer);
}






