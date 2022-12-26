import 'package:flutter/material.dart';
import 'package:gc_wizard/tools/crypto_and_encodings/logic/teletypewriter.dart';
import 'package:gc_wizard/tools/crypto_and_encodings/teletypewriter/teletypewriter/widget/teletypewriter.dart';

class CCIR476 extends Teletypewriter {
  CCIR476({Key key}) : super(key: key, defaultCodebook: TeletypewriterCodebook.CCIR476, codebook: null);
}