import 'dart:typed_data';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:gc_wizard/i18n/app_localizations.dart';
import 'package:gc_wizard/logic/tools/images_and_files/animated_image_morse_code.dart';
import 'package:gc_wizard/logic/tools/images_and_files/video_morse_code.dart';
import 'package:gc_wizard/theme/theme_colors.dart';
import 'package:gc_wizard/widgets/common/base/gcw_button.dart';
import 'package:gc_wizard/widgets/common/base/gcw_iconbutton.dart';
import 'package:gc_wizard/widgets/common/base/gcw_output_text.dart';
import 'package:gc_wizard/widgets/common/base/gcw_slider.dart';
import 'package:gc_wizard/widgets/common/base/gcw_text.dart';
import 'package:gc_wizard/widgets/common/base/gcw_textfield.dart';
import 'package:gc_wizard/widgets/common/base/gcw_toast.dart';
import 'package:gc_wizard/widgets/common/gcw_async_executer1.dart';
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
import 'package:gc_wizard/widgets/utils/file_utils.dart';
import 'package:gc_wizard/widgets/utils/gcw_file.dart' as local;
import 'package:video_player/video_player.dart';



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
  int _startTime = 3;
  int _endTime = 4;
  int _intervallLast;
  double _blackLevel = 50;
  bool _blackLevelOverride = true;
  var _currentSimpleMode = GCWSwitchPosition.left;
  Map<String, dynamic> _outText;
  local.GCWFile _platformFile;
  bool _play = false;
  bool _filtered = true;
  VideoPlayerController _videoController;

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
              _blackLevelOverride = true;
              _startTime = null;
              _endTime = null;
              _videoController = null;
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
                  _play = (_platformFile != null);
                  if (_play) {
                    if (_videoController == null)
                      _videoController = VideoPlayerController.asset(_platformFile.path);
                    if (_videoController != null) _videoController.play();
                  }
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
                  if (_videoController != null) _videoController.pause();
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
          });
        },
      ),
      GCWIntegerSpinner(
        title: 'Start time (s)', //i18n(context, 'visual_cryptography_offset') + ' X',
        value: _startTime == null ? 0 : 0,
        onChanged: (value) {
          setState(() {
            _startTime = value;
          });
        },
      ),
      GCWIntegerSpinner(
        title: 'End time (s)', //i18n(context, 'visual_cryptography_offset') + ' X',
        value: _endTime == null ? 0 : 0,
        onChanged: (value) {
          setState(() {
            _endTime = value;
          });
        },
      ),
      GCWSlider(
          title: i18n(context, 'symbol_replacer_black_level'),
          value: _blackLevel,
          min: 1,
          max: 100,
          onChanged: (value) {
            _marked = null;
            _blackLevel = value;
            _blackLevelOverride = false;
            _analysePlatformFileAsync();
          }
      ),
      GCWButton(
        text: i18n(context, 'common_start'),
        onPressed: () {
          setState(() {
            _analysePlatformFileAsync();
          });
        },
      ),
    ]);
  }

  Widget _buildOutputDecode() {
    if (_outData == null) return null;

    return Column(children: <Widget>[
      _play
          ? VideoPlayer(_videoController)
          :  GCWGallery(
                imageData: _convertImageData(_outData),
                onDoubleTap: (index) {
                  setState(() {
                    if (_marked != null && index < _marked.length) _marked[index] = !_marked[index];
                    _outText = decodeMorseCode(_outData["durations"], _marked);
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
    }
  }

  List<GCWImageViewData> _convertImageData(Map<String, dynamic> _outData) {
    var list = <GCWImageViewData>[];

    if (_outData == null) return list;
    List<Uint8List> images = _outData["images"];
    List<int> durations = _outData["durations"];
    List<double> luminances = _outData["luminance"];
    if (_endTime == null) _endTime = _outData["duration"];

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
        if (!_filtered || i == images.length-1 || _marked[i] != _marked[i+1]) {
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
    if (_platformFile == null) return;
    if (_intervallLast == null || _intervallLast != _intervall)
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return Center(
            child: Container(
              child: GCWAsyncExecuter(
                isolatedFunction: analyseVideoMorseCodeAsync,
                parameter: _buildJobDataDecode(),
                onReady: (data) => _saveOutputDecode(data),
                isOverlay: true,
              ),
              height: 220,
              width: 150,
            ),
          );
        },
      );
    else if (_marked == null)
      _convertImageData(_outData);
  }

  Future<GCWAsyncExecuterParameters> _buildJobDataDecode() async {
    return GCWAsyncExecuterParameters(
        VideoMorseCodeJobData(_platformFile.path, _intervall,
          startTime: _startTime == null ? null : _startTime * 1000,
          endTime: _endTime == null ? null : _endTime * 1000,
          topLeft: Point<double>(0.0, 0.0), //(0.2, 0.2)

          bottomRight: Point<double>(1.0, 1.0), //(0.8, 0.8)
        ));
  }


  _saveOutputDecode(Map<String, dynamic> output) {
    _outData = output;
    _marked = null;

    if (_outData != null) {
      if (_blackLevelOverride)
        _blackLevel = _outData["blackLevel"];
    } else {
      showToast(i18n(context, 'common_loadfile_exception_notloaded'));
      return;
    }

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
