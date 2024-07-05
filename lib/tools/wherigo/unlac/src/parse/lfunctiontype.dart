import '../util/bytebuffer.dart';
import 'bheader.dart';
import 'binteger.dart';
import 'blist.dart';
import 'bobjecttype.dart';
import 'lfunction.dart';
import 'llocal.dart';
import 'lobject.dart';
import 'lstring.dart';
import 'lupvalue.dart';

class LFunctionType extends BObjectType<LFunction> {
  static final LFunctionType TYPE50 = LFunctionType50();
  static final LFunctionType TYPE51 = LFunctionType();
  static final LFunctionType TYPE52 = LFunctionType52();
  static final LFunctionType TYPE53 = LFunctionType53();

  @override
  LFunction parse(ByteBuffer_ buffer, BHeader header) {
    if (header.debug) {
      print("-- beginning to parse function");
    }
    if (header.debug) {
      print("-- parsing name...start...end...upvalues...params...varargs...stack");
    }
    var s = LFunctionParseState();
    parseMain(buffer, header, s);
    var lfunc = LFunction(
      header,
      s.code,
      s.locals.asArray(List<LLocal>.filled(s.locals.length.asInt(), LLocal())),
      s.constants.asArray(List<LObject>.filled(s.constants.length.asInt(), LObject())),
      s.upvalues,
      s.functions.asArray(List<LFunction>.filled(s.functions.length.asInt(), LFunction())),
      s.maximumStackSize,
      s.lenUpvalues,
      s.lenParameter,
      s.vararg,
    );
    for (var child in lfunc.functions) {
      child.parent = lfunc;
    }
    if (s.lines.length.asInt() == 0 && s.locals.length.asInt() == 0) {
      lfunc.stripped = true;
    }
    return lfunc;
  }

  void parseMain(ByteBuffer_ buffer, BHeader header, LFunctionParseState s) {
    s.name = header.string.parse(buffer, header);
    s.lineBegin = header.integer.parse(buffer, header).asInt();
    s.lineEnd = header.integer.parse(buffer, header).asInt();
    s.lenUpvalues = buffer.getUint8();
    s.lenParameter = buffer.getUint8();
    s.vararg = buffer.getUint8();
    s.maximumStackSize = buffer.getUint8();
    parseCode(buffer, header, s);
    parseConstants(buffer, header, s);
    parseUpvalues(buffer, header, s);
    parseDebug(buffer, header, s);
  }

  void parseCode(ByteBuffer_ buffer, BHeader header, LFunctionParseState s) {
    if (header.debug) {
      print("-- beginning to parse bytecode list");
    }
    s.length = header.integer.parse(buffer, header).asInt();
    s.code = List<int>.filled(s.length, 0);
    for (var i = 0; i < s.length; i++) {
      s.code[i] = buffer.getInt32();
      if (header.debug) {
        print("-- parsed codepoint ${s.code[i].toRadixString(16)}");
      }
    }
  }

  void parseConstants(ByteBuffer_ buffer, BHeader header, LFunctionParseState s) {
    if (header.debug) {
      print("-- beginning to parse constants list");
    }
    s.constants = header.constant.parseList(buffer, header);
    if (header.debug) {
      print("-- beginning to parse functions list");
    }
    s.functions = header.function.parseList(buffer, header);
  }

  void parseDebug(ByteBuffer_ buffer, BHeader header, LFunctionParseState s) {
    if (header.debug) {
      print("-- beginning to parse source lines list");
    }
    s.lines = header.integer.parseList(buffer, header);
    if (header.debug) {
      print("-- beginning to parse locals list");
    }
    s.locals = header.local.parseList(buffer, header);
    if (header.debug) {
      print("-- beginning to parse upvalues list");
    }
    var upvalueNames = header.string.parseList(buffer, header);
    for (var i = 0; i < upvalueNames.length.asInt(); i++) {
      s.upvalues[i].name = upvalueNames.get(i).deref();
    }
  }

  void parseUpvalues(ByteBuffer_ buffer, BHeader header, LFunctionParseState s) {
    s.upvalues = List<LUpvalue>.filled(s.lenUpvalues, LUpvalue());
    for (var i = 0; i < s.lenUpvalues; i++) {
      s.upvalues[i] = LUpvalue();
    }
  }
}

class LFunctionType52 extends LFunctionType {
  @override
  void parseMain(ByteBuffer_ buffer, BHeader header, LFunctionParseState s) {
    s.lineBegin = header.integer.parse(buffer, header).asInt();
    s.lineEnd = header.integer.parse(buffer, header).asInt();
    s.lenParameter = buffer.getUint8();
    s.vararg = buffer.getUint8();
    s.maximumStackSize = buffer.getUint8();
    parseCode(buffer, header, s);
    parseConstants(buffer, header, s);
    parseUpvalues(buffer, header, s);
    parseDebug(buffer, header, s);
  }

  @override
  void parseDebug(ByteBuffer_ buffer, BHeader header, LFunctionParseState s) {
    s.name = header.string.parse(buffer, header);
    super.parseDebug(buffer, header, s);
  }

  @override
  void parseUpvalues(ByteBuffer_ buffer, BHeader header, LFunctionParseState s) {
    var upvalues = header.upvalue.parseList(buffer, header);
    s.lenUpvalues = upvalues.length.asInt();
    s.upvalues = upvalues.asArray(List<LUpvalue>.filled(s.lenUpvalues, LUpvalue()));
  }
}

class LFunctionType53 extends LFunctionType {
  @override
  void parseMain(ByteBuffer_ buffer, BHeader header, LFunctionParseState s) {
    s.name = header.string.parse(buffer, header); // TODO: psource
    s.lineBegin = header.integer.parse(buffer, header).asInt();
    s.lineEnd = header.integer.parse(buffer, header).asInt();
    s.lenParameter = buffer.getUint8();
    s.vararg = buffer.getUint8();
    s.maximumStackSize = buffer.getUint8();
    parseCode(buffer, header, s);
    s.constants = header.constant.parseList(buffer, header);
    parseUpvalues(buffer, header, s);
    s.functions = header.function.parseList(buffer, header);
    parseDebug(buffer, header, s);
  }

  @override
  void parseUpvalues(ByteBuffer_ buffer, BHeader header, LFunctionParseState s) {
    var upvalues = header.upvalue.parseList(buffer, header);
    s.lenUpvalues = upvalues.length.asInt();
    s.upvalues = upvalues.asArray(List<LUpvalue>.filled(s.lenUpvalues, LUpvalue()));
  }
}

class LFunctionType50 extends LFunctionType {
  @override
  void parseMain(ByteBuffer_ buffer, BHeader header, LFunctionParseState s) {
    s.name = header.string.parse(buffer, header);
    s.lineBegin = header.integer.parse(buffer, header).asInt();
    s.lineEnd = 0;
    s.lenUpvalues = buffer.getUint8();
    s.upvalues = List<LUpvalue>.filled(s.lenUpvalues, LUpvalue());
    for (var i = 0; i < s.lenUpvalues; i++) {
      s.upvalues[i] = LUpvalue();
    }
    s.lenParameter = buffer.getUint8();
    s.vararg = buffer.getUint8();
    s.maximumStackSize = buffer.getUint8();
    parseDebug(buffer, header, s);
    parseConstants(buffer, header, s);
    parseCode(buffer, header, s);
  }

  @override
  void parseDebug(ByteBuffer_ buffer, BHeader header, LFunctionParseState s) {
    super.parseDebug(buffer, header, s);
  }

  @override
  void parseUpvalues(ByteBuffer_ buffer, BHeader header, LFunctionParseState s) {
    var upvalues = header.upvalue.parseList(buffer, header);
    s.lenUpvalues = upvalues.length.asInt();
    s.upvalues = upvalues.asArray(List<LUpvalue>.filled(s.lenUpvalues, LUpvalue()));
  }
}

class LFunctionParseState {
  late LString name;
  late int lineBegin;
  late int lineEnd;
  late int lenUpvalues;
  late int lenParameter;
  late int vararg;
  late int maximumStackSize;
  late int length;
  late List<int> code;
  late BList<LObject> constants;
  late BList<LFunction> functions;
  late BList<BInteger> lines;
  late BList<LLocal> locals;
  late List<LUpvalue> upvalues;
}