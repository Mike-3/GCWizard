import 'dart:math';
import 'dart:typed_data';

import 'package:gc_wizard/tools/science_and_technology/numeral_bases/logic/numeral_bases.dart';

Uint8List? hexstring2file(String input) {
  if (_isBinary(input)) {
    return _binaryString2bytes(input);
  } else {
    return _hexString2bytes(input);
  }
}

String? file2hexstring(Uint8List input) {
  var sb = StringBuffer();

  for (var byte in input) {
    sb.write(byte.toRadixString(16).padLeft(2, '0'));
  }

  return sb.toString().toUpperCase();
}

Uint8List? _hexString2bytes(String input) {
  if (input.isEmpty) return null;

  var data = <int>[];

  input = input.replaceAll('0x', '');
  String hex = input.toUpperCase().replaceAll(RegExp('[^0-9A-F]'), '');
  if (hex.isEmpty) return null;

  for (var i = 0; i < hex.length; i = i + 2) {
    var valueString = hex.substring(i, min(i + 2, hex.length - 1));
    if (valueString.isNotEmpty) {
      var converted = convertBase(valueString, 16, 10);
      int? value = int.tryParse(converted);
      if (value != null) data.add(value);
    }
  }

  return Uint8List.fromList(data);
}

bool _isBinary(String input) {
  String binary = input.replaceAll(RegExp('[01\\s]'), '');
  return binary.isEmpty;
}

Uint8List? _binaryString2bytes(String input) {
  if (input.isEmpty) return null;

  var data = <int>[];

  String binary = input.replaceAll(RegExp('[^01]'), '');
  if (binary.isEmpty) return null;

  for (var i = 0; i < binary.length; i = i + 8) {
    var valueString = binary.substring(i, min(i + 8, binary.length - 1));
    if (valueString.isNotEmpty) {
      var converted = convertBase(valueString, 2, 10);
      int? value = int.tryParse(converted);
      if (value != null) data.add(value);
    }
  }

  return Uint8List.fromList(data);
}
