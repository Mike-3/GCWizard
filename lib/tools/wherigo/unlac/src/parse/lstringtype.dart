import '../util/bytebuffer.dart';
import 'bheader.dart';
import 'bobjecttype.dart';
import 'bsizet.dart';
import 'lstring.dart';

abstract class LStringType extends BObjectType<LString> {
  static LStringType50 getType50() {
    return LStringType50();
  }

  static LStringType53 getType53() {
    return LStringType53();
  }

  ThreadLocal<StringBuffer> b = ThreadLocal<StringBuffer>(() => StringBuffer());
}

class LStringType50 extends LStringType {
  @override
  LString parse(ByteBuffer_ buffer, BHeader header) {
    BSizeT sizeT = header.sizeT.parse(buffer, header);
    final StringBuffer b = this.b.get();
    b.clear();
    sizeT.iterate(() {
      b.writeCharCode(0xFF & buffer.getUint8());
    });
    String s = b.toString();
    if (header.debug) {
      print("-- parsed <string> \"$s\"");
    }
    return LString(sizeT, s);
  }
}

class LStringType53 extends LStringType {
  @override
  LString parse(ByteBuffer_ buffer, BHeader header) {
    BSizeT sizeT;
    int size = 0xFF & buffer.getUint8();
    if (size == 0xFF) {
      sizeT = header.sizeT.parse(buffer, header);
    } else {
      sizeT = BSizeT(size);
    }
    final StringBuffer b = this.b.get();
    b.clear();
    sizeT.iterate(() {
      b.writeCharCode(0xFF & buffer.getUint8());
    });
    b.writeCharCode(0);
    String s = b.toString();
    if (header.debug) {
      print("-- parsed <string> \"$s\"");
    }
    return LString(sizeT, s);
  }
}

class ThreadLocal<T> {
  final T Function() _initialValue;
  T _value;

  ThreadLocal(this._initialValue) : _value = _initialValue();

  T get() => _value;
  void set(T value) => _value = value;
}
