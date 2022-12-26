import 'package:flutter/material.dart';
import 'package:gc_wizard/i18n/app_localizations.dart';
import 'package:gc_wizard/tools/coords/data/logic/coordinates.dart';
import 'package:gc_wizard/tools/science_and_technology/astronomy/logic/julian_date.dart';
import 'package:gc_wizard/tools/science_and_technology/astronomy/moon_rise_set/logic/moon_rise_set.dart' as logic;
import 'package:gc_wizard/utils/common_utils.dart';
import 'package:gc_wizard/tools/common/gcw_columned_multiline_output/widget/gcw_columned_multiline_output.dart';
import 'package:gc_wizard/tools/common/gcw_datetime_picker/widget/gcw_datetime_picker.dart';
import 'package:gc_wizard/tools/common/gcw_text_divider/widget/gcw_text_divider.dart';
import 'package:gc_wizard/tools/coords/base/gcw_coords/widget/gcw_coords.dart';
import 'package:gc_wizard/tools/coords/base/utils/widget/utils.dart';

class MoonRiseSet extends StatefulWidget {
  @override
  MoonRiseSetState createState() => MoonRiseSetState();
}

class MoonRiseSetState extends State<MoonRiseSet> {
  var _currentDateTime = {'datetime': DateTime.now(), 'timezone': DateTime.now().timeZoneOffset};
  var _currentCoords = defaultCoordinate;
  var _currentCoordsFormat = defaultCoordFormat();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        GCWCoords(
          title: i18n(context, 'common_location'),
          coordsFormat: _currentCoordsFormat,
          onChanged: (ret) {
            setState(() {
              _currentCoordsFormat = ret['coordsFormat'];
              _currentCoords = ret['value'];
            });
          },
        ),
        GCWTextDivider(
          text: i18n(context, 'astronomy_riseset_date'),
        ),
        GCWDateTimePicker(
          config: {DateTimePickerConfig.DATE, DateTimePickerConfig.TIMEZONES},
          onChanged: (datetime) {
            setState(() {
              _currentDateTime = datetime;
            });
          },
        ),
        _buildOutput()
      ],
    );
  }

  Widget _buildOutput() {
    var moonRise = logic.MoonRiseSet(
        _currentCoords,
        JulianDate(_currentDateTime['datetime'], _currentDateTime['timezone']),
        _currentDateTime['timezone'],
        defaultEllipsoid());

    var outputs = [
      [
        i18n(context, 'astronomy_riseset_moonrise'),
        moonRise.rise.isNaN ? i18n(context, 'astronomy_riseset_notavailable') : formatHoursToHHmmss(moonRise.rise)
      ],
      [
        i18n(context, 'astronomy_riseset_transit'),
        moonRise.transit.isNaN ? i18n(context, 'astronomy_riseset_notavailable') : formatHoursToHHmmss(moonRise.transit)
      ],
      [
        i18n(context, 'astronomy_riseset_moonset'),
        moonRise.set.isNaN ? i18n(context, 'astronomy_riseset_notavailable') : formatHoursToHHmmss(moonRise.set)
      ],
    ];

    return GCWColumnedMultilineOutput(
        firstRows: [GCWTextDivider(text: i18n(context, 'common_output'))],
        data: outputs
    );
  }
}