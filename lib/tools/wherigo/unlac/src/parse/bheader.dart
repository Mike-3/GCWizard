import 'dart:core';
import 'dart:typed_data';

import '../configuration.dart';
import '../decompile/codeextract.dart';
import '../util/bytebuffer.dart';
import '../util/exception.dart';
import '../version.dart';
import 'bintegertype.dart';
import 'bsizettype.dart';
import 'lbooleantype.dart';
import 'lconstanttype.dart';
import 'lfunction.dart';
import 'lfunctiontype.dart';
import 'lheader.dart';
import 'llocaltype.dart';
import 'lnumbertype.dart';
import 'lstringtype.dart';
import 'lupvaluetype.dart';

class BHeader {
  static final Uint8List signature = {
    0x1B,
    0x4C,
    0x75,
    0x61,
  } as Uint8List;

  final bool debug = false;

  final Configuration config;
  late final Version version;
  late final LHeader lheader;
  late final BIntegerType integer;
  late final BSizeTType sizeT;
  late final LBooleanType bool_;
  late final LNumberType number;
  late final LNumberType linteger;
  late final LNumberType lfloat;
  late final LStringType string;
  late final LConstantType constant;
  late final LLocalType local;
  late final LUpvalueType upvalue;
  late final LFunctionType function;
  late final CodeExtract extractor;

  late final LFunction main;

  BHeader(ByteBuffer_ buffer, Configuration config)
      : config = config {
    // 4 byte Lua signature
    for (int i = 0; i < signature.length; i++) {
      if (buffer.getUint8_(i) != signature[i]) {
        throw IllegalStateException(
            'The input file does not have the signature of a valid Lua file.');
      }
    }
    // 1 byte Lua version
    int versionNumber = buffer.getUint8_(4);
    switch (versionNumber) {
      case 0x50:
        version = Version.LUA50;
        break;
      case 0x51:
        version = Version.LUA51;
        break;
      case 0x52:
        version = Version.LUA52;
        break;
      case 0x53:
        version = Version.LUA53;
        break;
      default:
        {
          int major = versionNumber >> 4;
          int minor = versionNumber & 0x0F;
          throw IllegalStateException(
              'The input chunk\'s Lua version is $major.$minor; unluac can only handle Lua 5.0 - Lua 5.3.');
        }
    }
    lheader = version.getLHeaderType().parse(buffer, this);
    integer = lheader.integer;
    sizeT = lheader.sizeT;
    bool_ = lheader.bool_;
    number = lheader.number;
    linteger = lheader.linteger;
    lfloat = lheader.lfloat;
    string = lheader.string;
    constant = lheader.constant;
    local = lheader.local;
    upvalue = lheader.upvalue;
    function = lheader.function;
    extractor = lheader.extractor;

    int upvalues = -1;
    if (versionNumber >= 0x53) {
      upvalues = buffer.getUint8_(5);
      if (debug) {
        print('-- main chunk upvalue count: $upvalues');
      }
      // TODO: check this value
    }
    main = function.parse(buffer, this);
    if (upvalues >= 0) {
      if (main.numUpvalues != upvalues) {
        throw IllegalStateException(
            'The main chunk has the wrong number of upvalues: ${main.numUpvalues} ($upvalues expected)');
      }
    }
    if (main.numUpvalues >= 1 && versionNumber >= 0x52 && (main.upvalues[0].name == null || main.upvalues[0].name!.isEmpty)) {
      main.upvalues[0].name = '_ENV';
    }
  }
}

