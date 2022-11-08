import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:gc_wizard/logic/tools/crypto_and_encodings/morse.dart';
import 'package:gc_wizard/logic/tools/images_and_files/animated_image.dart' as animated_image;
import 'package:image/image.dart' as Image;
import 'package:tuple/tuple.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class VideoMorseCodeJobData {
  final String videoPath;
  final IVideoCompress videoCompress;
  ///coordinates of top-left area to examine (0.0-1.0)
  final Point<double> topLeft;
  /// coordinates of bottom-right area to examine (0.0-1.0)
  final Point<double> bottomRight;

  VideoMorseCodeJobData(this.videoPath,
      {this.topLeft = null, this.bottomRight = null, this.videoCompress = null});
}

Future<Map<String, dynamic>> analyseVideoMorseCodeAsync(dynamic jobData) async {
  if (jobData == null) return null;

  var output = await analyseVideoMorseCode(jobData.parameters.videoPath,
      topLeft: jobData.parameters.topLeft,
      bottomRight: jobData.parameters.bottomRight,
      videoCompress: jobData.parameters.videoCompress,
      sendAsyncPort: jobData.sendAsyncPort);

  if (jobData.sendAsyncPort != null) jobData.sendAsyncPort.send(output);

  return output;
}

Future<Map<String, dynamic>> analyseVideoMorseCode(String videoPath,
    {int intervall = 50,
      Point<double> topLeft,
      Point<double> bottomRight,
      IVideoCompress videoCompress, SendPort sendAsyncPort}) async {

    // var out = animated_image.analyseImage(bytes, sendAsyncPort: sendAsyncPort, filterImages: (outMap, frames) {
    //   List<Uint8List> imageList = outMap["images"];
    //   var filteredList = <List<int>>[];
    //
    //   // for (var i = 0; i < imageList.length; i++) filteredList = _filterImages(filteredList, i, imageList);
    //
    //   // filteredList = _searchHighSignalImage(frames, filteredList);
    //   // outMap.addAll({"imagesFiltered": filteredList});
    // });

  if (videoCompress == null) videoCompress = VideoCompress;
  if (topLeft == null)
    topLeft = Point<double>(0.0, 0.0);
  else
    topLeft = Point<double>(topLeft.x.clamp(0.0, 1.0), topLeft.y.clamp(0.0, 1.0));

  if (bottomRight == null)
    bottomRight = Point<double>(1.0, 1.0);
  else
    bottomRight = Point<double>(bottomRight.x.clamp(topLeft.x, 1.0), bottomRight.y.clamp(topLeft.y, 1.0));


  return await _createThumbnailImages(videoPath, intervall, videoCompress,
        topLeft, bottomRight,
        sendAsyncPort: sendAsyncPort);
}

Future<Map<String, dynamic>> _createThumbnailImages(String videoPath, int intervall,
    IVideoCompress videoCompress,
    Point<double> topLeft,
    Point<double> bottomRight,
    { SendPort sendAsyncPort}) async {
  var timeStamp = 000; //39500;
  Uint8List thumbnail;
  List<Uint8List> imageList = [];
  List<int> durationList = [];
  List<double> luminanceList = [];
  var videoInfo = await VideoCompress.getMediaInfo(videoPath);
  var _total =  (videoInfo.duration - timeStamp) / intervall;
  int _progressStep = max((_total / 100).toInt(), 1);
  int _progress = 0;
var time = DateTime.now();


  // do {
  //   thumbnail = await _createThumbnailImage(videoPath, timeStamp, videoCompress);
  //   timeStamp += intervall;
  //   if (thumbnail != null) {
  //     imageList.add(thumbnail);
  //     durationList.add(intervall);
  //     luminanceList.add(await _imageLuminance_(thumbnail, topLeft, bottomRight));
  //   }
  //   _progress++;
  //   print(timeStamp.toString() + ' ' + luminanceList.last.toString());
  //   if (_total != 0 && sendAsyncPort != null && (_progress % _progressStep == 0)) {
  //     sendAsyncPort.send({'progress': _progress / _total});
  //   }
  // } while (thumbnail != null && timeStamp < videoInfo.duration);

  do {
    await _createThumbnailImage(videoPath, timeStamp, videoCompress).then((thumbnail) async {
      if (thumbnail != null) {
        imageList.add(thumbnail);
        durationList.add(intervall);
        luminanceList.add(await _imageLuminance_(thumbnail, topLeft, bottomRight));
      }
    });
    timeStamp += intervall;

    _progress++;
    print(timeStamp.toString() + ' ' + luminanceList.last.toString());
    if (_total != 0 && sendAsyncPort != null && (_progress % _progressStep == 0)) {
      sendAsyncPort.send({'progress': _progress / _total});
    }
  } while ( timeStamp < videoInfo.duration); //thumbnail != null &&

// Future.wait(
// __createThumbnailImages(videoPath, intervall,
//       imageList,
//       durationList,
//       luminanceList,
//       videoCompress,
//       topLeft, bottomRight,
//       sendAsyncPort: sendAsyncPort
//   )
// );
  print("Duration: " + DateTime.now().difference(time).inSeconds.toString());

  var out = Map<String, dynamic>();
  out.addAll({"images": imageList});
  out.addAll({"durations": durationList});
  out.addAll({"luminance": luminanceList});

  var minMax = _minMaxLuminance(luminanceList);
  out.addAll({"minLuminance": minMax.item1});
  out.addAll({"maxLuminance": minMax.item2});
  out.addAll({"threshold": _findThreshold (luminanceList, minMax.item1, minMax.item2 )});

  return out;
}

__createThumbnailImages(String videoPath, int intervall,
    List<Uint8List> imageList,
    List<int> durationList,
    List<double> luminanceList,

    IVideoCompress videoCompress,
    Point<double> topLeft,
    Point<double> bottomRight,
    { SendPort sendAsyncPort}) async {

  var timeStamp = 000; //39500;

  var videoInfo = await VideoCompress.getMediaInfo(videoPath);
  var _total =  (videoInfo.duration - timeStamp) / intervall;
  int _progressStep = max((_total / 100).toInt(), 1);
  int _progress = 0;

  var counter = 0;
  do {
    _createThumbnailImage(videoPath, timeStamp, videoCompress).then((thumbnail) async {
      timeStamp += intervall;
      if (thumbnail != null) {
        imageList.add(thumbnail);
        durationList.add(intervall);
        luminanceList.add(await _imageLuminance_(thumbnail, topLeft, bottomRight));
      }
      _progress++;
      print(timeStamp.toString() + ' ' + luminanceList.last.toString());
      if (_total != 0 && sendAsyncPort != null && (_progress % _progressStep == 0)) {
        sendAsyncPort.send({'progress': _progress / _total});
      }
    });
    counter++;
  } while ((counter < 6) && (timeStamp < videoInfo.duration)); //thumbnail != null &&

}

Future<Uint8List> _createThumbnailImage(String videoPath, int timeStampMs, IVideoCompress videoCompress ) async {
  return VideoThumbnail.thumbnailData(
    video: videoPath,
    maxWidth: 128, // specify the width of the thumbnail, let the height auto-scaled to keep the source aspect ratio
    quality: 100,
    timeMs: timeStampMs
  );
}

Future<double> _imageLuminance_(Uint8List image,
    Point<double> topLeft,
    Point<double> bottomRight) async {
  var _image = Image.decodeImage(image);

  if (_changeImageSize(topLeft, bottomRight)) {
    _image = _cropImage(_image, topLeft, bottomRight);
    //image = Image.encodePng(_image);
  }
  return _imageLuminance(_image, topLeft, bottomRight);
}

Image.Image _cropImage(Image.Image image, Point<double> topLeft, Point<double> bottomRight ) {
  if (!_changeImageSize(topLeft, bottomRight)) return image;
  return Image.copyCrop(image, (image.width * topLeft.x).toInt(), (image.height * topLeft.y).toInt(),
      (image.width * (bottomRight.x- topLeft.x)).toInt(), (image.height * (bottomRight.y- topLeft.y)).toInt());
}

bool _changeImageSize(Point<double> topLeft, Point<double> bottomRight) {
  return !(topLeft == Point<double>(0.0, 0.0) && bottomRight == Point<double>(1.0, 1.0));
}

Tuple2 <double, double> _minMaxLuminance(List<double> LuminanceList) {
  var _min = 99999.9;
  var _max = -99999.9;
  LuminanceList.forEach((luminance) {
    _min = min(_min, luminance);
    _max = max(_max, luminance);
  });

  return Tuple2 <double, double>(_min, _max);
}

double _findThreshold(List<double> brightnessList, double min, double max) {
  // """Return threshold value to split `signal` into two bins.
  //       Assumes `signal` is bimodal.
  //       :param signal: signal to threshold.
  //       :param tolerance: acceptable amount of wiggle when computing threshold.
  //       :return: computed threshold value.
  //       """
  // # Initial threshold guess is the halfway point.
  var tolerance = 1;
  var threshold = min + ((max - min) / 2);

  return 100.0;

  // # Guarantee the while loop gets entered at least once.
  var last_threshold = threshold + tolerance + 1;

  // # Find the "best" threshold.
  while ((threshold - last_threshold).abs() > tolerance) {
    var lowList = brightnessList.where((signal) => signal < threshold);
    if (lowList.length  == 0) return last_threshold;
    var low = (lowList.reduce((a, b) => a + b))/ lowList.length;  //signal[signal < threshold].mean();
    var highList = brightnessList.where((signal) => signal >= threshold);
    if (highList.length  == 0) return last_threshold;
    var high = (lowList.reduce((a, b) => a + b))/ highList.length; //signal[signal >= threshold].mean();
    last_threshold = threshold;
    threshold = low + ((high - low) / 2);
  }
  return threshold;
}


double _imageLuminance(Image.Image image, Point<double> topLeft, Point<double> bottomRight) {
  var sum = -9999;
  for (var x = 0; x < image.width; x++) {
    for (var y = 0; y < image.height; y++) {
      //sum += Image.getLuminance(image.getPixel(x, y));
      sum = max(sum, Image.getLuminance(image.getPixel(x, y)));
    }
  }

  return sum.toDouble(); // sum / (image.width * image.height);
}
