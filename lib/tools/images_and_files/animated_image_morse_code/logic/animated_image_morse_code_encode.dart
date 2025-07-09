import 'dart:typed_data';

import 'package:gc_wizard/common_widgets/async_executer/gcw_async_executer_parameters.dart';
import 'package:gc_wizard/tools/crypto_and_encodings/morse/logic/morse.dart';
import 'package:gc_wizard/tools/images_and_files/animated_image/logic/animated_image_encode.dart';

class AnimatedImageMorseCodeJobData {
  final List<Uint8List> images;
  final int imageOn;
  final int imageOff;
  final int? imageFirst;
  final int? imageFirstDuration;
  final int? imageLast;
  final int? imageLastDuration;
  final int dotDuration;
  final String text;
  final int loopCount;

  AnimatedImageMorseCodeJobData({required this.images, required this.imageOn, required this.imageOff,
    required this.dotDuration, required this.text, this.imageFirst, this.imageFirstDuration,
    this.imageLast, this.imageLastDuration, this.loopCount = 0});
}

Future<Uint8List?> createImageMorseCodeAsync(GCWAsyncExecuterParameters? jobData) async {
  if (jobData?.parameters is! AnimatedImageMorseCodeJobData) return null;

  var data = jobData!.parameters as AnimatedImageMorseCodeJobData;
  var output = createImage(data.images, _prepareDurations(data.imageOn, data.imageOff, data.dotDuration,
      data.text, data.imageFirst, data.imageFirstDuration, data.imageLast, data.imageLastDuration), data.loopCount);

  jobData.sendAsyncPort?.send(output);

  return output;
}

List<MapEntry<int, int>> _prepareDurations(int imageOn, int imageOff, int dotDurationLength, String text,
    int? imageFirst, int? imageFirstDuration, int? imageLast, int? imageLastDuration) {

  var list = <MapEntry<int, int>>[];
  var morse = decodeMorse(text);
  if (imageFirst != null) {
    list.add(MapEntry(imageFirst, imageFirstDuration ?? dotDurationLength));
  }
  for (var i = 0; i < morse.length; i++) {
    if (morse[i] == '.') {
      list.add(MapEntry(imageOn, dotDurationLength));
      list.add(MapEntry(imageOff, dotDurationLength));
    } else if (morse[i] == '-') {
      list.add(MapEntry(imageOff, dotDurationLength * 3));
      list.add(MapEntry(imageOff, dotDurationLength));
    } else {
      if (list.isNotEmpty && list.last.key == imageOff && list.last.value == dotDurationLength) {
        list.last = MapEntry(imageOff, dotDurationLength * 5);
      } else {
        list.add(MapEntry(imageOff, dotDurationLength * 5));
      }
    }
  }
  if (imageLast != null) {
    list.add(MapEntry(imageLast, imageLastDuration ?? dotDurationLength));
  }
  return list;
}