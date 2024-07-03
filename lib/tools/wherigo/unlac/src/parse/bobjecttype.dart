import 'dart:typed_data';

import 'bheader.dart';
import 'blist.dart';
import 'bobject.dart';

abstract class BObjectType<T extends BObject> {
  T parse(ByteBuffer buffer, BHeader header);

  BList<T> parseList(ByteBuffer buffer, BHeader header) {
    final length = header.integer.parse(buffer, header);
    final values = <T>[];
    length.iterate(() {
      values.add(parse(buffer, header));
    });
    return BList<T>(length, values);
  }
}

