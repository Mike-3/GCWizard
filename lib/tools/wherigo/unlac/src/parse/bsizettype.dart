import '../util/bytebuffer.dart';
import 'bheader.dart';
import 'bintegertype.dart';
import 'bobjecttype.dart';
import 'bsizet.dart';


class BSizeTType extends BObjectType<BSizeT> {
  final int sizeTSize;
  late final BIntegerType integerType;

  BSizeTType(this.sizeTSize) {
    integerType = BIntegerType(sizeTSize);
  }

  BSizeT parse(ByteBuffer_ buffer, BHeader header) {
    final value = BSizeT(integerType.raw_parse(buffer, header));
    if (header.debug) {
      print('-- parsed <size_t> $value');
    }
    return value;
  }
}


