//https://datatracker.ietf.org/doc/html/rfc7946

import 'dart:core';

import 'package:gc_wizard/tools/coords/_common/formats/dec/logic/dec.dart';
import 'package:gc_wizard/tools/coords/_common/logic/coordinates.dart';
import 'package:gc_wizard/tools/coords/map_view/logic/map_geometries.dart';

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
  List<GCWMapPoint> _parseCoordinates(String coordinates) {
    var points = <GCWMapPoint>[];
    var regex = RegExp(r'\[(.*)\]');
    regex.allMatches(coordinates).forEach((match) {
      var point = DECCoordinate.parse(match.group(0));
if (point))
    }

    matches.foE
    regExp.pa
    return points;
  }

}