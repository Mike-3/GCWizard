import 'dart:typed_data';

import 'biobjecttype.dart';

class LBooleanType extends BObjectType<LBoolean> {
  @override
  LBoolean parse(ByteBuffer buffer, BHeader header) {
    int value = buffer.asUint8List().first;
    if ((value & 0xFFFFFFFE) != 0) {
      throw IllegalStateException();
    } else {
      LBoolean bool = value == 0 ? LBoolean.LFALSE : LBoolean.LTRUE;
      if (header.debug) {
        print('-- parsed <boolean> $bool');
      }
      return bool;
    }
  }
}

class LBoolean {
  static final LBoolean LFALSE = LBoolean._internal(false);
  static final LBoolean LTRUE = LBoolean._internal(true);

  final bool value;

  LBoolean._internal(this.value);
}

class BHeader {
  final bool debug;

  BHeader(this.debug);
}

class IllegalStateException implements Exception {
  @override
  String toString() => 'IllegalStateException';
}

