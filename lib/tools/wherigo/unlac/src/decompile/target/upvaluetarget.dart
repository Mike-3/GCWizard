import 'decompiler.dart';
import 'output.dart';

class UpvalueTarget extends Target {
  final String name;

  UpvalueTarget(this.name);

  @override
  void print(Decompiler d, Output out) {
    out.print(name);
  }

  @override
  void printMethod(Decompiler d, Output out) {
    throw StateError('Illegal state');
  }
}
