import 'dart:typed_data';

import 'biobjecttype.dart';

class BSizeT {
  final int value;

  BSizeT(this.value);

  int asInt() => value;
}

class BSizeTType extends BObjectType<BSizeT> {
  final int sizeTSize;
  late final BIntegerType integerType;

  BSizeTType(this.sizeTSize) {
    integerType = BIntegerType(sizeTSize);
  }

  BSizeT parse(ByteBuffer buffer, BHeader header) {
    final value = BSizeT(integerType.raw_parse(buffer, header));
    if (header.debug) {
      print('-- parsed <size_t> $value');
    }
    return value;
  }
}

class BIntegerType {
  final int size;

  BIntegerType(this.size);

  int raw_parse(ByteBuffer buffer, BHeader header) {
    // Implement the logic to parse the integer value from the buffer
    throw UnimplementedError();
  }
}

class BHeader {
  final bool debug;

  BHeader({required this.debug});
}

