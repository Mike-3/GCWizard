import 'dart:typed_data';

import '../util/bytebuffer.dart';
import 'bheader.dart';
import 'binteger.dart';
import 'bobjecttype.dart';

class BIntegerType extends BObjectType<BInteger> {
  final int intSize;

  BIntegerType(this.intSize);

  BInteger raw_parse(ByteBuffer_ buffer, BHeader header) {
    BInteger value;
    switch (intSize) {
      case 0:
        value = BInteger.Int(0);
        break;
      case 1:
        value = BInteger.Int(buffer.getInt8_(0));
        break;
      case 2:
        value = BInteger.Int(buffer.getInt16_(0, Endian.little));
        break;
      case 4:
        value = BInteger.Int(buffer.getInt32(0, Endian.little));
        break;
      default:
        {
          final bytes = Uint8List(intSize);
          buffer.asUint8List().getRange(0, intSize).toList(growable: false).copyInto(bytes);
          value = BInteger.BigInt(BigInt.from(bytes.buffer.asByteData().getInt64(0, Endian.little)));
        }
        break;
    }
    return value;
  }

  @override
  BInteger parse(ByteBuffer_ buffer, BHeader header) {
    final value = raw_parse(buffer, header);
    if (header.debug) {
      print('-- parsed <integer> ${value.asInt()}');
    }
    return value;
  }
}

