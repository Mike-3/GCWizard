import 'bheader.dart';
import 'llocal.dart';
import 'lobject.dart';
import 'lupvalue.dart';

class LFunction {
  BHeader header;
  LFunction? parent;
  List<int> code;
  List<LLocal> locals;
  List<LObject> constants;
  List<LUpvalue> upvalues;
  List<LFunction> functions;
  int maximumStackSize;
  int numUpvalues;
  int numParams;
  int vararg;
  bool stripped;

  LFunction(
    this.header,
    this.code,
    this.locals,
    this.constants,
    this.upvalues,
    this.functions,
    this.maximumStackSize,
    this.numUpvalues,
    this.numParams,
    this.vararg,
  ) : stripped = false;
}