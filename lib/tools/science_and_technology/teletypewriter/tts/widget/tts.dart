import 'package:flutter/material.dart';
import 'package:gc_wizard/tools/science_and_technology/teletypewriter/_common/logic/teletypewriter.dart';
import 'package:gc_wizard/tools/science_and_technology/teletypewriter/teletypewriter/widget/teletypewriter.dart';

class TTS extends Teletypewriter {
  const TTS({Key? key}) : super(key: key, defaultCodebook: TeletypewriterCodebook.TTS, codebook: null);
}
