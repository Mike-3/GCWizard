// source: https://github.com/sassman/stegano.kde4
// Stegano.NET logic

import 'dart:convert';
import 'dart:typed_data';
import 'package:image/image.dart' as Image;
import 'package:gc_wizard/widgets/utils/gcw_file.dart' as local;

String decodeSteganoNet(local.GCWFile sourceFile) {
  if (sourceFile == null)
    return null;
  return decodeSteganoNetData(Image.decodeImage(sourceFile.bytes));
}

String decodeSteganoNetData(Image.Image bmpData) {
  if (bmpData == null)
    return null;

  const colorChannels = 3;
  var bi = _BitIterator(((bmpData.width * bmpData.height * colorChannels) / 8).ceil());

  int i = 0;
  // lastProg = 1,
  //     currProg = -1,
  //     i = 0,
  //     colorChannels = 3;
  // int progGes = bmpData.width * bmpData.height * bmpData.numberOfChannels;

  for (int x = 0; x < bmpData.width; x++) {
    for (int y = 0; y < bmpData.height; y++) {
      // currProg = ((x * y * colorChannels * 100) / progGes).toInt();
      // if (currProg > lastProg)
      //   lastProg = currProg;

      var pixelColor = bmpData.getPixel(x, y);
      bi.setBit(i, Image.getRed(pixelColor));
      bi.setBit(i + 1, Image.getGreen(pixelColor));
      bi.setBit(i + 2, Image.getBlue(pixelColor));
      i += 3;
    }
  }

  return _convert(bi.data());
}

String _convert(Uint8List buf) {
  if (buf == null || buf.length < 2)
    return null;
  var header = buf[0];

  switch (header) {
    case 1:
      const endIdentifier = 0xFF;
      var  end = -1;
      for (int i = 1; i < buf.length; i++) {
        if (buf[i] == endIdentifier && buf[i-1] == endIdentifier) {
          end = i -2;
          break;
        }
      }
      if (end > 0) {
        try {
          return utf8.decode(buf.sublist(1, end));
        } catch (e) {
          return null;
        }
      }
      break;
    default:
      return null;
  }
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
