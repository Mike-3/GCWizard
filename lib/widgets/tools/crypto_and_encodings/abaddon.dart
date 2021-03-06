import 'package:flutter/material.dart';
import 'package:gc_wizard/i18n/app_localizations.dart';
import 'package:gc_wizard/logic/tools/crypto_and_encodings/abaddon.dart';
import 'package:gc_wizard/widgets/common/base/gcw_textfield.dart';
import 'package:gc_wizard/widgets/common/gcw_default_output.dart';
import 'package:gc_wizard/widgets/common/gcw_text_divider.dart';
import 'package:gc_wizard/widgets/common/gcw_twooptions_switch.dart';

class Abaddon extends StatefulWidget {
  @override
  AbaddonState createState() => AbaddonState();
}

class AbaddonState extends State<Abaddon> {
  var _inputController;
  var _aController;
  var _bController;
  var _cController;

  var _currentInput = '';
  var _currentA = '¥';
  var _currentB = 'µ';
  var _currentC = 'þ';

  var _currentMode = GCWSwitchPosition.left;

  @override
  void initState() {
    super.initState();

    _inputController = TextEditingController(text: _currentInput);
    _aController = TextEditingController(text: _currentA);
    _bController = TextEditingController(text: _currentB);
    _cController = TextEditingController(text: _currentC);
  }

  @override
  void dispose() {
    _inputController.dispose();
    _aController.dispose();
    _bController.dispose();
    _cController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        GCWTextField(
          controller: _inputController,
          onChanged: (text) {
            setState(() {
              _currentInput = text;
            });
          },
        ),
        GCWTextDivider(
          text: i18n(context, 'common_key')
        ),
        Row(
          children: <Widget>[
            Expanded(
              child: Container(
                child: GCWTextField(
                  controller: _aController,
                  onChanged: (text) {
                    setState(() {
                      _currentA = text;
                    });
                  },
                ),
                padding: EdgeInsets.only(
                  left: 6,
                  right: 6
                )
              ),
            ),
            Expanded(
              child: Container(
                child: GCWTextField(
                  controller: _bController,
                  onChanged: (text) {
                    setState(() {
                      _currentB = text;
                    });
                  },
                ),
                padding: EdgeInsets.only(
                  left: 6,
                  right: 6
                )
              ),
            ),
            Expanded(
              child: Container(
                child: GCWTextField(
                  controller: _cController,
                  onChanged: (text) {
                    setState(() {
                      _currentC = text;
                    });
                  },
                ),
                padding: EdgeInsets.only(
                  left: 6,
                  right: 6
                )
              ),
            ),
          ],
        ),
        GCWTwoOptionsSwitch(
          value: _currentMode,
          onChanged: (value) {
            setState(() {
              _currentMode = value;
            });
          },
        ),
        GCWDefaultOutput(
          text: _buildOutput()
        )
      ],
    );
  }

  _buildOutput() {
    if (_currentInput.length == 0
      || _currentA.length == 0
      || _currentB.length == 0
      || _currentC.length == 0)
      return '';

    var key = {YEN: _currentA, MY: _currentB, THORN: _currentC};
    return _currentMode == GCWSwitchPosition.left ? encryptAbaddon(_currentInput, key) : decryptAbaddon(_currentInput, key);
  }
}