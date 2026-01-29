//https://datatracker.ietf.org/doc/html/rfc7946

import 'dart:convert';
import 'dart:core';

import 'package:gc_wizard/tools/coords/_common/formats/dec/logic/dec.dart';
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
    try {
      if (input.isEmpty) return null;
      var jsonMap = asJsonMap(json.decode(input));

      var list = <MapViewDAO>[];
      if (jsonMap.containsKey(geoJsonLabel.type.name)) {
        if (jsonMap.containsKey(geoJsonLabel.features.name) &&
            jsonMap[geoJsonLabel.type.name] == geoJsonLabelTypes.FeatureCollection.name) {

            asJsonArray(jsonMap[geoJsonLabel.features.name]).forEach((jsonFeature) {
              var feature = _parseFeature(jsonFeature);
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
    } catch (e) {print(e.toString());}
    return null;
  }

  MapViewDAO? _parseFeature(Object? input) {
    var jsonMap = asJsonMap(input);
    if (!jsonMap.containsKey(geoJsonLabel.geometry.name)) return null;

    var geometry = _parseGeometry(jsonMap[geoJsonLabel.geometry.name]);

    return geometry;
  }

  MapViewDAO? _parseGeometry(Object? input) {
    var jsonMap = asJsonMap(input);
    if (!jsonMap.containsKey(geoJsonLabel.type.name) ||
        !jsonMap.containsKey(geoJsonLabel.coordinates.name)) {
      return null;
    }
    var coordinates =  _parseCoordinates(jsonMap[geoJsonLabel.coordinates.name]);
    if (coordinates.isEmpty) return null;

    var points = <GCWMapPoint>[];
    var lines = <GCWMapPolyline>[];

    if (jsonMap[geoJsonLabel.type.name] == geoJsonLabelTypes.Point.name) {
      if (coordinates.first.isNotEmpty) {
        points.add(coordinates.first.first);
      }
    } else if (jsonMap[geoJsonLabel.type.name] == geoJsonLabelTypes.MultiPoint.name) {
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

  List<List<GCWMapPoint>> _parseCoordinates(Object? input) {

    List<GCWMapPoint> _parsePoints(Object? coordinatesList) {
      var points = asJsonArray(coordinatesList).map<GCWMapPoint>((point) {
      var pointArray = asJsonArray(point);
        if (pointArray.length == 2) {
          var pointString = (pointArray[0]?.toString() ?? '') + ' ' + (pointArray[1]?.toString() ?? '');

          var point_ = DECCoordinate.parse(pointString);
          if (point_ != null) {
            return GCWMapPoint(point: point_.toLatLng()!, coordinateFormat: DECCoordinate().format, isEditable: true);
          }
        }
        return GCWMapPoint(point: LatLng(0, 0), isVisible: false);
      }).toList();

      points.removeWhere((mapPoint) => !mapPoint.isVisible);
      return points;
    }

    bool _isSinglePoint(List<Object?> array) {
      if (array.length == 2) {
        if (getJsonType(array[0]) == JsonType.SIMPLE_TYPE && getJsonType(array[1]) == JsonType.SIMPLE_TYPE) {
          return true;
        }
      }
      return false;
    }

    var coordinates = <List<GCWMapPoint>>[];
    var pointArray = asJsonArray(input);

    if (_isSinglePoint(pointArray)) {
      coordinates.add(_parsePoints([pointArray]));
    } else {

      //for (var coords in pointArray) {
        coordinates.add(_parsePoints(pointArray));

        // asJsonArray(coords).forEach((coords_) {
        //   coordinates.add(_parsePoints(coords_));
        // });
      //}
    }

    coordinates.removeWhere((list) => list.isEmpty);
    return coordinates;
  }
}