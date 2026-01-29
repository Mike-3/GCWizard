//https://datatracker.ietf.org/doc/html/rfc7946

import 'dart:core';

import 'package:gc_wizard/tools/coords/_common/formats/dec/logic/dec.dart';
//import 'package:gc_wizard/tools/coords/_common/logic/coordinates.dart';
import 'package:gc_wizard/tools/coords/map_view/logic/map_geometries.dart';
import 'package:gc_wizard/tools/coords/map_view/persistence/model.dart';
import 'package:gc_wizard/utils/json_utils.dart';
import 'package:latlong2/latlong.dart';

import 'gpx_kml_gpx_import.dart';

enum geoJsonLabel {
  type,
  geometry,
  coordinates,
  features,
  geometries,
  properties,
  bbox
}

enum geoJsonLabelTypes {
  Point,
  LineString,
  Polygon,
  MultiPoint,
  MultiLineString,
  MultiPolygon,
  Feature,
  FeatureCollection,
  GeometryCollection,
}

class GeoJsonReader {

  MapViewDAO? parse(String input) {
    var jsonMap = asJsonMap(input);

    var list = <MapViewDAO>[];
    if (jsonMap.containsKey(geoJsonLabel.type.name)) {
      if (jsonMap.containsKey(geoJsonLabel.features.name) &&
          jsonMap[geoJsonLabel.type.name] == geoJsonLabelTypes.FeatureCollection.name) {

          asJsonArray(jsonMap[geoJsonLabel.features.name]).forEach((jsonFeature) {
            var feature = _parseFeature(jsonFeature?.toString() ?? '');
            if (feature != null) {
              list.add(feature);
            }
          });

      } else if (jsonMap.containsKey(geoJsonLabel.geometry.name) &&
          jsonMap[geoJsonLabel.type.name] == geoJsonLabelTypes.Feature.name) {

        var feature = _parseFeature(input);
        if (feature != null) {
          list.add(feature);
        }
      }
    }

    if (list.isEmpty) return null;

    for (var i = 1; i < list.length; i++) {
      list.first.points.addAll(list[i].points);
      list.first.polylines.addAll(list[i].polylines);
    }

    return list.first;
  }

  MapViewDAO? _parseFeature(String input) {
    var jsonMap = asJsonMap(input);
    if (!jsonMap.containsKey(geoJsonLabel.geometry.name)) return null;

    var geometry = _parseGeometry(jsonMap[geoJsonLabel.geometry.name]?.toString() ?? '');

    return geometry;
  }

  MapViewDAO? _parseGeometry(String input) {
    var jsonMap = asJsonMap(input);
    if (!jsonMap.containsKey(geoJsonLabel.type.name) ||
        !jsonMap.containsKey(geoJsonLabel.coordinates.name)) {
      return null;
    }
    var coordinates =  _parseCoordinates(jsonMap[geoJsonLabel.coordinates.name]?.toString() ?? '');
    if (coordinates.isEmpty) return null;

    var points = <GCWMapPoint>[];
    var lines = <GCWMapPolyline>[];

    if (jsonMap[geoJsonLabel.type.name] == geoJsonLabelTypes.Point.name) {
      if (coordinates.first.isNotEmpty) {
        points.add(coordinates.first.first);
      }
    } else    if (jsonMap[geoJsonLabel.type.name] == geoJsonLabelTypes.MultiPoint.name) {
      for (var list in coordinates) {
        if (list.isNotEmpty) {
          points.add(list.first);
        }
      }
    } else if (jsonMap[geoJsonLabel.type.name] == geoJsonLabelTypes.LineString.name)  {
      if (coordinates.first.length > 1) {
        lines.add(GCWMapPolyline(points: coordinates.first));
      }
    } else if (jsonMap[geoJsonLabel.type.name] == geoJsonLabelTypes.Polygon.name ||
        jsonMap[geoJsonLabel.type.name] == geoJsonLabelTypes.MultiPolygon.name ||
        jsonMap[geoJsonLabel.type.name] == geoJsonLabelTypes.MultiLineString.name)  {
        for (var list in coordinates) {
          if (list.length > 1) {
            lines.add(GCWMapPolyline(points: list));
          }
      }
    }

    String? name;
    if (jsonMap.containsKey('name')) {
      name = jsonMap['name']?.toString();
    } else if (jsonMap.containsKey('title')) {
      name = jsonMap['title']?.toString();
    } else if (jsonMap.containsKey(geoJsonLabel.properties.name)) {
      var propertiesMap = asJsonMap(jsonMap[geoJsonLabel.properties.name]);
      if (propertiesMap.containsKey('name')) {
        name = propertiesMap['name']?.toString();
      }
    }

    if (name != null) {
      for (var point in points) {
        point.markerText = name;
      }
      for (var line in lines) {
        for (var point in line.points) {
          point.markerText = name;
        }
      }
    }
    return convertToMapViewDAO(points, lines);
  }

  List<List<GCWMapPoint>> _parseCoordinates(String input) {

    List<GCWMapPoint> _parsePoints(Object? coordinates) {
      var points = asJsonArray(coordinates).map<GCWMapPoint>((point) {
        var point_ = DECCoordinate.parse(point?.toString() ?? '');
        if (point_ != null) {
          return GCWMapPoint(
              point: point_.toLatLng()!, isEditable: true);
        } else {
          return GCWMapPoint(point: LatLng(0, 0), isVisible: false);
        }
      }).toList();

      points.removeWhere((mapPoint) => !mapPoint.isVisible);
      return points;
    }

    var coordinates = <List<GCWMapPoint>>[];
    asJsonArray(input).forEach((coords) {
      coordinates.add(_parsePoints(coords));

      asJsonArray(coords).forEach((coords_) {
        coordinates.add(_parsePoints(coords_));
      });
    });

    coordinates.removeWhere((list) => list.isEmpty);
    return coordinates;
  }
}

void main() {
  var tests = <String>[
    '''{
         "type": "Point",
         "coordinates": [100.0, 0.0]
     }'''
    ,
    '''{
         "type": "LineString",
         "coordinates": [
             [100.0, 0.0],
             [101.0, 1.0]
         ]
     }'''
    ,
    '''{
         "type": "Polygon",
         "coordinates": [
             [
                 [100.0, 0.0],
                 [101.0, 0.0],
                 [101.0, 1.0],
                 [100.0, 1.0],
                 [100.0, 0.0]
             ]
         ]
     }'''
    ,
    '''{
         "type": "Polygon",
         "coordinates": [
             [
                 [100.0, 0.0],
                 [101.0, 0.0],
                 [101.0, 1.0],
                 [100.0, 1.0],
                 [100.0, 0.0]
             ],
             [
                 [100.8, 0.8],
                 [100.8, 0.2],
                 [100.2, 0.2],
                 [100.2, 0.8],
                 [100.8, 0.8]
             ]
         ]
     }'''
    ,
    '''{
       "type": "MultiPolygon",
       "coordinates": [
           [
               [
                   [180.0, 40.0], [180.0, 50.0], [170.0, 50.0],
                   [170.0, 40.0], [180.0, 40.0]
               ]
           ],
           [
               [
                   [-170.0, 40.0], [-170.0, 50.0], [-180.0, 50.0],
                   [-180.0, 40.0], [-170.0, 40.0]
               ]
           ]
       ]
   }'''
    ,
    '''{
         "type": "MultiPoint",
         "coordinates": [
             [100.0, 0.0],
             [101.0, 1.0]
         ]
     }'''
    ,
    '''{
         "type": "MultiLineString",
         "coordinates": [
             [
                 [100.0, 0.0],
                 [101.0, 1.0]
             ],
             [
                 [102.0, 2.0],
                 [103.0, 3.0]
             ]
         ]
     }'''
    ,
    '''{
       "type": "FeatureCollection",
       "features": [{
           "type": "Feature",
           "geometry": {
               "type": "Point",
               "coordinates": [102.0, 0.5]
           },
           "properties": {
               "prop0": "value0"
           }
       }, {
           "type": "Feature",
           "geometry": {
               "type": "LineString",
               "coordinates": [
                   [102.0, 0.0],
                   [103.0, 1.0],
                   [104.0, 0.0],
                   [105.0, 1.0]
               ]
           },
           "properties": {
               "prop0": "value0",
               "prop1": 0.0
           }
       }, {
           "type": "Feature",
           "geometry": {
               "type": "Polygon",
               "coordinates": [
                   [
                       [100.0, 0.0],
                       [101.0, 0.0],
                       [101.0, 1.0],
                       [100.0, 1.0],
                       [100.0, 0.0]
                   ]
               ]
           },
           "properties": {
               "prop0": "value0",
               "prop1": {
                   "this": "that"
               }
           }
       }]
   }'''

  ];
  GeoJsonReader().parse(tests.first);
}