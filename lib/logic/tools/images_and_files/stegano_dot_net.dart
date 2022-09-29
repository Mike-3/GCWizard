// source: https://github.com/sassman/stegano.kde4
// Stegano.NET logic

import 'dart:convert';
import 'dart:typed_data';
import 'package:gc_wizard/logic/tools/images_and_files/hidden_data.dart';
import 'package:gc_wizard/logic/tools/images_and_files/stegano.dart';
import 'package:gc_wizard/widgets/utils/file_utils.dart';
import 'package:gc_wizard/widgets/utils/gcw_file.dart';
import 'package:image/image.dart' as Image;
import 'package:gc_wizard/widgets/utils/gcw_file.dart' as local;

Future<SteganoOutput> decodeSteganoDotNet(local.GCWFile sourceFile) {
  if (sourceFile == null)
    return null;
  return decodeSteganoDotNetData(Image.decodeImage(sourceFile.bytes));
}

Future<SteganoOutput> decodeSteganoDotNetData(Image.Image bmpData) async {
  if (bmpData == null)
    return null;

  const colorChannels = 3;
  var bi = _BitIterator(((bmpData.width * bmpData.height * colorChannels) / 8).ceil());

  int i = 0;

  for (int x = 0; x < bmpData.width; x++) {
    for (int y = 0; y < bmpData.height; y++) {
      var pixelColor = bmpData.getPixel(x, y);
      bi.setBit(i, Image.getRed(pixelColor));
      bi.setBit(i + 1, Image.getGreen(pixelColor));
      bi.setBit(i + 2, Image.getBlue(pixelColor));
      i += 3;
    }
  }

  return _convert(bi.data());
}

Future<SteganoOutput> _convert(Uint8List buf) async {
  if (buf == null || buf.length < 2)
    return null;

  const terminator = 0xFF; // here we fix a bug of windows version 2 Terminators are present
  var header = buf[0];
  String outputText;
  List<local.GCWFile>  outputFiles;
  // print(buf);

  switch (header) {
    case 1: //only text
      var end = -1;
      for (int i = 1; i < buf.length; i++) {
        if (buf[i] == terminator && buf[i-1] == terminator) {
          end = i - 1;
          break;
        }
      }

      if (end > 0) {
        try {
          outputText = utf8.decode(buf.sublist(1, end));
        } catch (e) {}
      }
      break;
    //case 1: //text + encryption

    case 2: //text and files
      try {
        var zipFileLength = zipFileSize(buf.sublist(1));
        if (zipFileLength != null && zipFileLength > 0) {
          var zipFile = buf.sublist(1, zipFileLength + 1);
          outputFiles = await extractArchive(GCWFile(bytes: zipFile));

          var start = -1;
          for (int i = zipFile.length - 1; i > 0; i--) {
            if (zipFile[i] == 0x00) {
              start = i + 1;
              break;
            };
          }

          if (start > 0)
            outputText = utf8.decode(zipFile.sublist(start));
        }
      } catch (e) {}


    //case 2: //text and files + encryption

      break;
    default:
      return null;
  }

  if (outputText != null || outputFiles != null)
    return Future.value(SteganoOutput(SteganoSource.SteganoDotNet, outputText, outputFiles));
}

class _BitIterator {

  _BitIterator(int length) {
    _buf = Uint8List.fromList(List<int>.filled(length, 0));
  }

  Uint8List _buf;

  Uint8List data() {
    // it starts from behind and looks for 0x00
    const empty = 0x00;
    int resize = 0;
    int current = 0, next = 0xFF;
    for (int i = _buf.length - 1; i > 0; i--) {
      current = _buf[i];
      if (i - 1 > 0)
        next = _buf[i - 1];
      else
        next = 0xFF;

      if (current == empty)
        resize = i;
      else if (current != empty && next == empty)
        resize = i;
      else
        break;
    }
    if (resize > 0)
      _resizeBuffer(resize);

    return _buf;
  }

  void setBit(int i, int b) {
    if (i / 8 >= _buf.length)
      _resizeBuffer((i / 8 + 1).toInt());

    /** ~ -> NOT Operator to clear the i-th postition in byte and than overwrite it
     * by the bit out from the source
     */
    int curr = _buf[(i / 8).toInt()];
    _buf[(i / 8).toInt()] = ((curr & ~((b & 0x01) << i % 8)) | ((b & 0x01) << i % 8));
  }
  
  void _resizeBuffer(int length) {
    if (_buf.length < length) {
      var list = _buf.toList();
      list.addAll(List<int>.filled(length - _buf.length, 0));
      _buf = Uint8List.fromList(list);
    } else if (_buf.length > length)
      _buf = _buf.sublist(0, length);
  }
}
