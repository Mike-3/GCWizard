import 'dart:math';
import 'dart:typed_data';

import 'package:gc_wizard/common_widgets/async_executer/gcw_async_executer_parameters.dart';
import 'package:image/image.dart' as Image;
import 'package:utility/utility.dart';

enum EncodeMode {LOOP, REVERSE}

class AnimatedImageJobData {
  final List<Uint8List> images;
  final List<MapEntry<int, int>> durations;
  final EncodeMode mode;
  final int? loopDisplayDuration;
  final int loopCount;

  AnimatedImageJobData({required this.images, required this.durations, required this.mode,
    this.loopDisplayDuration, this.loopCount = 0});
}

Future<Uint8List?> createImageAsync(GCWAsyncExecuterParameters? jobData) async {
  if (jobData?.parameters is! AnimatedImageJobData) return null;

  var data = jobData!.parameters as AnimatedImageJobData;
  var output = createImage(data.images, _prepareDurations(data.durations, data.mode, data.loopDisplayDuration)
      , data.loopCount);

  jobData.sendAsyncPort?.send(output);

  return output;
}

List<MapEntry<int, int>> _prepareDurations(List<MapEntry<int, int>> durations, EncodeMode mode,
    int? loopDisplayDuration) {

  List<MapEntry<int, int>>? list;

  if (loopDisplayDuration != null && loopDisplayDuration > 0) {
    list = List<MapEntry<int, int>>.from(durations);
    var duration = (max(loopDisplayDuration, 0) / max(durations.length, 1)).toInt();
    for (var i = 0; i < list.length; i++) {
      list[i] = MapEntry(list[i].key, duration);
    }
  }

  if (mode == EncodeMode.REVERSE) {
    // 1234, 321, 234 no image with double view length
    list = list ?? List<MapEntry<int, int>>.from(durations);

    var list2 = list.reversed.toList();
    list2.removeFirst();
    list.addAll(list2);
    list2 = List<MapEntry<int, int>>.from(durations);
    list2.removeFirst();
    list.addAll(list2);
    return list;
  }
  return list ?? durations;
}

Uint8List? createImage(List<Uint8List> images,  List<MapEntry<int, int>> durations, int loopCount) {
  try {
    if (images.isEmpty || durations.isEmpty) return null;
    var convertedImages = <Image.Image?>[];
    for (var bytes in images) {
      var decoder = Image.findDecoderForData(bytes);
      Image.Image? convertedImage;
      if (decoder != null) {
        convertedImage = decoder.decode(bytes);
      }
      convertedImages.add(convertedImage);
    }
    var firstImage = convertedImages[durations[0].key - 1]?.clone();
    if (firstImage == null) return null;
    firstImage.frameDuration = max(durations[0].value, 0);

    var animation = firstImage;
    for (var i = 1; i < durations.length; i++) {
      if (durations[i].key > 0 && durations[i].key <= animation.length ) {
        var imageClone = convertedImages[durations[i].key - 1]?.clone();
        if (imageClone == null) continue;
        if (i < durations.length ) {
          imageClone.frameDuration = max(durations[i].value, 0);
        }
        animation.frames.add(imageClone);
      }
    }
    animation.loopCount = loopCount;

    final image = Image.encodeGif(animation, singleFrame: false, repeat: loopCount);

    return image;
  } on Exception {
    return null;
  }
}