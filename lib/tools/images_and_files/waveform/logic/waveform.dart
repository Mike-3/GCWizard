import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:gc_wizard/tools/images_and_files/waveform/logic/id3_data.dart';
import 'package:gc_wizard/tools/science_and_technology/numeral_bases/logic/numeral_bases.dart';
import 'package:gc_wizard/utils/file_utils/file_utils.dart';

part 'package:gc_wizard/tools/images_and_files/waveform/logic/waveform_datatypes.dart';
part 'package:gc_wizard/tools/images_and_files/waveform/logic/waveform_wav_data.dart';

SoundfileData getSoundfileData(Uint8List bytes) {
  switch (getFileType(bytes)) {
    case FileType.WAV:
    case FileType.WMV:
      return WAVContent(bytes);
    case FileType.MP3:
    case FileType.OGG:
    default:
      return SoundfileData(
          structure: [],
          PCMformat: 0,
          bits: 0,
          channels: 0,
          sampleRate: 0,
          duration: 0.0,
          amplitudesData: Uint8List.fromList([]));
  }
}
