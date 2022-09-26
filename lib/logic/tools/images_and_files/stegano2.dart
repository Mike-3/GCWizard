import 'dart:typed_data';
import 'package:image/image.dart' as Image;
import 'package:gc_wizard/widgets/utils/gcw_file.dart';

Uint8List buf;

String unhideData(GCWFile sourceFile) {
  var bmpData = Image.decodeImage(sourceFile.bytes);

BitIterator bi;

int lastProg = 1, currProg = -1, i = 0, colorChannels = 3;
int progGes = bmpData.width * bmpData.height * bmpData.numberOfChannels;

//monitor->setValue(lastProg);
for (int x = 0; x < bmpData.width; x++) {
  for (int y = 0; y < bmpData.height; y++) {
    currProg = ((x * y * colorChannels * 100) / progGes).toInt();
    if(currProg > lastProg) {
      lastProg = currProg;
      // monitor->setValue( currProg );
      // if (monitor->wasCanceled())
      //   return QByteArray();
    }
  var pixelColor = bmpData.getPixel(x, y);
  bi.setBit(i,    Image.getRed(pixelColor));
  bi.setBit(i+1,  Image.getGreen(pixelColor));
  bi.setBit(i+2,  Image.getBlue(pixelColor));
  i += 3;
  }
}

// QByteArray message = bi.data();
// QString result;
// bool found = false;
// ISteganoContainer*  container  = NULL;
// IMessageContainer*  icmes      = NULL;
// IDocumentContainer* icdoc      = NULL;
//
// if(this->useCrypt) {
// container = MessageContainerFactory::createMessageContainerFromRaw(message, this->key);
// }else {
// container = MessageContainerFactory::createMessageContainerFromRaw(message);
// }
// icmes = dynamic_cast< IMessageContainer* >(container);
// icdoc = dynamic_cast< IDocumentContainer* >(container);
// if(icmes) {
// result = icmes->text();
// }
// if(icdoc) {
// QString all = icdoc->files().join(",");
// qDebug() << all;
// }

return result;
}

void setBit(int i, int b) {
  if ((i / 8) > buf.length)
    buf.length = (buf.length + 1);

  //int round = i / 8;
  //byte current;

  //current = data[round];

  //int shifter = (i - (round * 8));
  //byte nb = (byte)(b & 0x01);
  //byte lastBit = (byte)(b & 0x01);
  //current = (byte)((current << 1) | (b & 0x01));
  //if (round < data.Length)
  //    data[round] = current;

  /** ~ -> NOT Operator to clear the i-th postition in byte and than overwrite it
   * by the bit out from the source
   */
  int curr = buf[(i / 8).toInt()];
  buf[(i / 8).toInt()] = ((curr & ~((b & 0x01) << i % 8)) | ((b & 0x01) << i % 8));
}