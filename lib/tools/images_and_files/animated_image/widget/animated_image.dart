import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:gc_wizard/application/i18n/logic/app_localizations.dart';
import 'package:gc_wizard/application/navigation/no_animation_material_page_route.dart';
import 'package:gc_wizard/application/theme/theme.dart';
import 'package:gc_wizard/application/theme/theme_colors.dart';
import 'package:gc_wizard/application/tools/widget/gcw_tool.dart';
import 'package:gc_wizard/common_widgets/async_executer/gcw_async_executer.dart';
import 'package:gc_wizard/common_widgets/async_executer/gcw_async_executer_parameters.dart';
import 'package:gc_wizard/common_widgets/buttons/gcw_iconbutton.dart';
import 'package:gc_wizard/common_widgets/buttons/gcw_submit_button.dart';
import 'package:gc_wizard/common_widgets/dialogs/gcw_exported_file_dialog.dart';
import 'package:gc_wizard/common_widgets/dividers/gcw_divider.dart';
import 'package:gc_wizard/common_widgets/dividers/gcw_text_divider.dart';
import 'package:gc_wizard/common_widgets/gcw_openfile.dart';
import 'package:gc_wizard/common_widgets/gcw_snackbar.dart';
import 'package:gc_wizard/common_widgets/gcw_text.dart';
import 'package:gc_wizard/common_widgets/image_viewers/gcw_gallery.dart';
import 'package:gc_wizard/common_widgets/image_viewers/gcw_imageview.dart';
import 'package:gc_wizard/common_widgets/outputs/gcw_columned_multiline_output.dart';
import 'package:gc_wizard/common_widgets/outputs/gcw_default_output.dart';
import 'package:gc_wizard/common_widgets/outputs/gcw_output.dart';
import 'package:gc_wizard/common_widgets/switches/gcw_twooptions_switch.dart';
import 'package:gc_wizard/common_widgets/textfields/gcw_integer_textfield.dart';
import 'package:gc_wizard/tools/images_and_files/animated_image/logic/animated_image.dart';
import 'package:gc_wizard/tools/images_and_files/animated_image/logic/animated_image_encode.dart';
import 'package:gc_wizard/utils/complex_return_types.dart';
import 'package:gc_wizard/utils/file_utils/file_utils.dart';
import 'package:gc_wizard/utils/file_utils/gcw_file.dart';
import 'package:gc_wizard/utils/ui_dependent_utils/file_widget_utils.dart';

final List<FileType> ANIMATED_IMAGE_ALLOWED_FILETYPES = [FileType.GIF, FileType.PNG, FileType.WEBP];

class AnimatedImage extends StatefulWidget {
  final GCWFile? file;

  const AnimatedImage({super.key, this.file});

  @override
  _AnimatedImageState createState() => _AnimatedImageState();
}

class _AnimatedImageState extends State<AnimatedImage> {
  AnimatedImageOutput? _outData;
  GCWFile? _file;
  bool _play = false;
  var _currentMode = GCWSwitchPosition.right;
  //final List<Uint8List> _encodeImages = [];
  final List<MapEntry<int, int>> _encodeDurations = []; //image index, duration
  final List<List<TextEditingController?>> _textEditingControllerArray = [];
  Uint8List? _outDataEncode;
  List<GCWImageViewData> _encodeImageData = [];

  @override
  void dispose() {
    for(var y = 0; y < _textEditingControllerArray.length; y++) {
      for (var x = 0; x < _textEditingControllerArray[y].length; x++) {
        _textEditingControllerArray[y][x]?.dispose();
      }
    }
    _textEditingControllerArray.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        GCWTwoOptionsSwitch(
          value: _currentMode,
          onChanged: (value) {
            setState(() {
              _currentMode = value;
            });
          },
        ),
        _currentMode == GCWSwitchPosition.right ? _buildDecodeWidget(context) : buildEncodeWidget(context)
      ],
    );
  }

  Widget _buildDecodeWidget(BuildContext context) {
    if (widget.file != null) {
      _file = widget.file;
      _analysePlatformFileAsync();
    }

    return Column(children: <Widget>[
      GCWOpenFile(
        supportedFileTypes: ANIMATED_IMAGE_ALLOWED_FILETYPES,
        suppressGallery: false,
        onLoaded: (GCWFile? value) {
          if (value == null) {
            showSnackBar(i18n(context, 'common_loadfile_exception_notloaded'), context);
            return;
          }

          setState(() {
            _file = value;
            _analysePlatformFileAsync();
          });
        },
      ),
      GCWDefaultOutput(
          trailing: Row(children: <Widget>[
            GCWIconButton(
              icon: Icons.play_arrow,
              size: IconButtonSize.SMALL,
              iconColor: _outData != null && !_play ? null : themeColors().inactive(),
              onPressed: () {
                setState(() {
                  _play = (_outData != null);
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
                });
              },
            ),
            GCWIconButton(
              icon: Icons.save,
              size: IconButtonSize.SMALL,
              iconColor: _outData == null ? themeColors().inactive() : null,
              onPressed: () {
                if (_outData != null && _file?.name != null) _exportFiles(context, _file!.name!, _outData!.images);
              },
            )
          ]),
          child: _buildOutput())
    ]);
  }

  Widget _buildOutput() {
    if (_outData == null) return Container();

    var durations = <List<Object>>[];
    if (_outData!.durations.length > 1) {
      var counter = 0;
      var total = 0;

      durations.addAll([
        [i18n(context, 'animated_image_table_index'), i18n(context, 'animated_image_table_duration')]
      ]);
      for (var value in _outData!.durations) {
        counter++;
        total += value;
        durations.addAll([
          [counter, value]
        ]);
      }
      durations.addAll([
        [i18n(context, 'common_total'), total]
      ]);
    }

    return Column(children: <Widget>[
      _play
          ? (_file?.bytes == null)
              ? Container()
              : Image.memory(_file!.bytes)
          : GCWGallery(imageData: _convertImageData(_outData!.images, _outData!.durations)),
      _buildDurationOutput(durations)
    ]);
  }

  Widget _buildDurationOutput(List<List<Object>> durations) {
    return Column(children: <Widget>[
      const GCWDivider(),
      GCWOutput(
          child: GCWColumnedMultilineOutput(data: durations, flexValues: const [1, 2], hasHeader: true, copyAll: true)),
    ]);
  }

  List<GCWImageViewData> _convertImageData(List<Uint8List> images, List<int> durations) {
    var list = <GCWImageViewData>[];

    var imageCount = images.length;
    for (var i = 0; i < images.length; i++) {
      String description = (i + 1).toString() + '/$imageCount';
      if (i < durations.length) {
        description += ': ' + durations[i].toString() + ' ms';
      }
      list.add(GCWImageViewData(GCWFile(bytes: images[i]), description: description));
    }
    return list;
  }

  List<GCWImageViewData> _updateEncodeImageData(Uint8List? image) {
    var list = <GCWImageViewData>[];

    if (image != null) {
      list.add(GCWImageViewData(GCWFile(bytes: image), description: ''));
    }

    var imageCount = _encodeImageData.length;
    for (var i = 0; i < _encodeImageData.length; i++) {
      String description = (i + 1).toString() + '/$imageCount';
      list.add(GCWImageViewData(GCWFile(bytes: _encodeImageData[i].file.bytes),
          description: description,
          marked: _encodeImageData[i].marked));
    }
    _encodeImageData = list;
    return list;
  }

  Future<void> _analysePlatformFileAsync() async {
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Center(
          child: SizedBox(
            height: GCW_ASYNC_EXECUTER_INDICATOR_HEIGHT,
            width: GCW_ASYNC_EXECUTER_INDICATOR_WIDTH,
            child: GCWAsyncExecuter<AnimatedImageOutput?>(
              isolatedFunction: analyseImageAsync,
              parameter: _buildJobData,
              onReady: (data) => _showOutput(data),
              isOverlay: true,
            ),
          ),
        );
      },
    );
  }

  Future<GCWAsyncExecuterParameters?> _buildJobData() async {
    if (_file == null) return null;
    return GCWAsyncExecuterParameters(_file!.bytes);
  }

  void _showOutput(AnimatedImageOutput? output) {
    _outData = output;

    // restore image references (problem with sendPort, lose references)
    if (_outData != null) {
      var linkList = _outData!.linkList;
      for (int i = 0; i < _outData!.images.length; i++) {
        _outData!.images[i] = _outData!.images[linkList[i]];
      }
    } else {
      showSnackBar(i18n(context, 'common_loadfile_exception_notloaded'), context);
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {});
    });
  }

  Widget buildEncodeWidget(BuildContext context) {
    return Column(children: <Widget>[
      GCWOpenFile(
        supportedFileTypes: SUPPORTED_IMAGE_TYPES,
        suppressGallery: false,
        onLoaded: (GCWFile? value) {
          if (value == null) {
            showSnackBar(i18n(context, 'common_loadfile_exception_notloaded'), context);
            return;
          }
          setState(() {
            _updateEncodeImageData(value.bytes);
          });
        },
      ),
      GCWTextDivider(
        text: '',
        trailing: Row(children: <Widget>[
          GCWIconButton(
            icon: Icons.delete,
            size: IconButtonSize.SMALL,
            iconColor: _outData != null && !_play ? null : themeColors().inactive(),
            onPressed: () {
              setState(() {
                _encodeImageData.removeWhere((data) => data.marked ?? false);
                _updateEncodeImageData(null);
              });
            },
          ),
        ]),
      ),
      GCWGallery(imageData: _encodeImageData),
      const GCWDivider(),
      _buildEncodeTable(),
      _buildEncodeSubmitButton(),
      _buildOutputEncode()
    ]);
  }

  Widget _buildEncodeTable() {
    var rows = <TableRow>[];
    var headerStyle = gcwTextStyle().copyWith(fontWeight: FontWeight.bold);
    rows.add(TableRow(children: [
      GCWText(text: i18n(context, 'common_index'), style: headerStyle),
      GCWText(text: 'Duration' + ' (ms)', style: headerStyle),
      Container()])
    );
    for (var i = 0; i < _encodeDurations.length + 1; i++) {
      var rowColor = i.isOdd ? themeColors().outputListOddRows() : themeColors().primaryBackground();
      rows.add(TableRow(
        decoration: BoxDecoration(color: rowColor),
        children: [
          GCWIntegerTextField(
            min: 0,
            controller: _getTextEditingController(i, 0,
                i < _encodeDurations.length ? _encodeDurations[i].key.toString(): ''),
            onChanged: (IntegerText ret) {
              if (i < _encodeDurations.length) {
                _encodeDurations[i] = MapEntry<int, int>(ret.value, _encodeDurations[i].value);
              } else {
                setState(() {
                  _encodeDurations.add(MapEntry<int, int>(ret.value, 0));
                });
              }
            },
          ),
          GCWIntegerTextField(
            min: 0,
            controller: _getTextEditingController(i, 1,
                i < _encodeDurations.length ? _encodeDurations[i].value.toString(): ''),
            onChanged: (IntegerText ret) {
              if (i < _encodeDurations.length) {
                _encodeDurations[i] = MapEntry<int, int>(_encodeDurations[i].key, ret.value);
              } else {
                setState(() {
                  _encodeDurations.add(MapEntry<int, int>(0, ret.value));
                });
              }
            },
          ),
          GCWIconButton(
            icon: Icons.remove,
            onPressed: () {
              setState(() {
                _encodeDurations.removeAt(i);
              });
            },
          )
      ])
      );
    }
    return Row(children: [
      Expanded(flex: 1, child: Container()),
      Expanded(flex: 3, child:
        Table(
          border: const TableBorder.symmetric(outside: BorderSide(width: 1, color: Colors.transparent)),
          columnWidths: {0: FlexColumnWidth(50), 1: FlexColumnWidth(50), 2: IntrinsicColumnWidth()},
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          children: rows
        ),
      ),
      Expanded(flex: 1, child: Container()),
    ]);
  }

  TextEditingController? _getTextEditingController(int rowIndex, int columnIndex, String text) {
    while (_textEditingControllerArray.length <= rowIndex) {
      _textEditingControllerArray.add(<TextEditingController?>[]);
    }
    while (_textEditingControllerArray[rowIndex].length <= columnIndex) {
      _textEditingControllerArray[rowIndex].add(null);
    }
    if (_textEditingControllerArray[rowIndex][columnIndex] == null) {
      _textEditingControllerArray[rowIndex][columnIndex] = TextEditingController();
    }
    _textEditingControllerArray[rowIndex][columnIndex]!.text = text;

    return _textEditingControllerArray[rowIndex][columnIndex];
  }

  Widget _buildEncodeSubmitButton() {
    return GCWSubmitButton(onPressed: () async {
      await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return Center(
            child: SizedBox(
              height: GCW_ASYNC_EXECUTER_INDICATOR_HEIGHT,
              width: GCW_ASYNC_EXECUTER_INDICATOR_WIDTH,
              child: GCWAsyncExecuter<Uint8List?>(
                isolatedFunction: createImageAsync,
                parameter: _buildJobDataEncode,
                onReady: (data) => _saveOutputEncode(data),
                isOverlay: true,
              ),
            ),
          );
        },
      );
    });
  }

  Future<GCWAsyncExecuterParameters?> _buildJobDataEncode() async {
    if (_encodeImageData.isEmpty) return null;
    return GCWAsyncExecuterParameters(
        AnimatedImageJobData(
            images: _encodeImageData.map((data) => data.file.bytes).toList(),
            durations: _encodeDurations,
        )
    );
  }

  void _saveOutputEncode(Uint8List? output) {
    _outDataEncode = output;
try {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    setState(() {});
  });
} catch (e) {}

  }

  Widget _buildOutputEncode() {
    if (_outDataEncode == null) return Container();

    return GCWDefaultOutput(child:
      GCWImageView(
        imageData: GCWImageViewData(GCWFile(bytes: _outDataEncode ?? Uint8List(0))),
        toolBarRight: true,
        fileName: buildFileNameWithDate('img1_', null),
      )
    );
  }

  Future<void> _exportFiles(BuildContext context, String fileName, List<Uint8List> data) async {
    createZipFile(fileName, '.' + fileExtension(FileType.PNG), data).then((bytes) async {
      await saveByteDataToFile(context, bytes, buildFileNameWithDate('anim_', FileType.ZIP)).then((value) {
        if (value) showExportedFileDialog(context);
      });
    });
  }
}

void openInAnimatedImage(BuildContext context, GCWFile file) {
  Navigator.push(
      context,
      NoAnimationMaterialPageRoute<GCWTool>(
          builder: (context) => GCWTool(
              tool: AnimatedImage(file: file), toolName: i18n(context, 'animated_image_title'), id: 'animated_image')));
}
