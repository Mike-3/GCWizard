import 'dart:typed_data';

import 'package:gc_wizard/common_widgets/async_executer/gcw_async_executer_parameters.dart';
import 'package:image/image.dart' as Image;

class AnimatedImageJobData {
  final List<Image.Image> images;
  final List<int> durations;
  final List<int> linkList;
  final int loopCount;

  AnimatedImageJobData({required this.images, required this.durations, required this.linkList, this.loopCount = 0});
}

Future<Uint8List?> createImageAsync(GCWAsyncExecuterParameters? jobData) async {
  if (jobData?.parameters is! AnimatedImageJobData) return null;

  var data = jobData!.parameters as AnimatedImageJobData;
  var output = createImage(data.images, data.durations, data.linkList, data.loopCount);

  jobData.sendAsyncPort?.send(output);

  return output;
}

Uint8List? createImage(List<Image.Image> images, List<int> durations, List<int> linkList, int loopCount) {
  try {
    if (images.isEmpty || linkList.isEmpty) return null;

    var animation = Image.Image(width: images.first.width, height: images.first.height);
    for (var i= 0; i <linkList.length; i++) {
      if (linkList[i] < animation.length ) {
        var imageClone = images[linkList[i]].clone();
        if (i < durations.length ) {
          imageClone.frameDuration = durations[i];
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