import 'dart:isolate';
import 'dart:typed_data';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:gc_wizard/i18n/app_localizations.dart';
import 'package:gc_wizard/logic/tools/images_and_files/animated_image_morse_code.dart';
import 'package:gc_wizard/logic/tools/images_and_files/video_morse_code.dart';
import 'package:gc_wizard/theme/theme_colors.dart';
import 'package:gc_wizard/widgets/common/base/gcw_iconbutton.dart';
import 'package:gc_wizard/widgets/common/base/gcw_output_text.dart';
import 'package:gc_wizard/widgets/common/base/gcw_slider.dart';
import 'package:gc_wizard/widgets/common/base/gcw_text.dart';
import 'package:gc_wizard/widgets/common/base/gcw_textfield.dart';
import 'package:gc_wizard/widgets/common/base/gcw_toast.dart';
import 'package:gc_wizard/widgets/common/gcw_async_executer.dart';
import 'package:gc_wizard/widgets/common/gcw_default_output.dart';
import 'package:gc_wizard/widgets/common/gcw_exported_file_dialog.dart';
import 'package:gc_wizard/widgets/common/gcw_gallery.dart';
import 'package:gc_wizard/widgets/common/gcw_imageview.dart';
import 'package:gc_wizard/widgets/common/gcw_integer_spinner.dart';
import 'package:gc_wizard/widgets/common/gcw_openfile.dart';
import 'package:gc_wizard/widgets/common/gcw_output.dart';
import 'package:gc_wizard/widgets/common/gcw_submit_button.dart';
import 'package:gc_wizard/widgets/common/gcw_text_divider.dart';
import 'package:gc_wizard/widgets/common/gcw_twooptions_switch.dart';
import 'package:gc_wizard/widgets/tools/images_and_files/animated_image.dart';
import 'package:gc_wizard/widgets/utils/file_utils.dart';
import 'package:gc_wizard/widgets/utils/gcw_file.dart' as local;
import 'package:intl/intl.dart';
import 'package:tuple/tuple.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class VideoMorseCode extends StatefulWidget {
  final local.GCWFile platformFile;

  const VideoMorseCode({Key key, this.platformFile}) : super(key: key);

  @override
  VideoMorseCodeState createState() => VideoMorseCodeState();
}

class VideoMorseCodeState extends State<VideoMorseCode> {
  Map<String, dynamic> _outData;
  var _marked = <bool>[];
  int _intervall = 50;
  double _blackLevel = 50;
  double _blackLevelNext;
  var _currentSimpleMode = GCWSwitchPosition.left;
  Map<String, dynamic> _outText;
  local.GCWFile _platformFile;
  // GCWSwitchPosition _currentMode = GCWSwitchPosition.right;
  bool _play = false;
  bool _filtered = true;
  static var allowedExtensions = [FileType.MP4, FileType.WEBM];

  String _currentInput = '';
  int _currentDotDuration = 400;
  TextEditingController _currentDotDurationController;
  TextEditingController _currentInputController;

  @override
  void initState() {
    super.initState();

    _currentInputController = TextEditingController(text: _currentInput);
    _currentDotDurationController = TextEditingController(text: _currentDotDuration.toString());
  }

  @override
  void dispose() {
    _currentInputController.dispose();
    _currentDotDurationController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.platformFile != null) {
      _platformFile = widget.platformFile;
      _analysePlatformFileAsync();
    }

    return Column(children: <Widget>[
      // GCWTwoOptionsSwitch(
      //   value: _currentMode,
      //   onChanged: (value) {
      //     setState(() {
      //       _currentMode = value;
      //     });
      //   },
      // ),
      // _currentMode == GCWSwitchPosition.right ? _decodeWidgets() : _encodeWidgets()
      _decodeWidgets(),
    ]);
  }




  Widget _decodeWidgets() {
    return Column(children: <Widget>[
      GCWOpenFile(
        supportedFileTypes: allowedExtensions,
        onLoaded: (_file) {
          if (_file == null) {
            showToast(i18n(context, 'common_loadfile_exception_notloaded'));
            return;
          }

          if (_file != null) {
            setState(() {
              _platformFile = _file;
              _outData = null;
              _marked = null;
              _blackLevel = 50;
              _blackLevelNext = null;
              _analysePlatformFileAsync();
            });
          }
        },
      ),
      GCWTwoOptionsSwitch(
        value: _currentSimpleMode,
        leftValue: i18n(context, 'common_mode_simple'),
        rightValue: i18n(context, 'common_mode_advanced'),
        onChanged: (value) {
          setState(() {
            _currentSimpleMode = value;
          });
        },
      ),
      _currentSimpleMode == GCWSwitchPosition.left ? Container() : _buildAdvancedModeControl(context),
      GCWDefaultOutput(
          child: _buildOutputDecode(),
          trailing: Row(children: <Widget>[
            GCWIconButton(
              icon: _filtered ? Icons.filter_alt : Icons.filter_alt_outlined,
              size: IconButtonSize.SMALL,
              iconColor: _outData != null ? null : themeColors().inActive(),
              onPressed: () {
                setState(() {
                  _filtered = !_filtered;
                });
              },
            ),
            GCWIconButton(
              icon: Icons.play_arrow,
              size: IconButtonSize.SMALL,
              iconColor: _outData != null && !_play ? null : themeColors().inActive(),
              onPressed: () {
                setState(() {
                  _play = (_outData != null);
                });
              },
            ),
            GCWIconButton(
              icon: Icons.stop,
              size: IconButtonSize.SMALL,
              iconColor: _play ? null : themeColors().inActive(),
              onPressed: () {
                setState(() {
                  _play = false;
                });
              },
            ),
            GCWIconButton(
              icon: Icons.save,
              size: IconButtonSize.SMALL,
              iconColor: _outData == null ? themeColors().inActive() : null,
              onPressed: () {
                _outData == null ? null : _exportFiles(context, _platformFile.name, _outData["images"]);
              },
            )
          ]))
    ]);
  }

  Widget _buildAdvancedModeControl(BuildContext context) {
    return Column(children: <Widget>[
      GCWIntegerSpinner(
        title: 'Intervall (ms)', //i18n(context, 'visual_cryptography_offset') + ' X',
        value: _intervall,
        onChanged: (value) {
          setState(() {
            _intervall = value;
            //if (_platformFile != null) _analysePlatformFileAsync();
          });
        },
      ),
      GCWSlider(
          title: i18n(context, 'symbol_replacer_black_level'),
          value: _blackLevel,
          min: 1,
          max: 100,
          onChangeEnd: (value) {
            setState(() {
              _marked = null;
              _blackLevel = value;
              _blackLevelNext = value;
              _convertImageData(_outData);
            });
          },
          onChanged: (value) {
    _marked = null;
    }),
    ]);
  }

  Widget _buildOutputDecode() {
    if (_outData == null) return null;

    return Column(children: <Widget>[
      // _play
      //     ? Image.memory(_platformFile.bytes)
          // : _filtered
          //     ? GCWGallery(
          //         imageData:
          //           _convertImageData(_outData["images"], null, null), //_convertImageDataFiltered _outData["durations"], _outData["imagesFiltered"]
          //         onDoubleTap: (index) {
          //           setState(() {
          //             // List<List<int>> imagesFiltered = _outData["imagesFiltered"];
          //
          //             // _marked[imagesFiltered[index].first] = !_marked[imagesFiltered[index].first];
          //             // _markedListSetColumn(imagesFiltered[index], _marked[imagesFiltered[index].first]);
          //             // _outText = decodeMorseCode(_outData["durations"], _marked);
          //           });
          //         },
          //       )
          //     :
      GCWGallery(
                  imageData: _convertImageData(_outData),
                  onDoubleTap: (index) {
                    setState(() {
                      // if (_marked != null && index < _marked.length) _marked[index] = !_marked[index];
                      // _outText = decodeMorseCode(_outData["durations"], _marked);
                    });
                  },
                ),
      _buildDecodeOutput(),
    ]);
  }

  Widget _buildDecodeOutput() {
    return Column(children: <Widget>[
      GCWDefaultOutput(child: GCWOutputText(text: _outText == null ? "" : _outText["text"])),
      GCWOutput(
          title: i18n(context, 'animated_image_morse_code_morse_code'),
          child: GCWOutputText(text: _outText == null ? "" : _outText["morse"])),
    ]);
  }

  _initMarkedList(List<Uint8List> images, List<double> luminances) {
    if (_marked == null || _marked.length != images.length) {
      _marked = List.filled(images.length, false);

      for (var i = 0; i < luminances.length; i++) {
        _marked[i] = luminances[i] > _blackLevel;
      };

      // // first image default as high signal
      // if (imagesFiltered.length == 2) {
      //   _markedListSetColumn(imagesFiltered[0], true);
      // }
    }
  }

  _markedListSetColumn(List<int> imagesFiltered, bool value) {
    imagesFiltered.forEach((idx) {
      _marked[idx] = value;
    });
  }

  List<GCWImageViewData> _convertImageDataFiltered(
      List<Uint8List> images, List<int> durations, List<List<int>> imagesFiltered) {
    var list = <GCWImageViewData>[];

    if (images != null) {
      var imageCount = images.length;
      // _initMarkedList(images, imagesFiltered);

      for (var i = 0; i < imagesFiltered.length; i++) {
        String description = imagesFiltered[i].length.toString() + '/$imageCount';

        var image = images[imagesFiltered[i].first];
        list.add(GCWImageViewData(local.GCWFile(bytes: image),
            description: description, marked: _marked[imagesFiltered[i].first]));
      }
      //_outText = decodeMorseCode(durations, _marked);


    }
    return list;
  }

  List<GCWImageViewData> _convertImageData(Map<String, dynamic> _outData) {
    var list = <GCWImageViewData>[];

    if (_outData == null) return list;
    List<Uint8List> images = _outData["images"];
    List<int> durations = _outData["durations"];
    List<double> luminances = _outData["luminance"];

    if (images != null) {
      var imageCount = images.length;
      _initMarkedList(images, luminances);
      var _duration = 0;

      for (var i = 0; i < images.length; i++) {
        String description = (i + 1).toString() + '/$imageCount';
        if ((durations != null) && (i < durations.length)) {
          _duration += durations[i];
          description += ': ' + _duration.toString() + ' ms ' + luminances[i].toString();
        }
        if (i == images.length-1 || _marked[i] != _marked[i+1]) {
          list.add(GCWImageViewData(local.GCWFile(bytes: images[i]), description: description, marked: _marked[i]));
          _duration = 0;
        }
      }
      _outText = decodeMorseCode(durations, _marked);

      // _outText = Map<String, dynamic>();
      // _outText.addAll({"text": _outData["minBrightness"].toString() + '/ ' + _outData["maxBrightness"].toString()});
      // _outText.addAll({"morse": _outData["threshold"].toString()});
    }
    return list;
  }


  _analysePlatformFileAsync() async {
    await analyseVideoMorseCodeAsync(await _buildJobDataDecode()) .then((data) => _saveOutputDecode(data));

    // await showDialog(
    //   context: context,
    //   barrierDismissible: false,
    //   builder: (context) {
    //     return Center(
    //       child: Container(
    //         child: GCWAsyncExecuter(
    //           isolatedFunction: dummyAsync, //analyseVideoMorseCodeAsync,
    //           parameter: _buildJobDataDecode(),
    //           onReady: (data) => _saveOutputDecode(data),
    //           isOverlay: true,
    //         ),
    //         height: 220,
    //         width: 150,
    //       ),
    //     );
    //   },
    // );
  }

  Future<GCWAsyncExecuterParameters> _buildJobDataDecode() async {
    _receivePort = ReceivePort();
    //parameters.sendAsyncPort = receivePort.sendPort;

    var jobpara = GCWAsyncExecuterParameters(
        VideoMorseCodeJobData(_platformFile.path, _intervall,
          topLeft: Point<double>(0.0, 0.0), //(0.2, 0.2)

          bottomRight: Point<double>(1.0, 1.0), //(0.8, 0.8)
        ));

    jobpara.sendAsyncPort = _receivePort.sendPort;
    //await _dummyAsync



    // analyseVideoMorseCodeAsync(jobpara).forEach((element) async {
    //   await for (var event in _receivePort) {
    //     if (event is Map<String, dynamic> && event['progress'] != null) {
    //       if (sendPort != null) sendPort.send(event);
    //       //yield event['progress'];
    //     } else {
    //       //_result = event;
    //       _receivePort.close();
    //       return event;
    //     }
    //   }
    // });

    //await analyseVideoMorseCodeAsync(jobpara).then((data) => _saveOutputDecode(data));
    // if (sendPort != null) sendPort.send({'progress': 0.5});


    return jobpara;
  }

  ReceivePort _receivePort;
SendPort sendPort;

  Future<Map<String, dynamic>> dummyAsync(dynamic jobData) async {
    sendPort = jobData.sendAsyncPort;
    // if (sendPort != null) sendPort.send({'progress': 0.5});
    // do {
    //   await for (var event in _receivePort) {
    //     if (event is Map<String, dynamic> && event['progress'] != null) {
    //       if (sendPort != null) sendPort.send(event);
    //       //yield event['progress'];
    //     } else {
    //       //_result = event;
    //       _receivePort.close();
    //       return event;
    //     }
    //   }
    // } while (true);

  }
Future<void> _transfer() async {
  //if (sendPort != null) sendPort.send(output);

}

  _saveOutputDecode(Map<String, dynamic> output) {
    _outData = output;
    _marked = null;

    // restore image references (problem with sendPort, lose references)
    if (_outData != null) {
      if (_blackLevelNext == null)
        _blackLevel = _outData["blackLevel"];

      //List<Uint8List> images = _outData["images"];
      // List<int> linkList = _outData["linkList"];
      // for (int i = 0; i < images.length; i++) {
      //   images[i] = images[linkList[i]];
      // }
    } else {
      showToast(i18n(context, 'common_loadfile_exception_notloaded'));
      return;
    }
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {});
    });
  }


  _exportFiles(BuildContext context, String fileName, List<Uint8List> data) async {
    createZipFile(fileName, '.' + fileExtension(FileType.PNG), data).then((bytes) async {
      var fileType = FileType.ZIP;
      var value = await saveByteDataToFile(context, bytes,
          'anim_' + DateFormat('yyyyMMdd_HHmmss').format(DateTime.now()) + '.' + fileExtension(fileType));

      if (value != null) showExportedFileDialog(context, fileType: fileType);
    });
  }

  _exportFile(BuildContext context, Uint8List data) async {
    var fileType = getFileType(data);
    var value = await saveByteDataToFile(context, data,
        'anim_export_' + DateFormat('yyyyMMdd_HHmmss').format(DateTime.now()) + '.' + fileExtension(fileType));

    if (value != null) showExportedFileDialog(context, fileType: fileType);
  }
}
