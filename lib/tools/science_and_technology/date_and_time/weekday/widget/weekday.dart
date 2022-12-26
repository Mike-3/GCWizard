import 'package:flutter/material.dart';
import 'package:gc_wizard/i18n/app_localizations.dart';
import 'package:gc_wizard/tools/common/date_utils/logic/date_utils.dart';
import 'package:gc_wizard/tools/common/gcw_datetime_picker/widget/gcw_datetime_picker.dart';
import 'package:gc_wizard/tools/common/gcw_default_output/widget/gcw_default_output.dart';
import 'package:gc_wizard/tools/common/gcw_text_divider/widget/gcw_text_divider.dart';

class Weekday extends StatefulWidget {
  @override
  WeekdayState createState() => WeekdayState();
}

class WeekdayState extends State<Weekday> {
  DateTime _currentDate;

  @override
  void initState() {
    DateTime now = DateTime.now();
    _currentDate = DateTime(now.year, now.month, now.day);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        GCWTextDivider(text: i18n(context, 'dates_weekday_date')),
        GCWDateTimePicker(
          config: {DateTimePickerConfig.DATE},
          datetime: _currentDate,
          onChanged: (value) {
            setState(() {
              _currentDate = value['datetime'];
            });
          },
        ),
        _buildOutput(context)
      ],
    );
  }

  Widget _buildOutput(BuildContext context) {
    var weekday = _currentDate.weekday;
    var output = i18n(context, WEEKDAY[weekday]);

    return GCWDefaultOutput(child: output);
  }
}