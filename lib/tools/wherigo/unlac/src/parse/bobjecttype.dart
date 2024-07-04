import 'dart:typed_data';

import 'bheader.dart';
import 'blist.dart';
import 'bobject.dart';

abstract class BObjectType<T extends BObject> {
  T parse(ByteBuffer_ buffer, BHeader header);

  BList<T> parseList(ByteBuffer_ buffer, BHeader header) {
    final length = header.integer.parse(buffer, header);
    final values = <T>[];
    length.iterate(() {
      values.add(parse(buffer, header));
    });
    return BList<T>(length, values);
  }
}

class ByteBuffer_ {
  ByteBuffer buffer;
  int pointer = 0;
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

  int getInt64(int pointer) {
    return buffer.asByteData(pointer, 8).getInt64(0, order);
  }

  double getFloat32(int pointer) {
    return buffer.asByteData(pointer, 4).getFloat32(0, order);
  }

  double getFloat64(int pointer) {
    return buffer.asByteData(pointer, 8).getFloat64(0, order);
  }

  Uint8List asUint8List() {
    return buffer.asUint8List();
  }
}

