import "package:flutter_test/flutter_test.dart";
import 'package:gc_wizard/tools/crypto_and_encodings/roman_numbers/chronogram/logic/chronogram.dart';

void main() {
  group("Chronogram.withoutJU:", () {
    List<Map<String, Object?>> _inputsToExpected = [
      {'input' : '', 'expectedOutput' : null},

      {'input' : 'ALICIMAAMADMIDIAILACMIICLIIIDIMCAMMIDIIDIACADDIDADIILDMICALMLII', 'expectedOutput' : 14921},
      {'input' : 'habemus Papam', 'expectedOutput' : 2000},
      {'input' : 'Christvs dvx; ergo trivmphvs', 'expectedOutput' : 1632},
      {'input' : 'Christus dux; ergo triumphus', 'expectedOutput' : 1612},
      {'input' : 'SIT LARIBVS NOSTRIS OPTO CONCORDIA CONSTANS NOSTER ET ASSIDVO LVCEAT IGNE FOCVS', 'expectedOutput' : 1626},
      {'input' : 'SVRGE O IEHOVA ATQVE DISPERGE INIMICOS TVOS', 'expectedOutput' : 1625},
    ];

    for (var elem in _inputsToExpected) {
      test('input: ${elem['input']}', () {
        var _actual = decodeChronogram(elem['input'] as String);
        expect(_actual, elem['expectedOutput']);
      });
    }
  });

  group("Chronogram.JUToIV:", () {
    List<Map<String, Object?>> _inputsToExpected = [
      {'input' : '', 'expectedOutput' : null},

      {'input' : 'ALICIMAAMADMIDIAILACMIICLIIIDIMCAMMIDIIDIACADDIDADIILDMICALMLII', 'expectedOutput' : 14921},
      {'input' : 'habemus Papam', 'expectedOutput' : 2005},
      {'input' : 'Christvs dvx; ergo trivmphvs', 'expectedOutput' : 1632},
      {'input' : 'Christus dux; ergo triumphus', 'expectedOutput' : 1632},
      {'input' : 'SIT LARIBVS NOSTRIS OPTO CONCORDIA CONSTANS NOSTER ET ASSIDVO LVCEAT IGNE FOCVS', 'expectedOutput' : 1626},
      {'input' : 'SVRGE O IEHOVA ATQVE DISPERGE INIMICOS TVOS', 'expectedOutput' : 1625},
    ];

    for (var elem in _inputsToExpected) {
      test('input: ${elem['input']}', () {
        var _actual = decodeChronogram(elem['input'] as String, JUToIV: true);
        expect(_actual, elem['expectedOutput']);
      });
    }
  });
}