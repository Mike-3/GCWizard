import 'package:gc_wizard/tools/coords/external_libs/net.sf/logic/geodesic.dart';
import 'package:gc_wizard/tools/coords/external_libs/net.sf/logic/geodesic_data.dart';
import 'package:gc_wizard/tools/coords/intervals/logic/coordinate_cell.dart';
import 'package:gc_wizard/tools/coords/intervals/logic/interval_calculator.dart';
import 'package:gc_wizard/tools/coords/logic/ellipsoid.dart';
import 'package:gc_wizard/tools/coords/utils/format_getter.dart' as formatGetter;
import 'package:gc_wizard/tools/coords/waypoint_projection/logic/vincenty/projection_vincenty.dart';
import 'package:latlong2/latlong.dart';

LatLng projection(LatLng coord, double bearingDeg, double distance, Ellipsoid ellipsoid) {
  if (distance == 0.0) return coord;

  bearingDeg = formatGetter.normalizeBearing(bearingDeg);

  GeodesicData projected =
      Geodesic(ellipsoid.a, ellipsoid.f).direct(coord.latitude, coord.longitude, bearingDeg, distance);

  return LatLng(projected.lat2, projected.lon2);
}

LatLng projectionRadian(LatLng coord, double bearingRad, double distance, Ellipsoid ellipsoid) {
  return projection(coord, radianToDeg(bearingRad), distance, ellipsoid);
}

/// A bit less accurate... Used for Map Polylines
LatLng projectionVincenty(LatLng coord, double bearing, double distance, Ellipsoid ellipsoid) {
  if (distance == 0.0) return coord;

  bearing = formatGetter.normalizeBearing(bearing);

  return vincentyDirect(coord, degToRadian(bearing), distance, ellipsoid);
}

class _ReverseProjectionCalculator extends IntervalCalculator {
  _ReverseProjectionCalculator(Map<String, dynamic> parameters, Ellipsoid ells) : super(parameters, ells) {
    eps = 1e-10;
  }

  @override
  bool checkCell(CoordinateCell cell, Map<String, dynamic> parameters) {
    Interval distanceToCoord = cell.distanceTo(parameters['coord']);
    Interval bearingToCoord = cell.bearingTo(parameters['coord']);

    var distance = parameters['distance'];
    var bearing = parameters['bearing'];

    if ((distanceToCoord.a <= distance) &&
        (distance <= distanceToCoord.b) &&
        ((bearingToCoord.a <= bearing) && (bearing <= bearingToCoord.b) ||
            (bearingToCoord.a <= bearing + 360.0) && (bearing + 360.0 <= bearingToCoord.b))) {}

    return (distanceToCoord.a <= distance) &&
        (distance <= distanceToCoord.b) &&
        ((bearingToCoord.a <= bearing) && (bearing <= bearingToCoord.b) ||
            (bearingToCoord.a <= bearing + 360.0) && (bearing + 360.0 <= bearingToCoord.b));
  }
}

List<LatLng> reverseProjection(LatLng coord, double bearing, double distance, Ellipsoid ellipsoid) {
  bearing = formatGetter.normalizeBearing(bearing);

  return _ReverseProjectionCalculator({'coord': coord, 'bearing': bearing, 'distance': distance}, ellipsoid).check();
}