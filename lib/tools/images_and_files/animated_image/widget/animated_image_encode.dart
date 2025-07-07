// part of 'package:gc_wizard/tools/images_and_files/animated_image/widget/animated_image.dart';
//
//
//   Widget buildEncodeWidget(BuildContext context) {
//     return Column(children: <Widget>[
//       GCWOpenFile(
//         supportedFileTypes: SUPPORTED_IMAGE_TYPES,
//         suppressGallery: false,
//         onLoaded: (GCWFile? value) {
//           if (value == null) {
//             showSnackBar(i18n(context, 'common_loadfile_exception_notloaded'), context);
//             return;
//           }
//
//           setState(() {
//             // _file = value;
//             // _analysePlatformFileAsync();
//           });
//         },
//       ),
//       GCWDefaultOutput(
//           trailing: Row(children: <Widget>[
//             GCWIconButton(
//               icon: Icons.play_arrow,
//               size: IconButtonSize.SMALL,
//               iconColor: _outData != null && !_play ? null : themeColors().inactive(),
//               onPressed: () {
//                 setState(() {
//                   _play = (_outData != null);
//                 });
//               },
//             ),
//             GCWIconButton(
//               icon: Icons.stop,
//               size: IconButtonSize.SMALL,
//               iconColor: _play ? null : themeColors().inactive(),
//               onPressed: () {
//                 setState(() {
//                   _play = false;
//                 });
//               },
//             ),
//             GCWIconButton(
//               icon: Icons.save,
//               size: IconButtonSize.SMALL,
//               iconColor: _outData == null ? themeColors().inactive() : null,
//               onPressed: () {
//                 if (_outData != null && _file?.name != null) _exportFiles(context, _file!.name!, _outData!.images);
//               },
//             )
//           ]),
//           child: _buildOutput())
//     ]);
//   }
//
//   Widget _buildOutput() {
//     if (_outData == null) return Container();
//
//     var durations = <List<Object>>[];
//     if (_outData!.durations.length > 1) {
//       var counter = 0;
//       var total = 0;
//
//       durations.addAll([
//         [i18n(context, 'animated_image_table_index'), i18n(context, 'animated_image_table_duration')]
//       ]);
//       for (var value in _outData!.durations) {
//         counter++;
//         total += value;
//         durations.addAll([
//           [counter, value]
//         ]);
//       }
//       durations.addAll([
//         [i18n(context, 'common_total'), total]
//       ]);
//     }
//
//     return Column(children: <Widget>[
//       _play
//           ? (_file?.bytes == null)
//               ? Container()
//               : Image.memory(_file!.bytes)
//           : GCWGallery(imageData: _convertImageData(_outData!.images, _outData!.durations)),
//       _buildDurationOutput(durations)
//     ]);
//   }
//
//   Widget _buildDurationOutput(List<List<Object>> durations) {
//     return Column(children: <Widget>[
//       const GCWDivider(),
//       GCWOutput(
//           child: GCWColumnedMultilineOutput(data: durations, flexValues: const [1, 2], hasHeader: true, copyAll: true)),
//     ]);
//   }
//
//   List<GCWImageViewData> _convertImageData(List<Uint8List> images, List<int> durations) {
//     var list = <GCWImageViewData>[];
//
//     var imageCount = images.length;
//     for (var i = 0; i < images.length; i++) {
//       String description = (i + 1).toString() + '/$imageCount';
//       if (i < durations.length) {
//         description += ': ' + durations[i].toString() + ' ms';
//       }
//       list.add(GCWImageViewData(GCWFile(bytes: images[i]), description: description));
//     }
//     return list;
//   }
//
//   Future<void> _analysePlatformFileAsync() async {
//     await showDialog<bool>(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) {
//         return Center(
//           child: SizedBox(
//             height: GCW_ASYNC_EXECUTER_INDICATOR_HEIGHT,
//             width: GCW_ASYNC_EXECUTER_INDICATOR_WIDTH,
//             child: GCWAsyncExecuter<AnimatedImageOutput?>(
//               isolatedFunction: analyseImageAsync,
//               parameter: _buildJobData,
//               onReady: (data) => _showOutput(data),
//               isOverlay: true,
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   Future<GCWAsyncExecuterParameters?> _buildJobData() async {
//     if (_file == null) return null;
//     return GCWAsyncExecuterParameters(_file!.bytes);
//   }
//
//   void _showOutput(AnimatedImageOutput? output) {
//     _outData = output;
//
//     // restore image references (problem with sendPort, lose references)
//     if (_outData != null) {
//       var linkList = _outData!.linkList;
//       for (int i = 0; i < _outData!.images.length; i++) {
//         _outData!.images[i] = _outData!.images[linkList[i]];
//       }
//     } else {
//       showSnackBar(i18n(context, 'common_loadfile_exception_notloaded'), context);
//       return;
//     }
//
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       setState(() {});
//     });
//   }
//
//   Future<void> _exportFiles(BuildContext context, String fileName, List<Uint8List> data) async {
//     createZipFile(fileName, '.' + fileExtension(FileType.PNG), data).then((bytes) async {
//       await saveByteDataToFile(context, bytes, buildFileNameWithDate('anim_', FileType.ZIP)).then((value) {
//         if (value) showExportedFileDialog(context);
//       });
//     });
//   }
// }
//
// void openInAnimatedImage(BuildContext context, GCWFile file) {
//   Navigator.push(
//       context,
//       NoAnimationMaterialPageRoute<GCWTool>(
//           builder: (context) => GCWTool(
//               tool: AnimatedImage(file: file), toolName: i18n(context, 'animated_image_title'), id: 'animated_image')));
// }
