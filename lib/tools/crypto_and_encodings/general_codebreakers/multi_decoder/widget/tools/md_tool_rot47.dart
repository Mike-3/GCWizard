import 'package:flutter/material.dart';

import 'package:gc_wizard/tools/crypto_and_encodings/general_codebreakers/multi_decoder/widget/multi_decoder.dart';
import 'package:gc_wizard/tools/crypto_and_encodings/rotation/logic/rotator.dart';

const MDT_INTERNALNAMES_ROT47 = 'multidecoder_tool_rot47_title';

class MultiDecoderToolROT47 extends AbstractMultiDecoderTool {
  MultiDecoderToolROT47({Key key, int id, String name, Map<String, dynamic> options})
      : super(
            key: key,
            id: id,
            name: name,
            internalToolName: MDT_INTERNALNAMES_ROT47,
            onDecode: (String input, String key) {
              return Rotator().rot47(input);
            },
            options: options);
}