import '../declaration.dart';
import '../decompiler.dart';
import '../expression/expression.dart';
import '../output.dart';
import '../target/target.dart';

class Assignment extends Statement {
  final List<Target> targets = List<Target>.filled(5, null, growable: true);
  final List<Expression> values = List<Expression>.filled(5, null, growable: true);

  bool allnil = true;
  bool declare = false;
  int declareStart = 0;

  Assignment();

  @override
  bool beginsWithParen() {
    return targets[0].beginsWithParen();
  }

  Target getFirstTarget() {
    return targets[0];
  }

  Expression getFirstValue() {
    return values[0];
  }

  bool assignsTarget(Declaration decl) {
    for (var target in targets) {
      if (target.isDeclaration(decl)) {
        return true;
      }
    }
    return false;
  }

  int getArity() {
    return targets.length;
  }

  Assignment.withTargetValue(Target target, Expression value) {
    targets.add(target);
    values.add(value);
    allnil = allnil && value.isNil();
  }

  void addFirst(Target target, Expression value) {
    targets.insert(0, target);
    values.insert(0, value);
    allnil = allnil && value.isNil();
  }

  void addLast(Target target, Expression value) {
    if (targets.contains(target)) {
      int index = targets.indexOf(target);
      targets.removeAt(index);
      values.removeAt(index);
    }
    targets.add(target);
    values.add(value);
    allnil = allnil && value.isNil();
  }

  bool assignListEquals(List<Declaration> decls) {
    if (decls.length != targets.length) return false;
    for (var target in targets) {
      bool found = false;
      for (var decl in decls) {
        if (target.isDeclaration(decl)) {
          found = true;
          break;
        }
      }
      if (!found) return false;
    }
    return true;
  }

  void declare(int declareStart) {
    declare = true;
    this.declareStart = declareStart;
  }

  @override
  void print(Decompiler d, Output out) {
    if (targets.isNotEmpty) {
      if (declare) {
        out.print('local ');
      }
      bool functionSugar = false;
      if (targets.length == 1 && values.length == 1 && values[0].isClosure() && targets[0].isFunctionName()) {
        var closure = values[0];
        if (!declare || declareStart >= closure.closureUpvalueLine()) {
          functionSugar = true;
        }
        if (targets[0].isLocal() && closure.isUpvalueOf(targets[0].getIndex())) {
          functionSugar = true;
        }
      }
      if (!functionSugar) {
        targets[0].print(d, out);
        for (int i = 1; i < targets.length; i++) {
          out.print(', ');
          targets[i].print(d, out);
        }
        if (!declare || !allnil) {
          out.print(' = ');
          Expression.printSequence(d, out, values, false, false);
        }
      } else {
        values[0].printClosure(d, out, targets[0]);
      }
      if (comment != null) {
        out.print(' -- ');
        out.print(comment);
      }
    }
  }
}