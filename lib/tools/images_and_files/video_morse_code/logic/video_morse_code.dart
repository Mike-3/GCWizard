import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:ffmpeg_kit_flutter/return_code.dart';
import 'package:gc_wizard/common_widgets/async_executer/gcw_async_executer_parameters.dart';
import 'package:gc_wizard/utils/file_utils/file_utils.dart';
import 'package:image/image.dart' as Image;
import 'package:tuple/tuple.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_player/video_player.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
// import 'package:ffmpeg_kit_flutter_min_gpl/ media_information.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:path_provider/path_provider.dart';

class VideoMorseCodeJobData {
  final String videoPath;
  final int intervall;
  final int startTime;
  final int endTime;
  ///coordinates of top-left area to examine (0.0-1.0)
  final Point<double>? topLeft;
  /// coordinates of bottom-right area to examine (0.0-1.0)
  final Point<double>? bottomRight;
  VideoPlayerController _controller;



  VideoMorseCodeJobData(this.videoPath, this.intervall,
        { required this.startTime,
          required this.endTime,
          this.topLeft,
          this.bottomRight});
}

Future<Map<String, dynamic>?> analyseVideoMorseCodeAsync(GCWAsyncExecuterParameters? jobData) async {
  if (jobData?.parameters is! VideoMorseCodeJobData) return null;

  var data = jobData!.parameters as VideoMorseCodeJobData;
  var output = await analyseVideoMorseCode(data.videoPath, data.intervall,
      startTime: data.startTime,
      endTime:  data.endTime,
      topLeft: data.topLeft,
      bottomRight: data.bottomRight,
      isCancelled: jobData.isCancelled,
      sendAsyncPort: jobData.sendAsyncPort);

  if (jobData.sendAsyncPort != null) jobData.sendAsyncPort.send(output);

  return output;
}


Future<Map<String, dynamic>> analyseVideoMorseCode(String videoPath, int intervall,
    { required int startTime,
      required int endTime,
      Point<double>? topLeft,
      Point<double>? bottomRight,
      required Function isCancelled,
      SendPort? sendAsyncPort}) async {

  var videoCompress = VideoCompress;
  if (topLeft == null) {
    topLeft = const Point<double>(0.0, 0.0);
  } else {
    topLeft = Point<double>(topLeft.x.clamp(0.0, 1.0), topLeft.y.clamp(0.0, 1.0));
  }

  if (bottomRight == null) {
    bottomRight = const Point<double>(1.0, 1.0);
  } else {
    bottomRight = Point<double>(bottomRight.x.clamp(topLeft.x, 1.0), bottomRight.y.clamp(topLeft.y, 1.0));
  }


  return await _createThumbnailImages(videoPath, intervall, startTime, endTime, videoCompress,
        topLeft, bottomRight, isCancelled,
        sendAsyncPort: sendAsyncPort);
}

Future<Map<String, dynamic>> _createThumbnailImages(String videoPath, int intervall,
    int startTime,
    int endTime,
    IVideoCompress videoCompress,
    Point<double> topLeft,
    Point<double> bottomRight,
    Function isCancelled,
    { required SendPort sendAsyncPort}) async {

  String tmpDir = (await getTemporaryDirectory()).path;
  var videoDir = '$tmpDir/video';
  deleteDirectory(videoDir);
  createDirectory(videoDir);


/// https://stackoverflow.com/questions/73783637/how-to-extract-all-video-frames-using-ffmpeg-kit-with-flutter
  FFmpegKit.executeAsync('-i ${videoPath} -vf  fps=1/60 scale=-1:170 ${videoDir}/out%04d.png').then((session) async {
    // final state = FFmpegKitConfig.sessionStateToString(
    //     await session.getState());
    final returnCode = await session.getReturnCode();
    final failStackTrace = await session.getFailStackTrace();
    final duration = await session.getDuration();

    if (ReturnCode.isSuccess(returnCode)) {
      print(
          "Encode completed successfully in ${duration} milliseconds; playing video.");
      //this.playVideo();
    } else {
      print(
          "Encode failed. Please check log for the details.");
      print(
          " rc ${returnCode}" );//${(failStackTrace)} ? "" + "\\n"");
    }
    return null;
  });

  List<Uint8List> imageList = [];
  List<int> durationList = [];
  List<double> luminanceList = [];
  var videoInfo = await VideoCompress.getMediaInfo(videoPath);
  endTime = (endTime == null ? videoInfo.duration.toInt() : min(endTime, videoInfo.duration.toInt()));
  var timeStamp = (startTime == null ? 0 : min(startTime, endTime));
  var _total =  (endTime - timeStamp) / intervall;
  int _progressStep = max((_total / 100).toInt(), 1);
  int _progress = 0;
var time = DateTime.now();


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
    // ToDo remove
    print(timeStamp.toString() + ' ' + luminanceList.last.toString());
    if (_total != 0 && sendAsyncPort != null && (_progress % _progressStep == 0)) {
      sendAsyncPort.send({'progress': _progress / _total});
    }
  } while (timeStamp < endTime && (isCancelled == null || !isCancelled()));

  print("Duration: " + DateTime.now().difference(time).inSeconds.toString());

  var out = Map<String, dynamic>();
  out.addAll({"duration": videoInfo.duration?.toInt()});
  out.addAll({"images": imageList});
  out.addAll({"durations": durationList});
  out.addAll({"luminance": luminanceList});

  var minMax = _minMaxLuminance(luminanceList);
  out.addAll({"minLuminance": minMax.item1});
  out.addAll({"maxLuminance": minMax.item2});
  out.addAll({"blackLevel": _findThreshold (luminanceList, minMax.item1, minMax.item2 )});

  return out;
}


Future<Uint8List> _createThumbnailImage(String videoPath, int timeStampMs, IVideoCompress videoCompress ) async {
  return VideoThumbnail.thumbnailData(
    video: videoPath,
    maxWidth: 128, // specify the width of the thumbnail, let the height auto-scaled to keep the source aspect ratio
    quality: 100,
    timeMs: timeStampMs
  );
}

Future<double> _imageLuminance_(Uint8List image, Point<double> topLeft, Point<double> bottomRight) async {
  var _image = Image.decodeImage(image);

  if (_changeImageSize(topLeft, bottomRight)) {
    _image = _cropImage(_image!, topLeft, bottomRight);
    //image = Image.encodePng(_image);
  }
  return _imageLuminance(_image!, topLeft, bottomRight);
}

Image.Image _cropImage(Image.Image image, Point<double> topLeft, Point<double> bottomRight ) {
  if (!_changeImageSize(topLeft, bottomRight)) return image;
  return Image.copyCrop(image, x: (image.width * topLeft.x).toInt(), y: (image.height * topLeft.y).toInt(),
      width: (image.width * (bottomRight.x- topLeft.x)).toInt(), height: (image.height * (bottomRight.y- topLeft.y)).toInt());
}

bool _changeImageSize(Point<double> topLeft, Point<double> bottomRight) {
  return !(topLeft == const Point<double>(0.0, 0.0) && bottomRight == const Point<double>(1.0, 1.0));
}

Tuple2 <double, double> _minMaxLuminance(List<double> LuminanceList) {
  var _min = 99999.9;
  var _max = -99999.9;
  for (var luminance in LuminanceList) {
    _min = min(_min, luminance);
    _max = max(_max, luminance);
  }

  return Tuple2 <double, double>(_min, _max);
}

double _findThreshold(List<double> luminanceList, double min, double max) {
  // """Return threshold value to split `signal` into two bins.
  //       Assumes `signal` is bimodal.
  //       :param signal: signal to threshold.
  //       :param tolerance: acceptable amount of wiggle when computing threshold.
  //       :return: computed threshold value.
  //       """
  // # Initial threshold guess is the halfway point.
  var tolerance = 1;
  var threshold = min + ((max - min) / 2);

  return threshold;

  // # Guarantee the while loop gets entered at least once.
  var last_threshold = threshold + tolerance + 1;

  // # Find the "best" threshold.
  while ((threshold - last_threshold).abs() > tolerance) {
    var lowList = luminanceList.where((signal) => signal < threshold);
    if (lowList.length  == 0) return last_threshold;
    var low = (lowList.reduce((a, b) => a + b))/ lowList.length;  //signal[signal < threshold].mean();
    var highList = luminanceList.where((signal) => signal >= threshold);
    if (highList.length  == 0) return last_threshold;
    var high = (lowList.reduce((a, b) => a + b))/ highList.length; //signal[signal >= threshold].mean();
    last_threshold = threshold;
    threshold = low + ((high - low) / 2);
  }
  return threshold;
}


double _imageLuminance(Image.Image image, Point<double> topLeft, Point<double> bottomRight) {
  num sum = -9999;
  for (var x = 0; x < image.width; x++) {
    for (var y = 0; y < image.height; y++) {
      //sum += Image.getLuminance(image.getPixel(x, y));
      sum = max(sum, Image.getLuminance(image.getPixel(x, y)));
    }
  }

  return (sum * 100.0/ 255.0).toDouble(); // sum / (image.width * image.height);
}
