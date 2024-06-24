import 'dart:typed_data';

class LLocal {
  final LString name;
  final BInteger start;
  final BInteger end;

  LLocal(this.name, this.start, this.end);
}

class LString {
  // Assuming LString has a parse method
  LString parse(ByteBuffer buffer, BHeader header) {
    // Implementation here
  }
}

class BInteger {
  // Assuming BInteger has a parse method and asInt method
  BInteger parse(ByteBuffer buffer, BHeader header) {
    // Implementation here
  }

  int asInt() {
    // Implementation here
  }
}

class BHeader {
  final LString string;
  final BInteger integer;
  final bool debug;

  BHeader(this.string, this.integer, this.debug);
}

class LLocalType extends BObjectType<LLocal> {
  @override
  LLocal parse(ByteBuffer buffer, BHeader header) {
    final name = header.string.parse(buffer, header);
    final start = header.integer.parse(buffer, header);
    final end = header.integer.parse(buffer, header);
    if (header.debug) {
      print('-- parsing local, name: $name from ${start.asInt()} to ${end.asInt()}');
    }
    return LLocal(name, start, end);
  }
}

abstract class BObjectType<T> {
  T parse(ByteBuffer buffer, BHeader header);
}