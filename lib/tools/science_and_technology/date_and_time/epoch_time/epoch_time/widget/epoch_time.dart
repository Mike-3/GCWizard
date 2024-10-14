import 'package:flutter/material.dart';
import 'package:gc_wizard/application/i18n/logic/app_localizations.dart';
import 'package:gc_wizard/common_widgets/gcw_datetime_picker.dart';
import 'package:gc_wizard/common_widgets/outputs/gcw_columned_multiline_output.dart';
import 'package:gc_wizard/common_widgets/outputs/gcw_default_output.dart';
import 'package:gc_wizard/common_widgets/spinners/gcw_double_spinner.dart';
import 'package:gc_wizard/common_widgets/spinners/gcw_integer_spinner.dart';
import 'package:gc_wizard/common_widgets/switches/gcw_twooptions_switch.dart';
import 'package:gc_wizard/tools/science_and_technology/date_and_time/epoch_time/epoch_time/logic/epoch_time.dart';
import 'package:gc_wizard/tools/science_and_technology/date_and_time/epoch_time/excel_time/logic/excel_time.dart';
import 'package:gc_wizard/tools/science_and_technology/date_and_time/epoch_time/unix_time/logic/unix_time.dart';
import 'package:intl/intl.dart';

class EpochTime extends StatefulWidget {
  final int min;
  final int max;
  final EPOCH epochType;

  const EpochTime(
      {Key? key, required this.min, required this.max, required this.epochType})
      : super(
          key: key,
        );

  @override
  _EpochTimeState createState() => _EpochTimeState();
}

class _EpochTimeState extends State<EpochTime> {
  late dynamic _currentTimeStamp;
  var _currentDateTime = DateTime.now();
  GCWSwitchPosition _currentMode = GCWSwitchPosition.right;

  @override
  void initState() {
    super.initState();

    _currentTimeStamp = (widget.epochType == EPOCH.UNIX) ? 0 : 1.0;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        GCWTwoOptionsSwitch(
          value: _currentMode,
          onChanged: (value) {
            setState(() {
              _currentMode = value;
            });
          },
        ),
        _currentMode == GCWSwitchPosition.right
            ? (widget.epochType == EPOCH.UNIX)
                ? GCWIntegerSpinner(
                    value: _currentTimeStamp as int,
                    min: widget.min,
                    max: widget.max,
                    onChanged: (value) {
                      setState(() {
                        _currentTimeStamp = value;
                      });
                    })
                : GCWDoubleSpinner(
                    value: _currentTimeStamp as double,
                    min: widget.min.toDouble(),
                    max: widget.max.toDouble(),
//max days according to DateTime https://stackoverflow.com/questions/67144785/flutter-dart-datetime-max-min-value
                    numberDecimalDigits: 11,
                    onChanged: (value) {
                      setState(() {
                        _currentTimeStamp = value;
                      });
                    })
            : GCWDateTimePicker(
                datetime: _currentDateTime,
                config: const {
                  DateTimePickerConfig.DATE,
                  DateTimePickerConfig.TIME,
                  DateTimePickerConfig.SECOND_AS_INT,
                },
                onChanged: (datetime) {
                  setState(() {
                    _currentDateTime = datetime.datetime;
                  });
                },
              ),
        _buildOutput()
      ],
    );
  }

  Widget _buildOutput() {

    EpochTimeOutput output;
    late Object timeStamp;

    if (_currentMode == GCWSwitchPosition.left) {
      //Date to EPOCH
      switch (widget.epochType) {
        case EPOCH.UNIX:
          output = DateTimeToUnixTime(_currentDateTime);
          timeStamp = output.timeStamp.toInt();
          break;
        case EPOCH.EXCEL1900:
          output = DateTimeToExcelTime(_currentDateTime);
          timeStamp = output.timeStamp;
          break;
      }
    } else {
      //UNIX to Date
      switch (widget.epochType) {
        case EPOCH.UNIX:
          output = UnixTimeToDateTime(_currentTimeStamp as int);
          break;
        case EPOCH.EXCEL1900:
          output = ExcelTimeToDateTime(_currentTimeStamp as double);
          break;
      }
    }
    return GCWDefaultOutput(
      child: output.Error.startsWith('dates_')
          ? i18n(context, output.Error)
          : _currentMode == GCWSwitchPosition.left
              ? timeStamp
              : GCWColumnedMultilineOutput(
                  hasHeader: false,
                  flexValues: [5, 2, 4],
                  data: [
                    [
                      i18n(context, 'epoch_time_timezone_name'),
                      i18n(context, 'epoch_time_timezone_offset'),
                      i18n(context, 'epoch_time_timezone_date_time'),
                    ],
                    [
                      output.UTC.timeZoneName,
                      output.UTC.timeZoneOffset.inHours,
                      _formatDate(context, output.UTC),
                    ],
                    [
                      output.local.timeZoneName,
                      output.local.timeZoneOffset.inHours,
                      _formatDate(context, output.local),
                    ]
                  ],
                ),
    );
  }

  String _formatDate(BuildContext context, DateTime datetime,
      {bool excelBug = false}) {
    String loc = Localizations.localeOf(context).toString();
    String formatDate =
        DateFormat.yMd(loc).add_jms().format(datetime).toString();
    if (excelBug) {
      switch (loc) {
        case 'sv':
          formatDate = formatDate.replaceAll('-03-01', '-02-29');
          break;
        case 'sk':
        case 'cz':
          formatDate = formatDate.replaceAll('1. 3. ', '29. 2. ');
          break;
        case 'ru':
        case 'tr':
          formatDate = formatDate.replaceAll('01.03.', '29.02.');
          break;
        case 'pt':
          formatDate = formatDate.replaceAll('01/03/', '29/02/');
          break;
        case 'ko':
          formatDate = formatDate.replaceAll(' 3. 1.', ' 2. 29.');
          break;
        case 'nl':
          formatDate = formatDate.replaceAll('1-3-', '29-2-');
          break;
        case 'de':
        case 'da':
        case 'fi':
        case 'pl':
          formatDate = formatDate.replaceAll('1.3.', '29.2.');
          break;
        case 'en':
          formatDate = formatDate.replaceAll('3/1/', '2/29/');
          break;
        case 'es':
        case 'fr':
        case 'el':
        case 'it':
          formatDate = formatDate.replaceAll('1/3/', '29/2/');
          break;
        default:
          formatDate = formatDate.replaceAll('3/1/', '2/29/');
      }
    }
    return formatDate;
  }
}
