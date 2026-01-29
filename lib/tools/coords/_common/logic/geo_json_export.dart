import 'dart:convert';

import 'package:gc_wizard/tools/coords/_common/logic/geo_json_import.dart';
import 'package:gc_wizard/tools/coords/map_view/logic/map_geometries.dart';
import 'package:gc_wizard/utils/coordinate_utils.dart';

/// Convert points into geoJson
class geoJsonWriter {
  String toJson( List<GCWMapPoint> points, List<GCWMapPolyline> polylines) {
    return _toJsonFeatureCollection(points, polylines);
  }

  String _toJsonFeatureCollection( List<GCWMapPoint> points, List<GCWMapPolyline> polylines) {
    var list = <Map<String, Object>>[];
    list.add({geoJsonLabel.type.name: geoJsonLabelTypes.FeatureCollection.name});
    list.add({geoJsonLabel.features.name: _toJsonFeatureList(points, polylines)});
    return jsonEncode(list);
  }

  List<Map<String, Object>> _toJsonFeatureList(List<GCWMapPoint> points, List<GCWMapPolyline> polylines) {
    var list = <Map<String, Object>>[];

    for (var point in points) {
      list.add(_fillFeatureMap({geoJsonLabel.geometry.name: _toJsonPointGeometry(point)}, point.markerText));
    }
    for (var polyline in polylines) {
      list.add(_fillFeatureMap({geoJsonLabel.geometry.name: _toJsonPolylineGeometry(polyline)}, null));
    }
    return list;
  }

  Map<String, Object> _fillFeatureMap(Map<String, Object> featureMap, String? label) {
    var _featureMap = <String, Object>{};
    _featureMap.addAll({geoJsonLabel.type.name: geoJsonLabelTypes.Feature.name});
    _featureMap.addAll(featureMap);
    if (label != null && label.isNotEmpty) {
      _featureMap.addAll({geoJsonLabel.properties.name: {'name': label}});
    }
    return _featureMap;
  }

  Map<String, Object> _toJsonPointGeometry(GCWMapPoint point) {
    var list = <String, Object>{};
    list.addAll({geoJsonLabel.type.name: geoJsonLabelTypes.Point.name});
    list.addAll({geoJsonLabel.coordinates.name: _toJsonPoint(point)});
    return list;
  }

  Map<String, Object> _toJsonPolylineGeometry(GCWMapPolyline line) {
    var list = <String, Object>{};
    if (line.points.length == 1) {
      return _toJsonPointGeometry(line.points.first);
    } else if (line.points.length == 2) {
      list.addAll({geoJsonLabel.type.name: geoJsonLabelTypes.LineString.name});
    } else if (line.points.length > 2) {
      if (equalsLatLng(line.points.first.point, line.points.last.point)) {
        list.addAll({geoJsonLabel.type.name: geoJsonLabelTypes.Polygon.name});
      } else {
        list.addAll({geoJsonLabel.type.name: geoJsonLabelTypes.LineString.name});
      }
    }
    list.addAll({geoJsonLabel.coordinates.name: _toJsonPoints(line.points)});
    return list;
  }

  List<List<double>> _toJsonPoints(List<GCWMapPoint> points) {
    return points.map((point) {
      return _toJsonPoint(point);
    }).toList();
  }

  List<double> _toJsonPoint(GCWMapPoint point) {
    return ([point.point.latitude, point.point.longitude]);
  }
}


