import 'package:flutter/material.dart';
import 'package:gc_wizard/common_widgets/textfields/gcw_textfield.dart';
import 'package:gc_wizard/common_widgets/outputs/gcw_default_output.dart';

class RotN extends StatefulWidget {
  final Function rotate;

  RotN({Key key, this.rotate}) : super(key: key);

  @override
  RotNState createState() => RotNState();
}

class RotNState extends State<RotN> {
  String _output = '';

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        GCWTextField(
          onChanged: (text) {
            setState(() {
              _output = widget.rotate(text);
            });
          },
        ),
        GCWDefaultOutput(child: _output)
      ],
    );
  }
}