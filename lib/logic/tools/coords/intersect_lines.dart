import 'dart:math';

import 'package:gc_wizard/logic/tools/coords/centerpoint.dart';
import 'package:gc_wizard/logic/tools/coords/data/ellipsoid.dart';
import 'package:gc_wizard/logic/tools/coords/distance_and_bearing.dart';
import 'package:gc_wizard/logic/tools/coords/projection.dart';
import 'package:gc_wizard/utils/constants.dart';
import 'package:latlong/latlong.dart';

// Using "evolutional algorithms": Take state, add some random value.
// If result is better, repeat with new value until a certain tolance value is reached.
// Because of its random factor it is not necessarily given that an intersection point is found
// although there is always such a point between to geodetics (e.g. at the back side of the sphere)

LatLng intersectBearings(LatLng coord1, double az13, LatLng coord2, double az23, Ellipsoid ells, bool crossbearing) {

  var _centerCalc = centerPointTwoPoints(coord1, coord2, ells);
  LatLng calculatedPoint = _centerCalc['centerPoint'];
  double dist = _centerCalc['distance'];

  var distBear1 = distanceBearing(coord1, calculatedPoint, ells);
  var distBear2 = distanceBearing(coord2, calculatedPoint, ells);

  var bear1, bear2;

  if (!crossbearing) {
    bear1 = distBear1.bearingAToB;
    bear2 = distBear2.bearingAToB;
  } else {
    bear1 = distBear1.bearingBToA;
    bear2 = distBear2.bearingBToA;
  }

  double d = (bear1 - az13) * (bear1 - az13) + (bear2 - az23) * (bear2 - az23);

  int c = 0;
  int br = 0;
  bool broke = false;

  while (d > epsilon) {
    if (br > 50) {      //adjusted these values empirical
      broke = true;
      break;
    }

    c++;
    if (c > 500) {
      br++;
      dist = 100;
      c = 0;
    }

    double bearing = Random().nextDouble() * 360.0;
    LatLng projectedPoint = projection(calculatedPoint, bearing, dist, ells);

    var distBear1 = distanceBearing(coord1, projectedPoint, ells);
    var distBear2 = distanceBearing(coord2, projectedPoint, ells);

    var bear1, bear2;

    if (!crossbearing) {
      bear1 = distBear1.bearingAToB;
      bear2 = distBear2.bearingAToB;
    } else {
      bear1 = distBear1.bearingBToA;
      bear2 = distBear2.bearingBToA;
    }

    double newD = (bear1 - az13) * (bear1 - az13) + (bear2 - az23) * (bear2 - az23);

    if (newD < d) {
      calculatedPoint = projectedPoint;

      dist *= 1.5;          //adjusted these values empirical
      d = newD;
    } else if (newD > d )
      dist /= 1.2;
  }

  if (broke)
    return null;

  return calculatedPoint;
}

LatLng intersectFourPoints(LatLng coord11, LatLng coord12, LatLng coord21, LatLng coord22, Ellipsoid ells) {
  var bearing1 = distanceBearing(coord11, coord12, ells).bearingAToB;
  var bearing2 = distanceBearing(coord21, coord22, ells).bearingAToB;

  return intersectBearings(coord11, bearing1, coord21, bearing2, ells, false);
}