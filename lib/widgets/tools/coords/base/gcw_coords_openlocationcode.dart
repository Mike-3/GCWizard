import 'package:flutter/material.dart';
import 'package:gc_wizard/logic/tools/coords/converter/open_location_code.dart';
import 'package:gc_wizard/widgets/common/base/gcw_textfield.dart';
import 'package:latlong/latlong.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class GCWCoordsOpenLocationCode extends StatefulWidget {
  final Function onChanged;

  const GCWCoordsOpenLocationCode({Key key, this.onChanged}) : super(key: key);

  @override
  GCWCoordsOpenLocationCodeState createState() => GCWCoordsOpenLocationCodeState();
}

class GCWCoordsOpenLocationCodeState extends State<GCWCoordsOpenLocationCode> {
  var _controller;
  var _currentCoord = '';

  var _maskInputFormatter = MaskTextInputFormatter(
    mask: '########+##########',
    filter: {"#": RegExp(r'[23456789CFGHJMPQRVWXcfghjmpqrvwx]')}
  );

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _currentCoord);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column (
      children: <Widget>[
        GCWTextField(
          controller: _controller,
          inputFormatters: [_maskInputFormatter],
          onChanged: (ret) {
            setState(() {
              _currentCoord = ret;
              _setCurrentValueAndEmitOnChange();
            });
          }
        ),
      ]
    );
  }

  _setCurrentValueAndEmitOnChange() {
    try {
      LatLng coords = openLocationCodeToLatLon(_currentCoord);
      widget.onChanged(coords);
    } catch(e) {}
  }
}