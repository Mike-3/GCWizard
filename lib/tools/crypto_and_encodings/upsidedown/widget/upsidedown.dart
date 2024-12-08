import 'package:flutter/material.dart';
import 'package:gc_wizard/application/i18n/logic/app_localizations.dart';
import 'package:gc_wizard/common_widgets/buttons/gcw_radiobuttonset.dart';
import 'package:gc_wizard/tools/crypto_and_encodings/upsidedown/logic/upsidedown.dart';

import 'package:gc_wizard/common_widgets/outputs/gcw_default_output.dart';
import 'package:gc_wizard/common_widgets/switches/gcw_twooptions_switch.dart';
import 'package:gc_wizard/common_widgets/textfields/gcw_textfield.dart';

class UpsideDown extends StatefulWidget {
  const UpsideDown({Key? key}) : super(key: key);

  @override
  UpsideDownState createState() => UpsideDownState();
}

class UpsideDownState extends State<UpsideDown> {
  late TextEditingController _inputControllerDecode;
  late TextEditingController _inputControllerEncode;

  String _currentInputEncode = '';
  String _currentInputDecode = '';
  GCWSwitchPosition _currentMode = GCWSwitchPosition.right;

  int _currentActiveButton = 0;

  @override
  void initState() {
    super.initState();
    _inputControllerDecode = TextEditingController(text: _currentInputDecode);
    _inputControllerEncode = TextEditingController(text: _currentInputEncode);
  }

  @override
  void dispose() {
    _inputControllerDecode.dispose();
    _inputControllerEncode.dispose();

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
        GCWRadioButtonSet(
            title: i18n(context, 'upsidedown_flip_mode'),
            activeButton: _currentActiveButton,
            buttons: ['upsidedown_flip_mode_h', 'upsidedown_flip_mode_v', 'upsidedown_flip_mode_hv'],
            onChanged: (value) {
              setState(() {
                _currentActiveButton = value;
              });
            },
        ),
        _currentMode == GCWSwitchPosition.right
            ? GCWTextField(
                controller: _inputControllerDecode,
                onChanged: (text) {
                  setState(() {
                    _currentInputDecode = text;
                  });
                })
            : GCWTextField(
                controller: _inputControllerEncode,
                onChanged: (text) {
                  setState(() {
                    _currentInputEncode = text;
                  });
                }),
        _buildOutput(),
      ],
    );
  }

  Widget _buildOutput() {
    String result = '';
    print(_currentActiveButton);
    if (_currentMode == GCWSwitchPosition.right) {
      // decode
      result = decodeUpsideDownText(_currentInputDecode, _currentActiveButton);
    } else {
      // encode
      result = encodeUpsideDownText(_currentInputEncode, _currentActiveButton);
    }
    return GCWDefaultOutput(
      child: result,
    );
  }
}
