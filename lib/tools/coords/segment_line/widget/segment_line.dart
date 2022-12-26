import 'package:flutter/material.dart';
import 'package:gc_wizard/i18n/app_localizations.dart';
import 'package:gc_wizard/tools/common/units/logic/length.dart';
import 'package:gc_wizard/tools/common/units/logic/unit.dart';
import 'package:gc_wizard/tools/common/units/logic/unit_category.dart';
import 'package:gc_wizard/tools/coords/data/logic/coordinates.dart';
import 'package:gc_wizard/tools/coords/segment_line/logic/segment_line.dart';
import 'package:gc_wizard/tools/coords/logic/utils.dart';
import 'package:gc_wizard/theme/fixed_colors.dart';
import 'package:gc_wizard/utils/constants.dart';
import 'package:gc_wizard/utils/settings/preferences.dart';
import 'package:gc_wizard/tools/common/gcw_default_output/widget/gcw_default_output.dart';
import 'package:gc_wizard/tools/common/gcw_integer_spinner/widget/gcw_integer_spinner.dart';
import 'package:gc_wizard/tools/common/gcw_submit_button/widget/gcw_submit_button.dart';
import 'package:gc_wizard/tools/common/gcw_text_divider/widget/gcw_text_divider.dart';
import 'package:gc_wizard/tools/common/units/gcw_unit_dropdownbutton/widget/gcw_unit_dropdownbutton.dart';
import 'package:gc_wizard/tools/coords/base/gcw_coords/widget/gcw_coords.dart';
import 'package:gc_wizard/tools/coords/base/gcw_coords_output/widget/gcw_coords_output.dart';
import 'package:gc_wizard/tools/coords/base/gcw_coords_outputformat/widget/gcw_coords_outputformat.dart';
import 'package:gc_wizard/tools/coords/base/utils/widget/utils.dart';
import 'package:gc_wizard/tools/coords/map_view/gcw_map_geometries/widget/gcw_map_geometries.dart';
import 'package:prefs/prefs.dart';

class SegmentLine extends StatefulWidget {
  @override
  SegmentLineState createState() => SegmentLineState();
}

class SegmentLineState extends State<SegmentLine> {
  var _currentCoords1 = defaultCoordinate;
  var _currentCoords2 = defaultCoordinate;

  var _currentCoordsFormat1 = defaultCoordFormat();
  var _currentCoordsFormat2 = defaultCoordFormat();

  var _currentSegmentCount = 2;

  var _currentMapPoints = <GCWMapPoint>[];
  var _currentMapPolylines = <GCWMapPolyline>[];

  Length _currentOutputUnit = UNITCATEGORY_LENGTH.defaultUnit;
  var _currentOutputFormat = defaultCoordFormat();

  List<String> _currentOutputs = [];
  Widget _currentDistanceOutput = Container();

  @override
  void initState() {
    super.initState();

    _currentOutputUnit = getUnitBySymbol(allLengths(), Prefs.get(PREFERENCE_DEFAULT_LENGTH_UNIT));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        GCWCoords(
          title: i18n(context, 'coords_segmentline_start'),
          coordsFormat: _currentCoordsFormat1,
          onChanged: (ret) {
            setState(() {
              _currentCoordsFormat1 = ret['coordsFormat'];
              _currentCoords1 = ret['value'];
            });
          },
        ),
        GCWCoords(
          title: i18n(context, 'coords_segmentline_end'),
          coordsFormat: _currentCoordsFormat2,
          onChanged: (ret) {
            setState(() {
              _currentCoordsFormat2 = ret['coordsFormat'];
              _currentCoords2 = ret['value'];
            });
          },
        ),
        GCWTextDivider(text: i18n(context, 'coords_segmentline_numbersegments')),
        GCWIntegerSpinner(
          value: _currentSegmentCount,
          min: 2,
          overflow: SpinnerOverflowType.SUPPRESS_OVERFLOW,
          onChanged: (value) {
            setState(() {
              _currentSegmentCount = value;
            });
          },
        ),
        GCWCoordsOutputFormat(
          coordFormat: _currentOutputFormat,
          onChanged: (value) {
            setState(() {
              _currentOutputFormat = value;
            });
          },
        ),
        GCWUnitDropDownButton(
            unitList: allLengths(),
            value: _currentOutputUnit,
            onlyShowSymbols: false,
            onChanged: (Length value) {
              setState(() {
                _currentOutputUnit = value;
              });
            }),
        GCWSubmitButton(
          onPressed: () {
            setState(() {
              _calculateOutput();
            });
          },
        ),
        _currentDistanceOutput,
        GCWCoordsOutput(
          outputs: _currentOutputs,
          points: _currentMapPoints,
          polylines: _currentMapPolylines,
        ),
      ],
    );
  }

  _calculateOutput() {
    var segments = segmentLine(_currentCoords1, _currentCoords2, _currentSegmentCount, defaultEllipsoid());

    var startMapPoint = GCWMapPoint(
        point: _currentCoords1,
        markerText: i18n(context, 'coords_segmentline_start'),
        coordinateFormat: _currentCoordsFormat1);
    var endMapPoint = GCWMapPoint(
        point: _currentCoords2,
        markerText: i18n(context, 'coords_segmentline_end'),
        coordinateFormat: _currentCoordsFormat2);

    _currentMapPoints = [startMapPoint];
    segments['points'].asMap().forEach((index, point) {
      _currentMapPoints.add(GCWMapPoint(
        point: point,
        markerText: i18n(context, 'coords_segmentline_segmentdivider') + ' ' + (index + 1).toString(),
        coordinateFormat: _currentOutputFormat,
        color: COLOR_MAP_CALCULATEDPOINT,
      ));
    });
    _currentMapPoints.add(endMapPoint);

    _currentMapPolylines = [GCWMapPolyline(points: List<GCWMapPoint>.from(_currentMapPoints))];

    _currentOutputs = List<String>.from(segments['points'].map((point) {
      return formatCoordOutput(point, _currentOutputFormat, defaultEllipsoid());
    }).toList());

    var distanceOutput = doubleFormat.format(_currentOutputUnit.fromMeter(segments['segmentDistance']));
    _currentDistanceOutput = GCWDefaultOutput(
      child:
          i18n(context, 'coords_segmentline_segmentdistance') + ': ' + distanceOutput + ' ' + _currentOutputUnit.symbol,
      copyText: distanceOutput,
    );
  }
}