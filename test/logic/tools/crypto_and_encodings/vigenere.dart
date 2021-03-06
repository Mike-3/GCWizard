import "package:flutter_test/flutter_test.dart";
import 'package:gc_wizard/logic/tools/crypto_and_encodings/vigenere.dart';

void main() {
  group("Vigenere.encrypt:", () {
    List<Map<String, dynamic>> _inputsToExpected = [
      {'input' : null, 'key': null, 'autoKey': false, 'aValue': 0, 'expectedOutput' : ''},
      {'input' : null, 'key': 'ABC', 'autoKey': false, 'aValue': 0, 'expectedOutput' : ''},
      {'input' : 'ABC', 'key': null, 'autoKey': false, 'aValue': 0, 'expectedOutput' : 'ABC'},
      {'input' : '', 'key': '', 'autoKey': false, 'aValue': 0, 'expectedOutput' : ''},
      {'input' : '', 'key': 'ABC', 'autoKey': false, 'aValue': 0, 'expectedOutput' : ''},
      {'input' : 'ABC', 'key': '', 'autoKey': false, 'aValue': 0, 'expectedOutput' : 'ABC'},

      {'input' : 'ABC', 'key': 'MNO', 'autoKey': false, 'aValue': 0, 'expectedOutput' : 'MOQ'},
      {'input' : 'ABCDEF', 'key': 'MN', 'autoKey': false, 'aValue': 0, 'expectedOutput' : 'MOOQQS'},
      {'input' : 'ABCDEF', 'key': 'MN', 'autoKey': true, 'aValue': 0, 'expectedOutput' : 'MOCEGI'},

      {'input' : 'Abc', 'key': 'mnO', 'autoKey': false, 'aValue': 0, 'expectedOutput' : 'Moq'},
      {'input' : 'AbCDeF', 'key': 'MN', 'autoKey': false, 'aValue': 0, 'expectedOutput' : 'MoOQqS'},
      {'input' : 'ABcdeF', 'key': 'mn', 'autoKey': true, 'aValue': 0, 'expectedOutput' : 'MOcegI'},

      {'input' : 'Ab12c', 'key': 'mnO', 'autoKey': false, 'aValue': 0, 'expectedOutput' : 'Mo12q'},
      {'input' : ' A%67bC DeF_', 'key': 'MN', 'autoKey': false, 'aValue': 0, 'expectedOutput' : ' M%67oO QqS_'},
      {'input' : 'A Bcd23eF', 'key': 'mn', 'autoKey': true, 'aValue': 0, 'expectedOutput' : 'M Oce23gI'},

      {'input' : 'AbCDeF', 'key': 'MN', 'autoKey': false, 'aValue': 1, 'expectedOutput' : 'NpPRrT'},
      {'input' : 'AbCDeF', 'key': 'MN', 'autoKey': false, 'aValue': 13, 'expectedOutput' : 'ZbBDdF'},
      {'input' : 'AbCDeF', 'key': 'MN', 'autoKey': false, 'aValue': 26, 'expectedOutput' : 'MoOQqS'},
      {'input' : 'AbCDeF', 'key': 'MN', 'autoKey': false, 'aValue': 27, 'expectedOutput' : 'NpPRrT'},
      {'input' : 'AbCDeF', 'key': 'MN', 'autoKey': false, 'aValue': 52, 'expectedOutput' : 'MoOQqS'},
      {'input' : 'AbCDeF', 'key': 'MN', 'autoKey': false, 'aValue': -1, 'expectedOutput' : 'LnNPpR'},
      {'input' : 'AbCDeF', 'key': 'MN', 'autoKey': false, 'aValue': -13, 'expectedOutput' : 'ZbBDdF'},
      {'input' : 'AbCDeF', 'key': 'MN', 'autoKey': false, 'aValue': -26, 'expectedOutput' : 'MoOQqS'},
      {'input' : 'AbCDeF', 'key': 'MN', 'autoKey': false, 'aValue': -27, 'expectedOutput' : 'LnNPpR'},
      {'input' : 'AbCDeF', 'key': 'MN', 'autoKey': false, 'aValue': -52, 'expectedOutput' : 'MoOQqS'},
      {'input' : 'AbCDeF', 'key': 'mn', 'autoKey': true, 'aValue': 1, 'expectedOutput' : 'NpDFhJ'},
      {'input' : 'AbCDeF', 'key': 'mn', 'autoKey': true, 'aValue': 13, 'expectedOutput' : 'ZbPRtV'},
      {'input' : 'AbCDeF', 'key': 'mn', 'autoKey': true, 'aValue': 26, 'expectedOutput' : 'MoCEgI'},
      {'input' : 'AbCDeF', 'key': 'mn', 'autoKey': true, 'aValue': 27, 'expectedOutput' : 'NpDFhJ'},
      {'input' : 'AbCDeF', 'key': 'mn', 'autoKey': true, 'aValue': 52, 'expectedOutput' : 'MoCEgI'},
      {'input' : 'AbCDeF', 'key': 'mn', 'autoKey': true, 'aValue': -1, 'expectedOutput' : 'LnBDfH'},
      {'input' : 'AbCDeF', 'key': 'mn', 'autoKey': true, 'aValue': -13, 'expectedOutput' : 'ZbPRtV'},
      {'input' : 'AbCDeF', 'key': 'mn', 'autoKey': true, 'aValue': -26, 'expectedOutput' : 'MoCEgI'},
      {'input' : 'AbCDeF', 'key': 'mn', 'autoKey': true, 'aValue': -27, 'expectedOutput' : 'LnBDfH'},
      {'input' : 'AbCDeF', 'key': 'mn', 'autoKey': true, 'aValue': -52, 'expectedOutput' : 'MoCEgI'},
    ];

    _inputsToExpected.forEach((elem) {
      test('input: ${elem['input']}, key: ${elem['key']}, aValue: ${elem['aValue']}, autoKey: ${elem['autoKey']}', () {
        var _actual = encryptVigenere(elem['input'], elem['key'], elem['autoKey'], aValue: elem['aValue']);
        expect(_actual, elem['expectedOutput']);
      });
    });
  });

  group("Vigenere.decrypt:", () {
    List<Map<String, dynamic>> _inputsToExpected = [
      {'input' : null, 'key': null, 'autoKey': false, 'aValue': 0, 'expectedOutput' : ''},
      {'input' : null, 'key': 'ABC', 'autoKey': false, 'aValue': 0, 'expectedOutput' : ''},
      {'input' : 'ABC', 'key': null, 'autoKey': false, 'aValue': 0, 'expectedOutput' : 'ABC'},
      {'input' : '', 'key': '', 'autoKey': false, 'aValue': 0, 'expectedOutput' : ''},
      {'input' : '', 'key': 'ABC', 'autoKey': false, 'aValue': 0, 'expectedOutput' : ''},
      {'input' : 'ABC', 'key': '', 'autoKey': false, 'aValue': 0, 'expectedOutput' : 'ABC'},

      {'input' : 'MOQ', 'key': 'MNO', 'autoKey': false, 'aValue': 0, 'expectedOutput' : 'ABC'},
      {'input' : 'MOOQQS', 'key': 'MN', 'autoKey': false, 'aValue': 0, 'expectedOutput' : 'ABCDEF'},
      {'input' : 'MOCEGI', 'key': 'MN', 'autoKey': true, 'aValue': 0, 'expectedOutput' : 'ABCDEF'},

      {'input' : 'Moq', 'key': 'mnO', 'autoKey': false, 'aValue': 0, 'expectedOutput' : 'Abc'},
      {'input' : 'MoOQqS', 'key': 'MN', 'autoKey': false, 'aValue': 0, 'expectedOutput' : 'AbCDeF'},
      {'input' : 'MOcegI', 'key': 'mn', 'autoKey': true, 'aValue': 0, 'expectedOutput' : 'ABcdeF'},

      {'input' : 'Mo12q', 'key': 'mnO', 'autoKey': false, 'aValue': 0, 'expectedOutput' : 'Ab12c'},
      {'input' : ' M%67oO QqS_', 'key': 'MN', 'autoKey': false, 'aValue': 0, 'expectedOutput' : ' A%67bC DeF_'},
      {'input' : 'M Oce23gI', 'key': 'mn', 'autoKey': true, 'aValue': 0, 'expectedOutput' : 'A Bcd23eF'},

      {'expectedOutput' : 'AbCDeF', 'key': 'MN', 'autoKey': false, 'aValue': 1, 'input' : 'NpPRrT'},
      {'expectedOutput' : 'AbCDeF', 'key': 'MN', 'autoKey': false, 'aValue': 13, 'input' : 'ZbBDdF'},
      {'expectedOutput' : 'AbCDeF', 'key': 'MN', 'autoKey': false, 'aValue': 26, 'input' : 'MoOQqS'},
      {'expectedOutput' : 'AbCDeF', 'key': 'MN', 'autoKey': false, 'aValue': 27, 'input' : 'NpPRrT'},
      {'expectedOutput' : 'AbCDeF', 'key': 'MN', 'autoKey': false, 'aValue': 52, 'input' : 'MoOQqS'},
      {'expectedOutput' : 'AbCDeF', 'key': 'MN', 'autoKey': false, 'aValue': -1, 'input' : 'LnNPpR'},
      {'expectedOutput' : 'AbCDeF', 'key': 'MN', 'autoKey': false, 'aValue': -13, 'input' : 'ZbBDdF'},
      {'expectedOutput' : 'AbCDeF', 'key': 'MN', 'autoKey': false, 'aValue': -26, 'input' : 'MoOQqS'},
      {'expectedOutput' : 'AbCDeF', 'key': 'MN', 'autoKey': false, 'aValue': -27, 'input' : 'LnNPpR'},
      {'expectedOutput' : 'AbCDeF', 'key': 'MN', 'autoKey': false, 'aValue': -52, 'input' : 'MoOQqS'},
      {'expectedOutput' : 'AbCDeF', 'key': 'mn', 'autoKey': true, 'aValue': 1, 'input' : 'NpDFhJ'},
      {'expectedOutput' : 'AbCDeF', 'key': 'mn', 'autoKey': true, 'aValue': 13, 'input' : 'ZbPRtV'},
      {'expectedOutput' : 'AbCDeF', 'key': 'mn', 'autoKey': true, 'aValue': 26, 'input' : 'MoCEgI'},
      {'expectedOutput' : 'AbCDeF', 'key': 'mn', 'autoKey': true, 'aValue': 27, 'input' : 'NpDFhJ'},
      {'expectedOutput' : 'AbCDeF', 'key': 'mn', 'autoKey': true, 'aValue': 52, 'input' : 'MoCEgI'},
      {'expectedOutput' : 'AbCDeF', 'key': 'mn', 'autoKey': true, 'aValue': -1, 'input' : 'LnBDfH'},
      {'expectedOutput' : 'AbCDeF', 'key': 'mn', 'autoKey': true, 'aValue': -13, 'input' : 'ZbPRtV'},
      {'expectedOutput' : 'AbCDeF', 'key': 'mn', 'autoKey': true, 'aValue': -26, 'input' : 'MoCEgI'},
      {'expectedOutput' : 'AbCDeF', 'key': 'mn', 'autoKey': true, 'aValue': -27, 'input' : 'LnBDfH'},
      {'expectedOutput' : 'AbCDeF', 'key': 'mn', 'autoKey': true, 'aValue': -52, 'input' : 'MoCEgI'},
    ];

    _inputsToExpected.forEach((elem) {
      test('input: ${elem['input']}, key: ${elem['key']}, aValue: ${elem['aValue']}, autoKey: ${elem['autoKey']}', () {
        var _actual = decryptVigenere(elem['input'], elem['key'], elem['autoKey'], aValue: elem['aValue']);
        expect(_actual, elem['expectedOutput']);
      });
    });
  });
}