import 'dart:typed_data';

import 'package:gc_wizard/logic/tools/images_and_files/stegano_dot_net.dart';
import 'package:gc_wizard/plugins/flutter_steganography/decoder.dart';
import 'package:gc_wizard/plugins/flutter_steganography/encoder.dart';
import 'package:gc_wizard/plugins/flutter_steganography/requests/decode_request.dart';
import 'package:gc_wizard/plugins/flutter_steganography/requests/encode_request.dart';
import 'package:gc_wizard/widgets/utils/gcw_file.dart' as local;

const int MAX_LENGTH = 5000;

enum SteganoSource{
  FlutterStegano,
  SteganoDotNet,
}

class SteganoOutput {
  SteganoSource source;
  String text;
  List<local.GCWFile> files;

  SteganoOutput(SteganoSource source, String text, List<local.GCWFile> files) {
    this.source = source;
    this.text = text;
    this.files = files;
  }
}

Future<Uint8List> encodeStegano(local.GCWFile file, String message, String key, String filename) async {
  Uint8List data = file.bytes;
  // the key is use to encrypt your message with AES256 algorithm
  EncodeRequest request = EncodeRequest(data, message, key: key, filename: filename);
  Uint8List response = await encodeMessageIntoImageAsync(request);
  return response;
}

Future<List<SteganoOutput>> decodeAllSteganoVariants(local.GCWFile file, String key) async {
  var result = <SteganoOutput>[];
  SteganoOutput steganoOutput;

  try {
    steganoOutput = await decodeStegano(file, key);
  } catch (e) {
    steganoOutput = null;
  }
  if (steganoOutput != null)
    result.add(steganoOutput);

  steganoOutput = await decodeSteganoDotNet(file);
  if (steganoOutput != null)
    result.add(steganoOutput);

  if (result == null || result.length == 0)
    throw Exception('abnormal_length_nothing_to_decode');

  return Future.value(result);
}

Future<SteganoOutput> decodeStegano(local.GCWFile file, String key) async {
  Uint8List data = file.bytes;
  // the key is use to decrypt your encrypted message with AES256 algorithm
  DecodeRequest request = DecodeRequest(data, key: key);
  String response = await decodeMessageFromImageAsync(request);
  if (response != null && response.length > MAX_LENGTH) {
    throw Exception('abnormal_length_nothing_to_decode');
  }
  if (response != null)
    return Future.value(SteganoOutput(SteganoSource.FlutterStegano, response, null));
}
