import '../decompiler.dart';
import '../output.dart';
import 'target.dart';

class GlobalTarget extends Target {
  final String name;

  GlobalTarget(this.name);

  @override
  void print(Decompiler d, Output out) {
    out.print(name);
  }

  @override
  void printMethod(Decompiler d, Output out) {
    throw StateError('Illegal state');
  }
}
