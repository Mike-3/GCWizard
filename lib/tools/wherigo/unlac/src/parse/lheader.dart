import '../decompile/codeextract.dart';
import '../decompile/decompile.dart';
import 'bobjecttype.dart';
import 'bintegertype.dart';
import 'bsizettype.dart';
import 'lbooleantype.dart';
import 'lconstanttype.dart';
import 'lfunctiontype.dart';
import 'llocaltype.dart';
import 'lnumbertype.dart';
import 'lstringtype.dart';
import 'lupvaluetype.dart';

class LHeader extends BObject {
  final int format;
  final BIntegerType integer;
  final BSizeTType sizeT;
  final LBooleanType bool;
  final LNumberType number;
  final LNumberType linteger;
  final LNumberType lfloat;
  final LStringType string;
  final LConstantType constant;
  final LLocalType local;
  final LUpvalueType upvalue;
  final LFunctionType function;
  final CodeExtract extractor;

  LHeader(
    this.format,
    this.integer,
    this.sizeT,
    this.bool,
    this.number,
    this.linteger,
    this.lfloat,
    this.string,
    this.constant,
    this.local,
    this.upvalue,
    this.function,
    this.extractor,
  );
}