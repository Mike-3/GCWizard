import 'dart:typed_data';

import 'bibjecttype.dart';

class LUpvalue {
  late bool instack;
  late int idx;
}

class LUpvalueType extends BObjectType<LUpvalue> {
  @override
  LUpvalue parse(ByteBuffer buffer, BHeader header) {
    LUpvalue upvalue = LUpvalue();
    upvalue.instack = buffer.getInt8(0) != 0;
    upvalue.idx = buffer.getInt8(1) & 0xFF;
    return upvalue;
  }
}

