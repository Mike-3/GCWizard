import 'dart:typed_data';
import 'dart:math';
import 'package:gc_wizard/application/i18n/logic/app_localizations.dart';
import 'package:gc_wizard/application/theme/theme_colors.dart';
import 'package:gc_wizard/common_widgets/async_executer/gcw_async_executer.dart';
import 'package:gc_wizard/common_widgets/async_executer/gcw_async_executer_parameters.dart';
import 'package:gc_wizard/common_widgets/buttons/gcw_button.dart';
import 'package:gc_wizard/common_widgets/buttons/gcw_iconbutton.dart';
import 'package:gc_wizard/common_widgets/dialogs/gcw_exported_file_dialog.dart';
import 'package:gc_wizard/common_widgets/gcw_openfile.dart';
import 'package:gc_wizard/common_widgets/gcw_slider.dart';
import 'package:gc_wizard/common_widgets/gcw_snackbar.dart';
import 'package:gc_wizard/common_widgets/image_viewers/gcw_gallery.dart';
import 'package:gc_wizard/common_widgets/image_viewers/gcw_imageview.dart';
import 'package:gc_wizard/common_widgets/outputs/gcw_default_output.dart';
import 'package:gc_wizard/common_widgets/outputs/gcw_output.dart';
import 'package:gc_wizard/common_widgets/outputs/gcw_output_text.dart';
import 'package:gc_wizard/common_widgets/spinners/gcw_integer_spinner.dart';
import 'package:gc_wizard/common_widgets/switches/gcw_twooptions_switch.dart';
import 'package:gc_wizard/tools/images_and_files/animated_image_morse_code/logic/animated_image_morse_code.dart';
import 'package:gc_wizard/tools/images_and_files/video_morse_code/logic/video_morse_code.dart';
import 'package:gc_wizard/utils/file_utils/file_utils.dart';
import 'package:gc_wizard/utils/file_utils/gcw_file.dart';
import 'package:gc_wizard/utils/ui_dependent_utils/file_widget_utils.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';



class VideoMorseCode extends StatefulWidget {
  final GCWFile? platformFile;

  const VideoMorseCode({Key? key, this.platformFile}) : super(key: key);

  @override
  VideoMorseCodeState createState() => VideoMorseCodeState();
}

class VideoMorseCodeState extends State<VideoMorseCode> {
  VideoMorseCodeOutput? _outData;
  var _marked = <bool>[];
  int _intervall = 50;
  int _startTime = 3;
  int _endTime = 4;
  int? _intervallLast;
  double _blackLevel = 50;
  bool _blackLevelOverride = true;
  var _currentSimpleMode = GCWSwitchPosition.left;
  MorseCodeOutput? _outText;
  late GCWFile? _platformFile;
  bool _play = false;
  bool _filtered = true;
  late VideoPlayerController? _videoController;

  static var allowedExtensions = [FileType.MP4, FileType.WEBM];

  String _currentInput = '';
  int _currentDotDuration = 400;
  late TextEditingController _currentDotDurationController;
  late TextEditingController _currentInputController;

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
            showSnackBar(i18n(context, 'common_loadfile_exception_notloaded'), context);
            return;
          }

          setState(() {
            _platformFile = _file;
            _outData = null;
            _marked = [];
            _blackLevel = 50;
            _blackLevelOverride = true;
            _startTime = -1;
            _endTime = -1;
            _videoController = null;
            _analysePlatformFileAsync();
          });
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
          trailing: Row(children: <Widget>[
            GCWIconButton(
              icon: _filtered ? Icons.filter_alt : Icons.filter_alt_outlined,
              size: IconButtonSize.SMALL,
              iconColor: _outData != null ? null : themeColors().inactive(),
              onPressed: () {
                setState(() {
                  _filtered = !_filtered;
                });
              },
            ),
            GCWIconButton(
              icon: Icons.play_arrow,
              size: IconButtonSize.SMALL,
              iconColor: _outData != null && !_play ? null : themeColors().inactive(),
              onPressed: () {
                setState(() {
                  _play = (_platformFile?.path != null);
                  if (_play) {
                    _videoController ??= VideoPlayerController.asset(_platformFile!.path!);
                    _videoController?.play();
                  }
                });
              },
            ),
            GCWIconButton(
              icon: Icons.stop,
              size: IconButtonSize.SMALL,
              iconColor: _play ? null : themeColors().inactive(),
              onPressed: () {
                setState(() {
                  _play = false;
                  _videoController?.pause();
                });
              },
            ),
            GCWIconButton(
              icon: Icons.save,
              size: IconButtonSize.SMALL,
              iconColor: _outData == null ? themeColors().inactive() : null,
              onPressed: () {
                _outData?.images == null ? null : _exportFiles(context, _platformFile?.name ?? "", _outData!.images);
              },
            )
          ]),
          child: _buildOutputDecode())
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
        value: max(0, _startTime),
        onChanged: (value) {
          setState(() {
            _startTime = value;
          });
        },
      ),
      GCWIntegerSpinner(
        title: 'End time (s)', //i18n(context, 'visual_cryptography_offset') + ' X',
        value: max(0, _endTime),
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
            _marked = [];
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
    if (_outData == null) return Container();

    return Column(children: <Widget>[
      _play
          ? VideoPlayer(_videoController!)
          :  GCWGallery(
                imageData: _convertImageData(_outData),
                onDoubleTap: (index) {
                  setState(() {
                    if (_marked.isNotEmpty && index < _marked.length) _marked[index] = !_marked[index];
                    _outText = decodeMorseCode(_outData!.durations, _marked);
                  });
                },
              ),
      _buildDecodeOutput(),
    ]);
  }

  Widget _buildDecodeOutput() {
    return Column(children: <Widget>[
      GCWDefaultOutput(child: GCWOutputText(text: _outText?.text == null ? "" : _outText!.text)),
      GCWOutput(
          title: i18n(context, 'animated_image_morse_code_morse_code'),
          child: GCWOutputText(text: _outText?.morseCode == null ? "" : _outText!.morseCode)),
    ]);
  }

  void _initMarkedList(List<Uint8List> images, List<double> luminances) {
    if (_marked.length != images.length) {
      _marked = List.filled(images.length, false);

      for (var i = 0; i < luminances.length; i++) {
        _marked[i] = luminances[i] > _blackLevel;
      }
    }
  }

  List<GCWImageViewData> _convertImageData(VideoMorseCodeOutput? _outData) {
    var list = <GCWImageViewData>[];

    if (_outData == null) return list;
    List<Uint8List> images = _outData.images;
    List<int> durations = _outData.durations;
    List<double> luminances = _outData.luminances;
    if (_endTime <= 0) _endTime = _outData.duration ?? 0;

    // if (images != null) {
      var imageCount = images.length;
      _initMarkedList(images, luminances);
      var _duration = 0;

      for (var i = 0; i < images.length; i++) {
        String description = (i + 1).toString() + '/$imageCount';
        if (i < durations.length) {
          _duration += durations[i];
          description += ': ' + _duration.toString() + ' ms ' + luminances[i].toString();
        }
        if (!_filtered || i == images.length-1 || _marked[i] != _marked[i+1]) {
          list.add(GCWImageViewData(GCWFile(bytes: images[i]), description: description, marked: _marked[i]));
          _duration = 0;
        }
      }
      _outText = decodeMorseCode(durations, _marked);

      // _outText = Map<String, dynamic>();
      // _outText.addAll({"text": _outData["minBrightness"].toString() + '/ ' + _outData["maxBrightness"].toString()});
      // _outText.addAll({"morse": _outData["threshold"].toString()});
    // }
    return list;
  }


  void _analysePlatformFileAsync() async {
    if (_platformFile == null) return;
    if (_intervallLast == null || _intervallLast != _intervall) {
      await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return Center(
            child: SizedBox(
              height: GCW_ASYNC_EXECUTER_INDICATOR_HEIGHT,
              width: GCW_ASYNC_EXECUTER_INDICATOR_WIDTH,
              child: GCWAsyncExecuter(
                isolatedFunction: analyseVideoMorseCodeAsync,
                parameter: _buildJobDataDecode,
                onReady: (data) => _saveOutputDecode(data),
                isOverlay: true,
              ),
            ),
          );
        },
      );
    } else if (_marked.isEmpty) {
      _convertImageData(_outData);
    }
  }

  Future<GCWAsyncExecuterParameters> _buildJobDataDecode() async {
    return GCWAsyncExecuterParameters(
        VideoMorseCodeJobData(_platformFile!.path!, _intervall,
          startTime: _startTime * 1000,
          endTime: _endTime * 1000,
          topLeft: const Point<double>(0.0, 0.0), //(0.2, 0.2)

          bottomRight: const Point<double>(1.0, 1.0), //(0.8, 0.8)
        ));
  }


  void _saveOutputDecode(VideoMorseCodeOutput? output) {
    _outData = output;
    _marked = [];

    if (_outData != null) {
      if (_blackLevelOverride) _blackLevel = _outData!.blackLevel;
    } else {
      showSnackBar(i18n(context, 'common_loadfile_exception_notloaded'), context);
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {});
    });
  }


  Future<void> _exportFiles(BuildContext context, String fileName, List<Uint8List> data) async {
    createZipFile(fileName, '.' + fileExtension(FileType.PNG), data).then((bytes) async {
      await saveByteDataToFile(context, bytes, buildFileNameWithDate('anim_', FileType.ZIP)).then((value) {
        if (value) showExportedFileDialog(context);
      });
    });
  }

  Future<void> _exportFile(BuildContext context, Uint8List data) async {
    var fileType = getFileType(data);
    await saveByteDataToFile(context, data, buildFileNameWithDate('anim_export_', fileType)).then((value) {
      var content = fileClass(fileType) == FileClass.IMAGE ? imageContent(context, data) : null;
      if (value) showExportedFileDialog(context, contentWidget: content);
    });
  }
}
