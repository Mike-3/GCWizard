import 'dart:typed_data';

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

  LNumber parse(ByteBuffer buffer, BHeader header) {
    LNumber value;
    if (integral) {
      switch (size) {
        case 4:
          value = LIntNumber(buffer.getInt32(0));
          break;
        case 8:
          value = LLongNumber(buffer.getInt64(0));
          break;
        default:
          throw StateError("The input chunk has an unsupported Lua number format");
      }
    } else {
      switch (size) {
        case 4:
          value = LFloatNumber(buffer.getFloat32(0), mode);
          break;
        case 8:
          value = LDoubleNumber(buffer.getFloat64(0), mode);
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

class LNumber {}

class LIntNumber extends LNumber {
  final int value;
  LIntNumber(this.value);
}

class LLongNumber extends LNumber {
  final int value;
  LLongNumber(this.value);
}

class LFloatNumber extends LNumber {
  final double value;
  final NumberMode mode;
  LFloatNumber(this.value, this.mode);
}

class LDoubleNumber extends LNumber {
  final double value;
  final NumberMode mode;
  LDoubleNumber(this.value, this.mode);
}

class BHeader {
  final bool debug;
  BHeader(this.debug);
}