import 'package:flutter/material.dart';
import 'package:gc_wizard/application/theme/theme.dart';
import 'package:gc_wizard/common_widgets/spinners/gcw_integer_spinner.dart';
import 'package:gc_wizard/common_widgets/spinners/spinner_constants.dart';
import 'package:gc_wizard/common_widgets/switches/gcw_twooptions_switch.dart';
import 'package:gc_wizard/common_widgets/text_input_formatters/gcw_only01anddot_textinputformatter.dart';
import 'package:gc_wizard/common_widgets/textfields/gcw_textfield.dart';
import 'package:gc_wizard/tools/science_and_technology/ip_address/logic/ip_address.dart';

class GCWIPAddress extends StatefulWidget {
  final void Function(IP) onChanged;
  final IP? value;
  const GCWIPAddress({super.key, required this.value, required this.onChanged});

  @override
  _GCWIPAddressState createState() => _GCWIPAddressState();
}

class _GCWIPAddressState extends State<GCWIPAddress> {
  List<int> _currentSpinnerValue = [];
  IP _currentValue = IP([0,0,0,0]);

  var _currentBinInputIP = '';
  late TextEditingController _binInputController;
  var _currentInputIPMode = GCWSwitchPosition.left;

  @override
  void initState() {
    super.initState();
    _binInputController = TextEditingController(text: _currentBinInputIP);
  }

  @override
  void dispose() {
    _binInputController.dispose();
    super.dispose();
  }

  void _setValue() {
    _currentValue = _currentInputIPMode == GCWSwitchPosition.left
        ? IP(_currentSpinnerValue)
        : IP.fromBinaryString(_currentBinInputIP);
  }

  @override
  Widget build(BuildContext context) {
    if (_currentSpinnerValue.isEmpty) {
      _currentSpinnerValue = widget.value == null ? [0,0,0,0] : widget.value!.ipBlocks;
      _setValue();
    }

    var children = <Widget>[
      GCWTwoOptionsSwitch(
        leftValue: 'Decimal',
        rightValue: 'Binary',
        value: _currentInputIPMode,
        onChanged: (value) {
          setState(() {
            _currentInputIPMode = value;
            _setValue();
            widget.onChanged(_currentValue);
          });
        }
      ),
    ];

    if (_currentInputIPMode == GCWSwitchPosition.left) {
      List<Widget> spinners = [];
      for (int i = 0; i <= 3; i++) {
        spinners.add(
            Expanded(
              child: GCWIntegerSpinner(
                value: _currentSpinnerValue[i],
                min: 0,
                max: 255,
                layout: SpinnerLayout.VERTICAL,
                onChanged: (int value) {
                  _currentSpinnerValue[i] = value;
                  _setValue();
                  widget.onChanged(_currentValue);
                }
              )
            )
        );
        if (i < 3) {
          spinners.add(Container(width: DOUBLE_DEFAULT_MARGIN));
        }
      }
      children.add(Row(children:spinners));
    } else {
      children.add (
        GCWTextField(
          controller: _binInputController,
          inputFormatters: [GCWOnly01AndDotInputFormatter()],
          onChanged: (text) {
            setState(() {
              _currentBinInputIP = text;
              _setValue();
              widget.onChanged(_currentValue);
            });
          },
        )
      );
    }

    return Column(
      children: children,
    );
  }
}
