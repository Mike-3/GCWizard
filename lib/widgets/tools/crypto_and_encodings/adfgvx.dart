import 'package:flutter/material.dart';
import 'package:gc_wizard/i18n/app_localizations.dart';
import 'package:gc_wizard/logic/tools/crypto_and_encodings/adfgvx.dart';
import 'package:gc_wizard/logic/tools/crypto_and_encodings/polybios.dart';
import 'package:gc_wizard/widgets/common/base/gcw_dropdownbutton.dart';
import 'package:gc_wizard/widgets/common/base/gcw_textfield.dart';
import 'package:gc_wizard/widgets/common/gcw_default_output.dart';
import 'package:gc_wizard/widgets/common/gcw_encrypt_buttonbar.dart';
import 'package:gc_wizard/widgets/common/gcw_text_divider.dart';
import 'package:gc_wizard/widgets/common/gcw_twooptions_switch.dart';

class ADFGVX extends StatefulWidget {
  @override
  ADFGVXState createState() => ADFGVXState();
}

class ADFGVXState extends State<ADFGVX> {
  var _inputController;
  var _substitutionKeyController;
  var _transpositionKeyController;
  var _alphabetController;

  String _currentInput = '';
  String _currentSubstitutionKey = '';
  String _currentTranspositionKey = '';

  GCWSwitchPosition _currentADFGVXMode = GCWSwitchPosition.left;
  PolybiosMode _currentPolybiosMode = PolybiosMode.ZA90;
  String _currentAlphabet = '';

  var _currentOutput = '';

  @override
  void initState() {
    super.initState();
    _inputController = TextEditingController(text: _currentInput);
    _substitutionKeyController = TextEditingController(text: _currentSubstitutionKey);
    _transpositionKeyController = TextEditingController(text: _currentTranspositionKey);
    _alphabetController = TextEditingController(text: _currentAlphabet);
  }

  @override
  void dispose() {
    _inputController.dispose();
    _substitutionKeyController.dispose();
    _transpositionKeyController.dispose();
    _alphabetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var polybiosModeItems = {
      PolybiosMode.AZ09 : i18n(context, 'polybios_mode_az09'),
      PolybiosMode.ZA90 : i18n(context, 'polybios_mode_za90'),
      PolybiosMode.CUSTOM : i18n(context, 'common_custom'),
    };

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
        GCWTwoOptionsSwitch(
          leftValue: i18n(context, 'adfgvx_mode_adfgx'),
          rightValue: i18n(context, 'adfgvx_mode_adfgvx'),
          onChanged: (text) {
            setState(() {
              _currentADFGVXMode = text;
            });
          },
        ),
        GCWTextDivider(
            text: i18n(context, 'common_key')
        ),
        GCWTextField(
          hintText: i18n(context, 'adfgvx_key_substitution'),
          controller: _substitutionKeyController,
          onChanged: (text) {
            setState(() {
              _currentSubstitutionKey = text;
            });
          },
        ),
        GCWTextField(
          hintText: i18n(context, 'adfgvx_key_transposition'),
          controller: _transpositionKeyController,
          onChanged: (text) {
            setState(() {
              _currentTranspositionKey = text;
            });
          },
        ),
        GCWTextDivider(
          text: i18n(context, 'common_alphabet')
        ),
        GCWDropDownButton(
          value: _currentPolybiosMode,
          onChanged: (value) {
            setState(() {
              _currentPolybiosMode = value;
            });
          },
          items: polybiosModeItems.entries.map((mode) {
            return DropdownMenuItem(
              value: mode.key,
              child: Text(mode.value),
            );
          }).toList(),
        ),
        _currentPolybiosMode == PolybiosMode.CUSTOM ? GCWTextField(
          hintText: i18n(context, 'common_alphabet'),
          controller: _alphabetController,
          onChanged: (text) {
            setState(() {
              _currentAlphabet = text;
            });
          },
        ) : Container(),
        GCWEncryptButtonBar(
          onPressedEncode: () {
            setState(() {
              if (_currentADFGVXMode == GCWSwitchPosition.left) {
                _currentOutput = encryptADFGX(
                    _currentInput,
                    _currentSubstitutionKey,
                    _currentTranspositionKey,
                    polybiosMode: _currentPolybiosMode,
                    alphabet: _currentAlphabet
                );
              } else {
                _currentOutput = encryptADFGVX(
                    _currentInput,
                    _currentSubstitutionKey,
                    _currentTranspositionKey,
                    polybiosMode: _currentPolybiosMode,
                    alphabet: _currentAlphabet
                );
              }
            });
          },
          onPressedDecode: () {
            setState(() {
              if (_currentADFGVXMode == GCWSwitchPosition.left) {
                _currentOutput = decryptADFGX(
                    _currentInput,
                    _currentSubstitutionKey,
                    _currentTranspositionKey,
                    polybiosMode: _currentPolybiosMode,
                    alphabet: _currentAlphabet
                );
              } else {
                _currentOutput = decryptADFGVX(
                    _currentInput,
                    _currentSubstitutionKey,
                    _currentTranspositionKey,
                    polybiosMode: _currentPolybiosMode,
                    alphabet: _currentAlphabet
                );
              }
            });
          },
        ),
        GCWDefaultOutput(
          text: _currentOutput == null ? '' : _currentOutput
        )
      ],
    );
  }
}