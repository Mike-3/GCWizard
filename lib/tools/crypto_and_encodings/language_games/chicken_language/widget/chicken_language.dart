import 'package:flutter/material.dart';
import 'package:gc_wizard/tools/crypto_and_encodings/language_games/chicken_language/logic/chicken_language.dart';
import 'package:gc_wizard/tools/common/base/gcw_textfield/widget/gcw_textfield.dart';
import 'package:gc_wizard/tools/common/gcw_default_output/widget/gcw_default_output.dart';
import 'package:gc_wizard/tools/common/gcw_twooptions_switch/widget/gcw_twooptions_switch.dart';

class ChickenLanguage extends StatefulWidget {
  @override
  ChickenLanguageState createState() => ChickenLanguageState();
}

class ChickenLanguageState extends State<ChickenLanguage> {
  var _currentInput = '';
  var _currentMode = GCWSwitchPosition.right;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        GCWTextField(onChanged: (text) {
          setState(() {
            _currentInput = text;
          });
        }),
        GCWTwoOptionsSwitch(
          value: _currentMode,
          onChanged: (value) {
            setState(() {
              _currentMode = value;
            });
          },
        ),
        GCWDefaultOutput(child: _buildOutput())
      ],
    );
  }

  _buildOutput() {
    if (_currentInput == null) return '';

    var out = _currentMode == GCWSwitchPosition.left
        ? encryptChickenLanguage(_currentInput)
        : decryptChickenLanguage(_currentInput);

    return out;
  }
}