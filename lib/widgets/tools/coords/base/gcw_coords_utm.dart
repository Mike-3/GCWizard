import 'package:flutter/material.dart';
import 'package:gc_wizard/i18n/app_localizations.dart';
import 'package:gc_wizard/logic/tools/coords/converter/utm.dart';
import 'package:gc_wizard/logic/tools/coords/data/coordinates.dart';
import 'package:gc_wizard/theme/theme.dart';
import 'package:gc_wizard/widgets/common/gcw_double_textfield.dart';
import 'package:gc_wizard/widgets/common/gcw_integer_textfield.dart';
import 'package:gc_wizard/widgets/tools/coords/base/gcw_coords_sign_dropdownbutton.dart';
import 'package:gc_wizard/widgets/tools/coords/base/utils.dart';
import 'package:gc_wizard/widgets/utils/textinputformatter/coords_integer_utm_lonzone_textinputformatter.dart';
import 'package:latlong/latlong.dart';

class GCWCoordsUTM extends StatefulWidget {
  final Function onChanged;

  const GCWCoordsUTM({Key key, this.onChanged}) : super(key: key);

  @override
  GCWCoordsUTMState createState() => GCWCoordsUTMState();
}

class GCWCoordsUTMState extends State<GCWCoordsUTM> {
  var _LonZoneController;
  var _EastingController;
  var _NorthingController;

  var _currentHemisphere = defaultHemiphereLatitude();

  var _currentLonZone = {'text': '', 'value': 0};
  var _currentEasting = {'text': '', 'value': 0.0};
  var _currentNorthing = {'text': '', 'value': 0.0};

  @override
  void initState() {
    super.initState();
    _LonZoneController = TextEditingController(text: _currentLonZone['text']);

    _EastingController = TextEditingController(text: _currentEasting['text']);
    _NorthingController = TextEditingController(text: _currentNorthing['text']);
  }

  @override
  void dispose() {
    _LonZoneController.dispose();
    _EastingController.dispose();
    _NorthingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column (
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: GCWIntegerTextField(
                  hintText: i18n(context, 'coords_formatconverter_utm_lonzone'),
                  textInputFormatter: CoordsIntegerUTMLonZoneTextInputFormatter(),
                  controller: _LonZoneController,
                  onChanged: (ret) {
                    setState(() {
                      _currentLonZone = ret;
                      _setCurrentValueAndEmitOnChange();
                    });
                  }
                ),
              ),
              Expanded(
                child: Container(
                  child: GCWCoordsSignDropDownButton(
                    itemList: ['N','S'],
                    value: _currentHemisphere,
                    onChanged: (value) {
                      setState(() {
                        _currentHemisphere = value;
                        _setCurrentValueAndEmitOnChange();
                      });
                    }
                  ),
                  padding: EdgeInsets.only(left: 2 * DEFAULT_MARGIN),
                )
              ),
            ],
          ),
          GCWDoubleTextField(
            hintText: i18n(context, 'coords_formatconverter_utm_easting'),
            min: 0.0,
            controller: _EastingController,
            onChanged: (ret) {
              setState(() {
                _currentEasting = ret;
                _setCurrentValueAndEmitOnChange();
              });
            }
          ),
          GCWDoubleTextField(
              hintText: i18n(context, 'coords_formatconverter_utm_northing'),
              min: 0.0,
              controller: _NorthingController,
              onChanged: (ret) {
                setState(() {
                  _currentNorthing = ret;
                  _setCurrentValueAndEmitOnChange();
                });
              }
          ),
        ]
    );
  }

  _setCurrentValueAndEmitOnChange() {
    var _lonZone = _currentLonZone['value'];

    var zone = UTMZone(_lonZone, _lonZone, _currentHemisphere > 0 ? 'N' : 'M');
    var utm = UTMREF(zone, _currentEasting['value'], _currentNorthing['value']);

    LatLng coords = UTMREFtoLatLon(utm, defaultEllipsoid());
    widget.onChanged(coords);
  }
}