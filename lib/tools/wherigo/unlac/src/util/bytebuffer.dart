import 'dart:typed_data';

class ByteBuffer_ {
  ByteBuffer buffer;
  int pointer = 0;
  int markPointer = 0;
  Endian order = Endian.big;

  ByteBuffer_(this.buffer);

  int getUint8() {
    pointer += 1;
    return buffer.asByteData(pointer - 1, 1).getUint8(0);
  }

  int getUint8_(int pointer) {
    return buffer.asByteData(pointer, 1).getInt8(0);
  }

  int getInt8_(int pointer) {
    return buffer.asByteData(pointer, 1).getInt8(0);
  }

  int getInt16() {
    pointer += 2;
    return buffer.asByteData(pointer, 2).getInt16(0, order);
  }

  int getInt16_(int pointer, Endian order) {
    return buffer.asByteData(pointer, 2).getInt16(0, order);
  }
  int getInt32() {
    pointer += 4;
    return buffer.asByteData(pointer, 4).getInt32(0, order);
  }

  int getInt32_(int pointer) {
    return buffer.asByteData(pointer, 4).getInt32(0, order);
  }

  int getInt64_(int pointer) {
    return buffer.asByteData(pointer, 8).getInt64(0, order);
  }

  double getFloat32_(int pointer) {
    return buffer.asByteData(pointer, 4).getFloat32(0, order);
  }

  double getFloat64_(int pointer) {
    return buffer.asByteData(pointer, 8).getFloat64(0, order);
  }

  Uint8List asUint8List() {
    return buffer.asUint8List();
  }

  void mark() {
    markPointer = pointer;
  }

  void reset() {
    pointer = markPointer;
  }
}