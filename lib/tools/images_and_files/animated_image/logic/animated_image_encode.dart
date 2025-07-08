import 'dart:math';
import 'dart:typed_data';

import 'package:gc_wizard/common_widgets/async_executer/gcw_async_executer_parameters.dart';
import 'package:image/image.dart' as Image;

class AnimatedImageJobData {
  final List<Uint8List> images;
  final  List<MapEntry<int, int>> durations;
  final int loopCount;

  AnimatedImageJobData({required this.images, required this.durations, this.loopCount = 0});
}

Future<Uint8List?> createImageAsync(GCWAsyncExecuterParameters? jobData) async {
  if (jobData?.parameters is! AnimatedImageJobData) return null;

  var data = jobData!.parameters as AnimatedImageJobData;
  var output = createImage(data.images, data.durations, data.loopCount);

  jobData.sendAsyncPort?.send(output);

  return output;
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
    var firstImage = convertedImages.firstWhere((image) => image != null);
    if (firstImage == null) return null;
    var animation = Image.Image(width: firstImage.width, height: firstImage.height);
    for (var i = 0; i < durations.length; i++) {
      if (durations[i].key > 0 && durations[i].key <= animation.length ) {
        var imageClone = convertedImages[durations[i].key + 1]?.clone();
        if (imageClone == null) continue;
        if (i < durations.length ) {
          imageClone.frameDuration = max(durations[i].value, 0);
        }
        animation.frames.add(imageClone);
      }
    }
    animation.loopCount = loopCount;

    final image = Image.encodeGif(animation, singleFrame: false, repeat:  loopCount);

    return image;
  } on Exception {
    return null;
  }
}