import 'dart:io' as io;
import 'dart:typed_data';
import "package:flutter_test/flutter_test.dart";
import 'package:gc_wizard/widgets/utils/file_utils.dart';
import 'package:gc_wizard/logic/tools/images_and_files/jab_code/jabcode.dart';
import 'package:tuple/tuple.dart';

var testDirPath = 'test/resources/jabcode/';

void main() {

  group("jabcode.scanBytes:", () {
    var files = readSamples();
    List<Map<String, dynamic>> _inputsToExpected = [
      {'input' : files[0], 'expectedOutput' : Tuple2<String, String>('Mike', null)},
    ];

    _inputsToExpected.forEach((elem) {
      test('input: ${elem['input']}', () {
        Uint8List content = _getFileData(elem['input']);
        var _actual = scanBytes(content);
        expect(_actual, elem['expectedOutput']);
      });
    });
  });

}


List<String> readSamples() {
  io.Directory dir = new io.Directory(testDirPath);
  Set<String> allowedExtensions = {'.png'};
  var files = dir.listSync(recursive: true).where((file) => (allowedExtensions.contains(getFileExtension(file.path))));
  return files.map((e) => e.uri.path).toList();
}

Uint8List _getFileData(String path) {
  io.File file = io.File(path);
  return file.readAsBytesSync();
}
