import 'dart:io' as io;
import 'dart:typed_data';
import "package:flutter_test/flutter_test.dart";
import 'package:gc_wizard/tools/images_and_files/jabcode/logic/jabcode.dart';
import 'package:gc_wizard/utils/file_utils/file_utils.dart';
import 'package:tuple/tuple.dart';

var testDirPath = 'test/tools/images_and_files/jabcode/';

void main() {

  group("jabcode.scanBytes:", () {
    var files = readSamples();
    List<Map<String, Object?>> _inputsToExpected = [
      {'input' : files[0], 'expectedOutput' : const Tuple2<String, String?>('Mike', null)},
    ];

    for (var elem in _inputsToExpected) {
      test('input: ${elem['input']}', () async {
        Uint8List content = _getFileData(elem['input'] as String);
        var _actual = await scanBytes(content);
        expect(_actual, elem['expectedOutput']);
      });
    }
  });

}


List<String> readSamples() {
  io.Directory dir = io.Directory(testDirPath);
  Set<String> allowedExtensions = {'.png'};
  var files = dir.listSync(recursive: true).where((file) => (allowedExtensions.contains(getFileExtension(file.path))));
  return files.map((e) => e.uri.path).toList();
}

Uint8List _getFileData(String path) {
  io.File file = io.File(path);
  return file.readAsBytesSync();
}
