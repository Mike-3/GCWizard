import 'dart:typed_data';

class LSourceLines {
  static LSourceLines? parse(ByteBuffer buffer) {
    var byteData = buffer.asByteData();
    int number = byteData.getInt32(0, Endian.little);
    int offset = 4;
    while (number-- > 0) {
      byteData.getInt32(offset, Endian.little);
      offset += 4;
    }
    return null;
  }
}