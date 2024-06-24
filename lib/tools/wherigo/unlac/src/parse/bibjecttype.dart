import 'dart:typed_data';

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

class BObject {}

class BHeader {}

class BInteger {
  void iterate(void Function() callback) {}
  int parse(ByteBuffer buffer, BHeader header) => 0;
}

class BList<T extends BObject> {
  BList(this.length, this.values);
  final BInteger length;
  final List<T> values;
}

