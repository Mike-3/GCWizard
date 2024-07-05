import '../util/bytebuffer.dart';
import 'bheader.dart';
import 'lnumber.dart';

enum NumberMode {
  MODE_NUMBER, // Used for Lua 5.0 - 5.2 where numbers can represent integers or floats
  MODE_FLOAT, // Used for floats in Lua 5.3
  MODE_INTEGER, // Used for integers in Lua 5.3
}

class LNumberType {
  final int size;
  final bool integral;
  final NumberMode mode;

  LNumberType(this.size, this.integral, this.mode) {
    if (!(size == 4 || size == 8)) {
      throw StateError("The input chunk has an unsupported Lua number size: $size");
    }
  }

  double convert(double number) {
    if (integral) {
      switch (size) {
        case 4:
          return number.toInt().toDouble();
        case 8:
          return number.toInt().toDouble();
      }
    } else {
      switch (size) {
        case 4:
          return number.toDouble();
        case 8:
          return number;
      }
    }
    throw StateError("The input chunk has an unsupported Lua number format");
  }

  LNumber parse(ByteBuffer_ buffer, BHeader header) {
    LNumber value;
    if (integral) {
      switch (size) {
        case 4:
          value = LIntNumber(buffer.getInt32_(0));
          break;
        case 8:
          value = LLongNumber(buffer.getInt64_(0));
          break;
        default:
          throw StateError("The input chunk has an unsupported Lua number format");
      }
    } else {
      switch (size) {
        case 4:
          value = LFloatNumber(buffer.getFloat32_(0), mode);
          break;
        case 8:
          value = LDoubleNumber(buffer.getFloat64_(0), mode);
          break;
        default:
          throw StateError("The input chunk has an unsupported Lua number format");
      }
    }
    if (header.debug) {
      print("-- parsed <number> $value");
    }
    return value;
  }
}
