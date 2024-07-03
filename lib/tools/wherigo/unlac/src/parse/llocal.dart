import 'binteger.dart';
import 'lstring.dart';

class LLocal {
  final LString name;
  final int start;
  final int end;

  // Used by the decompiler for annotation.
  bool forLoop = false;

  LLocal(this.name, BInteger start, BInteger end)
      : start = start.asInt(),
        end = end.asInt();

  @override
  String toString() {
    return name.deref();
  }
}