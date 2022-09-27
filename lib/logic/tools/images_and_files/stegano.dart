import 'dart:typed_data';

import 'package:gc_wizard/logic/tools/images_and_files/stegano2.dart';
import 'package:gc_wizard/plugins/flutter_steganography/decoder.dart';
import 'package:gc_wizard/plugins/flutter_steganography/encoder.dart';
import 'package:gc_wizard/plugins/flutter_steganography/requests/decode_request.dart';
import 'package:gc_wizard/plugins/flutter_steganography/requests/encode_request.dart';
import 'package:gc_wizard/widgets/utils/gcw_file.dart' as local;

const int MAX_LENGTH = 5000;

Future<Uint8List> encodeStegano(local.GCWFile file, String message, String key, String filename) async {
  Uint8List data = file.bytes;
  // the key is use to encrypt your message with AES256 algorithm
  EncodeRequest request = EncodeRequest(data, message, key: key, filename: filename);
  Uint8List response = await encodeMessageIntoImageAsync(request);
  return response;
}

Future<String> decodeAllSteganoVariants(local.GCWFile file, String key) async {
  String result;
  String result1;
  try {
    result1 = await decodeStegano(file, key);
  } catch (e) {
    result1 = null;
  }
  var result2 = decodeSteganoNet(file);

  if (result1 != null) {
    if (result != null) result += "\n\n";
    result += result1;
  }

  if (result2 != null) {
    if (result != null) result += "\n\n";
    result += result2;
  }

  if (result == null)
    throw Exception('abnormal_length_nothing_to_decode');

  return Future.value(result);
}

Future<String> decodeStegano(local.GCWFile file, String key) async {
  Uint8List data = file.bytes;
  // the key is use to decrypt your encrypted message with AES256 algorithm
  DecodeRequest request = DecodeRequest(data, key: key);
  String response = await decodeMessageFromImageAsync(request);
  if (response != null && response.length > MAX_LENGTH) {
    throw Exception('abnormal_length_nothing_to_decode');
  }
  return response;
}
