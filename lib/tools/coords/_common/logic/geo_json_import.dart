//https://datatracker.ietf.org/doc/html/rfc7946

import 'dart:core';

import 'package:gc_wizard/tools/coords/_common/formats/dec/logic/dec.dart';
import 'package:gc_wizard/tools/coords/_common/logic/coordinates.dart';
import 'package:gc_wizard/tools/coords/map_view/logic/map_geometries.dart';
import 'package:gc_wizard/utils/json_utils.dart';
import 'package:latlong2/latlong.dart';

enum geoJsonLabel {
  type,
  coordinates,
  features,
  geometry,
  geometries,
}

enum geoJsonLabelTypes {
  Point,
  LineString,
  Polygon,
  MultiPoint,
  MultiLineString,
  MultiPolygon,
  FeatureCollection,
  GeometryCollection,
}
class _GeoJsonReader {


  // List<List<GCWMapPoint>> _parseCoordinates(String coordinates) {
  //   var points = <GCWMapPoint>[];
  //   var regex = RegExp(r'\[(.*)\]', multiLine: true);
  //   var regex1 = RegExp(regex.pattern, multiLine: regex.isMultiLine);
  //
  //   regex.allMatches(coordinates).forEach((match) {
  //     var matches1 = regex1.allMatches(match.group(0) ?? '');
  //
  //     var point = DECCoordinate.parse(match.group(0) ?? '');
  //     if (point != null) {
  //       points.add(GCWMapPoint(
  //           point: point.toLatLng()!, isEditable: true));
  //     }
  //   });
  //   return points;
  // }

  List<List<GCWMapPoint>> _parseCoordinates(String input) {
    final decoded = asJsonArray(input);

    return decoded.map<List<GCWMapPoint>>((polygon) {
      return asJsonArray(polygon).map<GCWMapPoint>((point) {
        var point_ = DECCoordinate.parse(point?.toString() ?? '');
        if (point_ != null) {
          return GCWMapPoint(
              point: point_.toLatLng()!, isEditable: true);
        }
        // final p = point as List;
        // return '${p[0]},${p[1]}'; // oder '${p[0]} ${p[1]}'
      }).toList();
    }).toList();
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
}