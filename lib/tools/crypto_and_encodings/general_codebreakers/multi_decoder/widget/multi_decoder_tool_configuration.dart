part of 'package:gc_wizard/tools/crypto_and_encodings/general_codebreakers/multi_decoder/widget/multi_decoder.dart';

class MultiDecoderToolConfiguration extends StatefulWidget {
  final Map<String, Widget> widgets;
  const MultiDecoderToolConfiguration({Key? key, this.widgets}) : super(key: key);

  @override
  MultiDecoderToolConfigurationState createState() => MultiDecoderToolConfigurationState();
}

class MultiDecoderToolConfigurationState extends State<MultiDecoderToolConfiguration> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
        children: widget.widgets.entries.map((entry) {
      return Row(
        children: [
          Expanded(child: GCWText(text: i18n(context, entry.key)), flex: 1),
          Expanded(child: entry.value, flex: 3),
        ],
      );
    }).toList());
  }
}