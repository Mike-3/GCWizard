import '../declaration.dart';
import '../decompiler.dart';
import '../output.dart';
import 'target.dart';

class VariableTarget extends Target {
  final Declaration decl;

  VariableTarget(this.decl);

  @override
  void print(Decompiler d, Output out) {
    out.print(decl.name);
  }

  @override
  void printMethod(Decompiler d, Output out) {
    throw StateError('Illegal state');
  }

  @override
  bool isDeclaration(Declaration decl) {
    return this.decl == decl;
  }

  @override
  bool isLocal() {
    return true;
  }

  @override
  int? getIndex() {
    return decl.register;
  }

  @override
  bool operator ==(Object other) {
    if (other is VariableTarget) {
      return decl == other.decl;
    } else {
      return false;
    }
  }

  @override
  int get hashCode => decl.hashCode;
}