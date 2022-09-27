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

  _BitIterator bi;

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
  if (buf == null)
    return null;
  return utf8.decode(buf);
}

class _BitIterator {

  var _buf = Uint8List(0);

  Uint8List data() {
    // this algorithm is more safe then before, it starts from behind and looks for 0x00
    int resize = 0;
    int current = 0, next = 0xFF, empty = 0x00;
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
      _buf.length = resize;

    return _buf;
  }

  void setBit(int i, int b) {
    if (i / 8 >= _buf.length)
      _buf.length = (i / 8 + 1).toInt();

    /** ~ -> NOT Operator to clear the i-th postition in byte and than overwrite it
     * by the bit out from the source
     */
    int curr = _buf[(i / 8).toInt()];
    _buf[(i / 8).toInt()] = ((curr & ~((b & 0x01) << i % 8)) | ((b & 0x01) << i % 8));
  }
}
