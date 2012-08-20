/* -*- mode: espresso; espresso-indent-level: 2; indent-tabs-mode: nil -*- */
/* vim: set softtabstop=2 shiftwidth=2 tabstop=2 expandtab: */

/* Directives for JSLint ---------------------------------------------- */

/*global OpenLayers, $ */
/*global lon, lat, zoom, areaStops, otherAreaStops, findOtherLocations */
/*global minZoomForOtherMarkers, highlight, linkType */
/*global mapWidth, mapHeight, minZoom, maxZoom */

/*jslint browser: true, vars: true, white: true, plusplus: true */
/*jslint continue: true, maxerr: 50, indent: 2 */

/* End of directives for JSLint --------------------------------------- */

var area_init, route_init;

(function () {

  "use strict";

  // Mapping functions

  var map;
  var markers;
  var otherMarkers;
  var stopsById = [];
  var proj = new OpenLayers.Projection("EPSG:4326");
  var selectControl;
  var openPopup;
  var openHover;
  var segmentStyle = {
    strokeColor: "#CC0000",
    strokeOpacity: 0.2,
    strokeWidth: 4
  };

  var segmentSelectedStyle = {
    strokeColor: "#000000",
    strokeOpacity: 0.5,
    strokeWidth: 4
  };

  var bounds;
  var highlightedMarkers;
  var centerCoords;

  // Handle a click on a marker - go to its URL
  function markerClick(evt) {
    if (evt.feature.attributes.url) {
      window.location =  evt.feature.attributes.url;
    }
    OpenLayers.Event.stop(evt);
  }

  function jsPath(filename) {
    var i, r = new RegExp("(^|(.*?\\/))("+filename+"\\.js)(\\?|$)"),
    s = document.getElementsByTagName('script'),
    src, m, result = "", len;
    for(i=0, len=s.length; i<len; i++) {
      src = s[i].getAttribute('src');
      if(src) {
        m = src.match(r);
        if(m) {
          result = m[1];
          break;
        }
      }
    }
    return result;
  }

  function createMap(map_element) {
    // handle both cached and uncached js files in calculating image path
    var javascriptPath = jsPath('OpenLayers');
    if (javascriptPath === ''){
      javascriptPath = jsPath('libraries');
    }
    if (javascriptPath === ''){
      javascriptPath = jsPath('admin_libraries');
    }
    OpenLayers.ImgPath = javascriptPath + 'img/';
    var options = {
      'projection': new OpenLayers.Projection("EPSG:900913"),
      'units': "m",
      'numZoomLevels': 18,
      'maxResolution': 156543.0339,
      'theme': null,
      'maxExtent': new OpenLayers.Bounds(-20037508.34, -20037508.34,
                                         20037508.34, 20037508.34),
      'controls': [
        new OpenLayers.Control.Navigation(),
        new OpenLayers.Control.PanZoom(),
        new OpenLayers.Control.Attribution()
      ]
    };
    $('.static-map-element').hide();
    map = new OpenLayers.Map(map_element, options);
    var layer = new OpenLayers.Layer.Google("Google Streets",{'sphericalMercator': true,
                                                              'maxExtent': new OpenLayers.Bounds(-20037508.34, -20037508.34,
                                                                                                 20037508.34, 20037508.34)});
    map.addLayer(layer);
  }

  function pointCoords(lon, lat) {
    return new OpenLayers.Geometry.Point(lon, lat).transform(proj, map.getProjectionObject());
  }

  function addMarker(current, bounds, layer, other, highlightedLayer){
    var stopCoords = pointCoords(current.lon, current.lat);

    if (stopsById[current.id] === undefined) {
      bounds.extend(stopCoords);
      var marker = new OpenLayers.Feature.Vector(stopCoords, {
        url: current.url,
        name: current.description,
        id: current.id,
        highlight: current.highlight
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
      if (current.highlight === true && other === true) {
        highlightedLayer.addFeatures( marker );
      }else{
        layer.addFeatures( marker );
      }
    }

  }

  function addMarkerList(list, layer, others, highlightedLayer) {
    var i, j, item;
    for (i=0; i < list.length; i++){
      item = list[i];
      // an element in the list may be an individual marker or an array
      // of markers representing a route
      if (item instanceof Array){
        for (j=0; j < item.length; j++){
          addMarker(item[j], bounds, layer, others, highlightedLayer);
        }
      }else{
        addMarker(item, bounds, layer, others, highlightedLayer);
      }
    }
  }

  function loadNewMarkers(markerData) {
    var newMarkers, newContent;
    newMarkers = markerData.locations;
    // load new background markers
    addMarkerList(newMarkers, otherMarkers, true, highlightedMarkers);
    // update any associated list of issues
    newContent = markerData.issue_content;
    if ($('#issues-in-area').length > 0){
      $('#issues-in-area').html(newContent);
    }
  }

  function markerFail(){
    // do nothing
  }

  function replaceAtomLink(data, textStatus, jqXHR) {
    $('#in-page-atom-link').replaceWith(data);
  }

  function replaceAtomLinkFailure(jqXHR, textStatus, errorThrown) {
    // ignore errors here; there's nothing much that can be done
  }

  /* This function should be passed a string like:

       ?foo=bar&baz=quux

     .... such as window.location.search.  It will return an object
     that maps keys to values.  e.g. for the input above, the returned
     object would be:

     {'foo': 'bar',
      'baz': 'quux'}
  */
  function getQueryStringParametersMap(searchPart) {
    // Based on: http://stackoverflow.com/a/3855394/223092
    var result = {}, i, value, parts, keyValuePairs;
    if (searchPart[0] != '?') {
      throw new Error('The argument to getQueryStringParametersMap must be a search string beginning with \'?\'');
    }
    keyValuePairs = searchPart.substr(1).split('&');
    if (!keyValuePairs) {
      return result;
    }
    for (i = 0; i < keyValuePairs.length; ++i) {
      parts = keyValuePairs[i].split('=');
      // Skip over any malformed parts with multiple = signs:
      if (parts.length !== 2) {
        continue;
      }
      value = decodeURIComponent(parts[1].replace(/\+/g, " "));
      result[parts[0]] = value;
    }
    return result;
  }

  function updateURLParameters(originalURL, parametersToSet) {
    /* Use the DOM to parse the URL, using the nice trick from here:
       http://james.padolsey.com/javascript/parsing-urls-with-the-dom/ */
    var a = document.createElement('a'),
        originalParameters,
        result,
        questionMarkIndex,
        toJoin = [],
        key;
    questionMarkIndex = originalURL.indexOf('?');
    if (questionMarkIndex >= 0) {
      result = originalURL.substr(0, questionMarkIndex);
    } else {
      result = originalURL;
    }
    a.href = originalURL;
    originalParameters = getQueryStringParametersMap(a.search);
    jQuery.extend(originalParameters, parametersToSet);
    result += '?';
    for (key in originalParameters) {
      if (originalParameters.hasOwnProperty(key)) {
        toJoin.push(key + '=' + encodeURIComponent(originalParameters[key]));
      }
    }
    return result + toJoin.join('&');
  }

  function updateLocations(eevent) {
    var currentZoom = map.getZoom(), newLat, newLon, newPath, url;
    var parametersObject, mapParametersObject;
    var parameters, key, center, mapViewParameters;
    var positionKeys = {'lon': true,
                        'lat': true,
                        'zoom': true};
    if (currentZoom >= minZoomForOtherMarkers){
      if ($('#map-zoom-notice').length > 0) {
        $('#map-zoom-notice').fadeOut(500);
      }
      // Show other, non-highlighted markers
      otherMarkers.setVisibility(true);
    }else{
      if ($('#map-zoom-notice').length > 0) {
        $('#map-zoom-notice').fadeIn(500);
      }
      // Hide other, non-highlighted markers
      otherMarkers.setVisibility(false);
    }
    // Request and load markers by ajax
    if (currentZoom >= minZoomForOtherMarkers || highlight === 'has_content'){
      center = map.getCenter();
      center = center.transform(map.getProjectionObject(), proj);
      newLat = Math.round(center.lat*1000)/1000;
      newLon = Math.round(center.lon*1000)/1000;
      mapViewParameters = map.getZoom() + "/" + newLat + "/" + newLon;
      url = "/locations/" + mapViewParameters + "/" + linkType;
      parameters = "?height=" + $('#map').height() + "&width=" + $('#map').width();
      parameters = parameters + "&highlight=" + highlight;
      $.ajax({
        url: url + parameters,
        dataType: 'json',
        success: loadNewMarkers,
        failure: markerFail});
      $.ajax({
        url: "/issues/browse/atom_link/" + mapViewParameters,
        dataType: 'html',
        success: replaceAtomLink,
        failure: replaceAtomLinkFailure});
      mapParametersObject = {'lon': newLon, 'lat': newLat, 'zoom': currentZoom};
      // If we're able to replace the URL with history.replaceState,
      // update it to give a permalink to the new map position:
      if (history.replaceState) {
        parametersObject = getQueryStringParametersMap(window.location.search);
        jQuery.extend(parametersObject, mapParametersObject);
        newPath = updateURLParameters(window.location.href, parametersObject);
        history.replaceState(null, "New Map Position", newPath);
      }
      // Also update the parameters in the "choose from a list
      // instead" link, so that after dragging or zooming the map, the
      // alternative list will match:
      $('.choose-from-list').each(function (index, element) {
        element.href = updateURLParameters(element.href, mapParametersObject);
      });
    }
  }

  function createAreaMap(){
    var centerCoords, select;
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
    select = new OpenLayers.Control.SelectFeature( [markers, otherMarkers, highlightedMarkers] );
    map.addControl( select );
    select.activate();

    // Load the main markers, and the background markers (in either the highlighted or other layer)
    addMarkerList(areaStops, markers, false, null);
    addMarkerList(otherAreaStops, otherMarkers, true, highlightedMarkers);

    centerCoords =  new OpenLayers.LonLat(lon, lat);
    centerCoords.transform(proj, map.getProjectionObject());
    map.setCenter(centerCoords, zoom);

    if (findOtherLocations === true) {
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
      if (map.getZoom() === 0) {
        map.setCenter(centerCoords, zoom);
        return;
      }
      if (map.getZoom() < minZoom) {
        map.zoomTo(minZoom);
      }
      if (map.getZoom() > maxZoom) {
        map.zoomTo(maxZoom);
      }
    });

  }

  area_init = function() {
    // Vector layers must be added onload for IE
    if ($.browser.msie) {
      $(window).load(createAreaMap);
    } else {
      createAreaMap();
    }
  };

  function segmentSelected(event) {
    var segment = event.feature;
    segment.style = segmentSelectedStyle;
    // FIXME: a strict violation
    this.drawFeature(segment);
    var row = $("#route_segment_" + segment.segment_id);
    row.toggleClass("selected");
    row.find(".check-route-segment").attr('checked', 'true');
  }

  function segmentUnselected(event) {
    var segment = event.feature;
    segment.style = segmentStyle;
    // FIXME: a strict violation
    this.drawFeature(segment);
    $("#route_segment_" + segment.segment_id).toggleClass("selected");
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

  route_init = function(map_element, routeSegments) {

    var vectorLayer, i, coords, fromCoords, toCoords, points;
    var lineString, lineFeature;

    createMap(map_element);
    bounds = new OpenLayers.Bounds();

    vectorLayer = new OpenLayers.Layer.Vector("Vector Layer",{projection: proj});
    map.addLayer(vectorLayer);

    addSelectedHandler(vectorLayer);
    for (i=0; i < routeSegments.length; i++){
      coords = routeSegments[i];
      fromCoords = pointCoords(coords[0].lon, coords[0].lat);
      toCoords = pointCoords(coords[1].lon, coords[1].lat);
      points = [];
      points.push(fromCoords);
      points.push(toCoords);
      bounds.extend(fromCoords);
      bounds.extend(toCoords);
      lineString = new OpenLayers.Geometry.LineString(points);
      lineFeature = new OpenLayers.Feature.Vector(lineString, {projection: proj}, segmentStyle);
      lineFeature.segment_id = coords[2];
      vectorLayer.addFeatures([lineFeature]);
    }
    map.zoomToExtent(bounds, false);

  }

}());
