import 'package:flutter/material.dart';
import 'package:gc_wizard/i18n/app_localizations.dart';
import 'package:gc_wizard/logic/tools/coords/converter/natural_area_code.dart';
import 'package:gc_wizard/logic/tools/coords/data/coordinates.dart';
import 'package:gc_wizard/widgets/common/base/gcw_textfield.dart';
import 'package:gc_wizard/widgets/utils/textinputformatter/coords_text_naturalareacode_textinputformatter.dart';
import 'package:latlong/latlong.dart';

class GCWCoordsNaturalAreaCode extends StatefulWidget {
  final Function onChanged;

  const GCWCoordsNaturalAreaCode({Key key, this.onChanged}) : super(key: key);

  @override
  GCWCoordsNaturalAreaCodeState createState() => GCWCoordsNaturalAreaCodeState();
}

class GCWCoordsNaturalAreaCodeState extends State<GCWCoordsNaturalAreaCode> {
  var _controllerX;
  var _controllerY;
  var _currentX = '';
  var _currentY = '';

  @override
  void initState() {
    super.initState();

    _controllerX = TextEditingController(text: _currentX);
    _controllerY = TextEditingController(text: _currentY);
  }

  @override
  void dispose() {
    _controllerX.dispose();
    _controllerY.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column (
        children: <Widget>[
          GCWTextField(
            hintText: i18n(context, 'coords_formatconverter_naturalareacode_x'),
            controller: _controllerX,
            inputFormatters: [CoordsTextNaturalAreaCodeTextInputFormatter()],
            onChanged: (ret) {
              setState(() {
                _currentX = ret;
                _setCurrentValueAndEmitOnChange();
              });
            }
          ),
          GCWTextField(
            hintText: i18n(context, 'coords_formatconverter_naturalareacode_y'),
            controller: _controllerY,
            inputFormatters: [CoordsTextNaturalAreaCodeTextInputFormatter()],
            onChanged: (ret) {
              setState(() {
                _currentY = ret;
                _setCurrentValueAndEmitOnChange();
              });
            }
          ),
        ]
    );
  }

  _setCurrentValueAndEmitOnChange() {
    LatLng coords = naturalAreaCodeToLatLon(NaturalAreaCode(_currentX, _currentY));
    widget.onChanged(coords);
  }
}