import '../parse/lfunction.dart';
import '../parse/lupvalue.dart';
import 'declaration.dart';
import 'expression/upvalueexpression.dart';

class Upvalues {
  final List<LUpvalue> upvalues;

  Upvalues(LFunction func, List<Declaration>? parentDecls, int line)
      : upvalues = func.upvalues {
    for (var upvalue in upvalues) {
      if (upvalue.name == null || upvalue.name!.isEmpty) {
        if (upvalue.instack) {
          if (parentDecls != null) {
            for (var decl in parentDecls) {
              if (decl.register == upvalue.idx &&
                  line >= decl.begin &&
                  line < decl.end) {
                upvalue.name = decl.name;
                break;
              }
            }
          }
        } else {
          var parentvals = func.parent?.upvalues;
          if (upvalue.idx >= 0 && parentvals != null && upvalue.idx < parentvals.length) {
            upvalue.name = parentvals[upvalue.idx].name;
          }
        }
      }
    }
  }

  String getName(int index) {
    if (index < upvalues.length &&
        upvalues[index].name != null &&
        upvalues[index].name!.isNotEmpty) {
      return upvalues[index].name!;
    } else {
      //TODO: SET ERROR
      return "_UPVALUE${index}_";
    }
  }

  UpvalueExpression getExpression(int index) {
    return UpvalueExpression(getName(index));
  }
}


