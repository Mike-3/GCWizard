import '../util/bytebuffer.dart';
import 'bheader.dart';
import 'bobjecttype.dart';
import 'lupvalue.dart';

class LUpvalueType extends BObjectType<LUpvalue> {
  @override
  LUpvalue parse(ByteBuffer_ buffer, BHeader header) {
    LUpvalue upvalue = LUpvalue();
    upvalue.instack = buffer.getInt8_(0) != 0;
    upvalue.idx = buffer.getInt8_(1) & 0xFF;
    return upvalue;
  }
}

