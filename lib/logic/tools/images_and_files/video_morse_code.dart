import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:gc_wizard/logic/tools/crypto_and_encodings/morse.dart';
import 'package:gc_wizard/logic/tools/images_and_files/animated_image.dart' as animated_image;
import 'package:image/image.dart' as Image;
import 'package:tuple/tuple.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

Future<Map<String, dynamic>> analyseVideoMorseCodeAsync(dynamic jobData) async {
  if (jobData == null) return null;

  var output = await analyseVideoMorseCode(jobData.parameters, sendAsyncPort: jobData.sendAsyncPort);

  if (jobData.sendAsyncPort != null) jobData.sendAsyncPort.send(output);

  return output;
}

Future<Map<String, dynamic>> analyseVideoMorseCode(String videoPath, {int intervall = 100, SendPort sendAsyncPort}) async {
  try {
    // var out = animated_image.analyseImage(bytes, sendAsyncPort: sendAsyncPort, filterImages: (outMap, frames) {
    //   List<Uint8List> imageList = outMap["images"];
    //   var filteredList = <List<int>>[];
    //
    //   // for (var i = 0; i < imageList.length; i++) filteredList = _filterImages(filteredList, i, imageList);
    //
    //   // filteredList = _searchHighSignalImage(frames, filteredList);
    //   // outMap.addAll({"imagesFiltered": filteredList});
    // });

    return await _createThumbnailImages(videoPath, intervall);
  } on Exception {
    return null;
  }
}

Future<Map<String, dynamic>> _createThumbnailImages(String videoPath, int intervall) async {
  var timeStamp = 0;
  Uint8List thumbnail;
  List<Uint8List> imageList = [];
  List<int> durationList = [];
  List<double> brightnessList = [];


  do {
    thumbnail = await _createThumbnailImage(videoPath, timeStamp);
    timeStamp += intervall;
    if (thumbnail != null) {
      imageList.add(thumbnail);
      durationList.add(intervall);
      brightnessList.add(await _imageBrightness(thumbnail));
    }
  } while (thumbnail == null);

  var out = Map<String, dynamic>();
  out.addAll({"images": imageList});
  out.addAll({"durations": durationList});
  out.addAll({"brightnesses": brightnessList});

  return out;
}

Future<Uint8List> _createThumbnailImage(String videoPath, int timeStampMs) async {
  return VideoThumbnail.thumbnailData(
    video: videoPath,
    //maxWidth: 128, // specify the width of the thumbnail, let the height auto-scaled to keep the source aspect ratio
    quality: 75,
    timeMs: timeStampMs
  );
}

Future<double> _imageBrightness(Uint8List image) async {
  var _image = Image.decodeImage(image);
  return _imageLuminance(_image);
}


double _imageLuminance(Image.Image image) {
  var sum = 0;
  for (var x = 0; x < image.width; x++) {
    for (var y = 0; y < image.height; y++) {
      sum += Image.getLuminance(image.getPixel(x, y));
    }
  }

  return sum / (image.width * image.height);
}
