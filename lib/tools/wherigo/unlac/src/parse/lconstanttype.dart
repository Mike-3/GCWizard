import 'dart:typed_data';

import 'bheader.dart';
import 'lnil.dart';
import 'lobject.dart';

abstract class LConstantType extends BObjectType<LObject> {
  static LConstantType50 getType50() {
    return LConstantType50();
  }

  static LConstantType53 getType53() {
    return LConstantType53();
  }
}

class LConstantType50 extends LConstantType {
  @override
  LObject parse(ByteBuffer buffer, BHeader header) {
    int type = buffer.getUint8();
    if (header.debug) {
      print("-- parsing <constant>, type is ");
      switch (type) {
        case 0:
          print("<nil>");
          break;
        case 1:
          print("<boolean>");
          break;
        case 3:
          print("<number>");
          break;
        case 4:
          print("<string>");
          break;
        default:
          print("illegal $type");
          break;
      }
    }
    switch (type) {
      case 0:
        return LNil.NIL;
      case 1:
        return header.bool.parse(buffer, header);
      case 3:
        return header.number.parse(buffer, header);
      case 4:
        return header.string.parse(buffer, header);
      default:
        throw StateError('Illegal state');
    }
  }
}

class LConstantType53 extends LConstantType {
  @override
  LObject parse(ByteBuffer buffer, BHeader header) {
    int type = buffer.getUint8();
    if (header.debug) {
      print("-- parsing <constant>, type is ");
      switch (type) {
        case 0:
          print("<nil>");
          break;
        case 1:
          print("<boolean>");
          break;
        case 3:
          print("<float>");
          break;
        case 0x13:
          print("<integer>");
          break;
        case 4:
          print("<short string>");
          break;
        case 0x14:
          print("<long string>");
          break;
        default:
          print("illegal $type");
          break;
      }
    }
    switch (type) {
      case 0:
        return LNil.NIL;
      case 1:
        return header.bool.parse(buffer, header);
      case 3:
        return header.lfloat.parse(buffer, header);
      case 0x13:
        return header.linteger.parse(buffer, header);
      case 4:
      case 0x14:
        return header.string.parse(buffer, header);
      default:
        throw StateError('Illegal state');
    }
  }
}