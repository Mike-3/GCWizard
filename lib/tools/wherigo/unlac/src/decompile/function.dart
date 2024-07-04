import '../parse/lfunction.dart';
import '../version.dart';
import 'constant.dart';
import 'expression/constantexpression.dart';
import 'expression/globalexpression.dart';

class Function_ {
  List<Constant> constants;
  final int constantsOffset;

  Function_(LFunction function)
      : constants = List<Constant>.generate(
            function.constants.length, (i) => Constant(function.constants[i])),
        constantsOffset = function.header.version == Version.LUA50 ? 250 : 256;

  bool isConstant(int register) {
    return register >= constantsOffset;
  }

  int constantIndex(int register) {
    return register - constantsOffset;
  }

  String getGlobalName(int constantIndex) {
    return constants[constantIndex].asName();
  }

  ConstantExpression getConstantExpression(int constantIndex) {
    return ConstantExpression(constants[constantIndex], constantIndex);
  }

  GlobalExpression getGlobalExpression(int constantIndex) {
    return GlobalExpression(getGlobalName(constantIndex), constantIndex);
  }
}


