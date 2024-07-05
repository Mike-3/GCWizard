import '../util/bytebuffer.dart';
import '../util/exception.dart';
import 'bheader.dart';
import 'bobjecttype.dart';
import 'lboolean.dart';


class LBooleanType extends BObjectType<LBoolean> {
  @override
  LBoolean parse(ByteBuffer_ buffer, BHeader header) {
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

