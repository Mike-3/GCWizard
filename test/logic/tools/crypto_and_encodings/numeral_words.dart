import "package:flutter_test/flutter_test.dart";
import 'package:gc_wizard/logic/tools/crypto_and_encodings/numeral_words.dart';
import 'package:gc_wizard/utils/common_utils.dart';

void main(){
  group("NumeralWords.decodeNumeralwordsEntireWordsALL:", () {
    List<Map<String, dynamic>> _inputsToExpected = [

      {'input' : 'huit dwa seize six one two eins', 'language' : NumeralWordsLanguage.ALL, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('8', 'huit', 'common_language_french'),
                            NumeralWordsDecodeOutput('2', 'dwa', 'common_language_polish'),
                            NumeralWordsDecodeOutput('', '', 'common_language_russian'),
                            NumeralWordsDecodeOutput('', '', 'common_language_bulgarian'),
                            NumeralWordsDecodeOutput('16', 'seize', 'common_language_french'),
                            NumeralWordsDecodeOutput('6', 'six', 'common_language_english'),
                            NumeralWordsDecodeOutput('', '', 'common_language_french'),
                            NumeralWordsDecodeOutput('1', 'one', 'common_language_english'),
                            NumeralWordsDecodeOutput('2', 'two', 'common_language_english'),
                            NumeralWordsDecodeOutput('1', 'eins', 'common_language_german')]},
      {'input' : 'fuenf fünf kvin cinq пять lul five zéro', 'language' : NumeralWordsLanguage.ALL, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('5', 'fuenf', 'common_language_german'),
                            NumeralWordsDecodeOutput('5', 'fuenf', 'common_language_german'),
                            NumeralWordsDecodeOutput('5', 'kvin', 'common_language_esperanto'),
                            NumeralWordsDecodeOutput('5', 'cinq', 'common_language_french'),
                            NumeralWordsDecodeOutput('5', 'пять', 'numeralwords_language_kyr'),
                            NumeralWordsDecodeOutput('5', 'lul', 'common_language_volapuek'),
                            NumeralWordsDecodeOutput('5', 'five', 'common_language_english'),
                            NumeralWordsDecodeOutput('', '', 'numeralwords_language_sco'),
                            NumeralWordsDecodeOutput('0', 'zero', 'common_language_english'),
                            NumeralWordsDecodeOutput('', '', 'common_language_french'),
                            NumeralWordsDecodeOutput('', '', 'common_language_italian'),
                            NumeralWordsDecodeOutput('', '', 'common_language_portuguese'),
                            NumeralWordsDecodeOutput('', '', 'common_language_polish'),
                            NumeralWordsDecodeOutput('', '', 'numeralwords_language_jap'),
                            NumeralWordsDecodeOutput('', '', 'numeralwords_language_meg'),
        ]},
    ];

    _inputsToExpected.forEach((elem) {
      test('input: ${elem['input']}, language: ${elem['language']}, decodeMode: ${elem['decodeMode']}', () {
        var _actual = decodeNumeralwords(input: removeAccents(elem['input'].toString().toLowerCase()), language: elem['language'], decodeModeWholeWords: elem['decodeMode']);
        var length = elem['expectedOutput'].length;
        for (int i = 0; i < length; i++) {
          expect(_actual[i].number, elem['expectedOutput'][i].number);
          expect(_actual[i].numWord, elem['expectedOutput'][i].numWord);
          expect(_actual[i].language, elem['expectedOutput'][i].language);
        }
      });
    });
  });

  group("NumeralWords.decodeNumeralwordsEntireWordsDEU:", () {
    List<Map<String, dynamic>> _inputsToExpected = [
      {'input' : '', 'language' : NumeralWordsLanguage.DEU, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('', '', 'numeralwords_language_empty')]},
      {'input' : 'fünfundzwanzig', 'language' : NumeralWordsLanguage.DEU, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('25', 'fuenfundzwanzig', 'common_language_german')]},
      {'input' : 'hundert', 'language' : NumeralWordsLanguage.DEU, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('100', 'hundert', 'common_language_german')]},
      {'input' : 'hunderteins', 'language' : NumeralWordsLanguage.DEU, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('101', 'hunderteins', 'common_language_german')]},
      {'input' : 'hundertundeins', 'language' : NumeralWordsLanguage.DEU, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('101', 'hunderteins', 'common_language_german')]},
      {'input' : 'einhundert', 'language' : NumeralWordsLanguage.DEU, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('100', 'einshundert', 'common_language_german')]},
      {'input' : 'einhunderteins', 'language' : NumeralWordsLanguage.DEU, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('101', 'einshunderteins', 'common_language_german')]},
      {'input' : 'einhundertundeins', 'language' : NumeralWordsLanguage.DEU, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('101', 'einshunderteins', 'common_language_german')]},
      {'input' : 'hundertfünfundzwanzig', 'language' : NumeralWordsLanguage.DEU, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('125', 'hundertfuenfundzwanzig', 'common_language_german')]},
      {'input' : 'abc einhundertfünfundzwanzig abc', 'language' : NumeralWordsLanguage.DEU, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('125', 'einshundertfuenfundzwanzig', 'common_language_german')]},
      {'input' : 'zweihundertfünfundzwanzig', 'language' : NumeralWordsLanguage.DEU, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('225', 'zweihundertfuenfundzwanzig', 'common_language_german')]},
      {'input' : 'tausend', 'language' : NumeralWordsLanguage.DEU, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('1000', 'tausend', 'common_language_german')]},
      {'input' : 'eintausend', 'language' : NumeralWordsLanguage.DEU, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('1000', 'einstausend', 'common_language_german')]},
      {'input' : 'zweitausend', 'language' : NumeralWordsLanguage.DEU, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('2000', 'zweitausend', 'common_language_german')]},
      {'input' : 'hunderttausend', 'language' : NumeralWordsLanguage.DEU, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('100000', 'hunderttausend', 'common_language_german')]},
      {'input' : 'hunderttausendhundert', 'language' : NumeralWordsLanguage.DEU, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('100100', 'hunderttausendhundert', 'common_language_german')]},
      {'input' : 'hunderttausendeinhundert', 'language' : NumeralWordsLanguage.DEU, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('100100', 'hunderttausendeinshundert', 'common_language_german')]},
      {'input' : 'hunderttausendhunderteins', 'language' : NumeralWordsLanguage.DEU, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('100101', 'hunderttausendhunderteins', 'common_language_german')]},
      {'input' : 'hunderttausendhundertundeins', 'language' : NumeralWordsLanguage.DEU, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('100101', 'hunderttausendhunderteins', 'common_language_german')]},
      {'input' : 'einhunderttausend', 'language' : NumeralWordsLanguage.DEU, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('100000', 'einshunderttausend', 'common_language_german')]},
      {'input' : 'einhunderttausendeins', 'language' : NumeralWordsLanguage.DEU, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('100001', 'einshunderttausendeins', 'common_language_german')]},
      {'input' : 'hunderteinstausendeins', 'language' : NumeralWordsLanguage.DEU, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('101001', 'hunderteinstausendeins', 'common_language_german')]},
      {'input' : 'hundertundeinstausendeins', 'language' : NumeralWordsLanguage.DEU, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('101001', 'hunderteinstausendeins', 'common_language_german')]},
      {'input' : 'einhundertundeinstausendeins', 'language' : NumeralWordsLanguage.DEU, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('101001', 'einshunderteinstausendeins', 'common_language_german')]},
      {'input' : 'einhunderttausendundeins', 'language' : NumeralWordsLanguage.DEU, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('100001', 'einshunderttausendeins', 'common_language_german')]},
      {'input' : 'zweihunderttausend', 'language' : NumeralWordsLanguage.DEU, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('200000', 'zweihunderttausend', 'common_language_german')]},
      {'input' : 'fünfundzwanzigtausendsiebenhundertzweiundvierzig', 'language' : NumeralWordsLanguage.DEU, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('25742', 'fuenfundzwanzigtausendsiebenhundertzweiundvierzig', 'common_language_german')]},
      {'input' : 'dreihundertdreiunddreißigtausenddreihundertunddreiunddreißig', 'language' : NumeralWordsLanguage.DEU, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('333333', 'dreihundertdreiunddreissigtausenddreihundertdreiunddreissig', 'common_language_german')]},

      {'input' : 'huit dwa seize six one two eins', 'language' : NumeralWordsLanguage.ALL, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('8', 'huit', 'common_language_french'),
          NumeralWordsDecodeOutput('2', 'dwa', 'common_language_polish'),
          NumeralWordsDecodeOutput('', '', 'common_language_russian'),
          NumeralWordsDecodeOutput('', '', 'common_language_bulgarian'),
          NumeralWordsDecodeOutput('16', 'seize', 'common_language_french'),
          NumeralWordsDecodeOutput('6', 'six', 'common_language_english'),
          NumeralWordsDecodeOutput('', '', 'common_language_french'),
          NumeralWordsDecodeOutput('1', 'one', 'common_language_english'),
          NumeralWordsDecodeOutput('2', 'two', 'common_language_english'),
          NumeralWordsDecodeOutput('1', 'eins', 'common_language_german')]},
      {'input' : 'fuenf fünf kvin cinq пять lul five zéro', 'language' : NumeralWordsLanguage.ALL, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('5', 'fuenf', 'common_language_german'),
          NumeralWordsDecodeOutput('5', 'fuenf', 'common_language_german'),
          NumeralWordsDecodeOutput('5', 'kvin', 'common_language_esperanto'),
          NumeralWordsDecodeOutput('5', 'cinq', 'common_language_french'),
          NumeralWordsDecodeOutput('5', 'пять', 'numeralwords_language_kyr'),
          NumeralWordsDecodeOutput('5', 'lul', 'common_language_volapuek'),
          NumeralWordsDecodeOutput('5', 'five', 'common_language_english'),
          NumeralWordsDecodeOutput('', '', 'numeralwords_language_sco'),
          NumeralWordsDecodeOutput('0', 'zero', 'common_language_english'),
          NumeralWordsDecodeOutput('', '', 'common_language_french'),
          NumeralWordsDecodeOutput('', '', 'common_language_italian'),
          NumeralWordsDecodeOutput('', '', 'common_language_portuguese'),
          NumeralWordsDecodeOutput('', '', 'common_language_polish'),
          NumeralWordsDecodeOutput('', '', 'numeralwords_language_jap'),
          NumeralWordsDecodeOutput('', '', 'numeralwords_language_meg'),
        ]},
    ];

    _inputsToExpected.forEach((elem) {
      test('input: ${elem['input']}, language: ${elem['language']}, decodeMode: ${elem['decodeMode']}', () {
        var _actual = decodeNumeralwords(input: removeAccents(elem['input'].toString().toLowerCase()), language: elem['language'], decodeModeWholeWords: elem['decodeMode']);
        var length = elem['expectedOutput'].length;
        for (int i = 0; i < length; i++) {
          expect(_actual[i].number, elem['expectedOutput'][i].number);
          expect(_actual[i].numWord, elem['expectedOutput'][i].numWord);
          expect(_actual[i].language, elem['expectedOutput'][i].language);
        }
      });
    });
  });

  group("NumeralWords.decodeNumeralwordsEntireWordsENG:", () {
    List<Map<String, dynamic>> _inputsToExpected = [
      {'input' : 'one', 'language' : NumeralWordsLanguage.ENG, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('1', 'one', 'common_language_english')]},
      {'input' : 'ten', 'language' : NumeralWordsLanguage.ENG, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('10', 'ten', 'common_language_english')]},
      {'input' : 'abc ten def one abc', 'language' : NumeralWordsLanguage.ENG, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('10', 'ten', 'common_language_english'),
          NumeralWordsDecodeOutput('1', 'one', 'common_language_english')]},

      {'input' : 'fifty', 'language' : NumeralWordsLanguage.ENG, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('50', 'fifty', 'common_language_english')]},
      {'input' : 'fiftyone', 'language' : NumeralWordsLanguage.ENG, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('51', 'fiftyone', 'common_language_english')]},
      {'input' : 'fifty-one', 'language' : NumeralWordsLanguage.ENG, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('51', 'fifty-one', 'common_language_english')]},
      {'input' : 'fifty one', 'language' : NumeralWordsLanguage.ENG, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('50', 'fifty', 'common_language_english'),
          NumeralWordsDecodeOutput('1', 'one', 'common_language_english')]},

      {'input' : 'hundred', 'language' : NumeralWordsLanguage.ENG, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('100', 'hundred', 'common_language_english')]},
      {'input' : 'a hundred', 'language' : NumeralWordsLanguage.ENG, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('100', 'onehundred', 'common_language_english')]},
      {'input' : 'one hundred', 'language' : NumeralWordsLanguage.ENG, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('100', 'onehundred', 'common_language_english')]},
      {'input' : 'onehundredfifty', 'language' : NumeralWordsLanguage.ENG, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('150', 'onehundredfifty', 'common_language_english')]},
      {'input' : 'one hundred fifty', 'language' : NumeralWordsLanguage.ENG, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('100', 'onehundred', 'common_language_english'),
          NumeralWordsDecodeOutput('50', 'fifty', 'common_language_english')]},

      {'input' : 'a hundred and fifty-five', 'language' : NumeralWordsLanguage.ENG, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('155', 'onehundredfifty-five', 'common_language_english')]},
      {'input' : 'two hundred and fifty-five', 'language' : NumeralWordsLanguage.ENG, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('255', 'twohundredfifty-five', 'common_language_english')]},
      {'input' : 'a hundred and fiftyfive', 'language' : NumeralWordsLanguage.ENG, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('155', 'onehundredfiftyfive', 'common_language_english')]},
      {'input' : 'two hundred and fiftyfive', 'language' : NumeralWordsLanguage.ENG, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('255', 'twohundredfiftyfive', 'common_language_english')]},

      {'input' : 'thousand', 'language' : NumeralWordsLanguage.ENG, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('1000', 'thousand', 'common_language_english')]},
      {'input' : 'a thousand', 'language' : NumeralWordsLanguage.ENG, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('1000', 'onethousand', 'common_language_english')]},
      {'input' : 'one thousand', 'language' : NumeralWordsLanguage.ENG, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('1000', 'onethousand', 'common_language_english')]},
      {'input' : 'one hundred thousand', 'language' : NumeralWordsLanguage.ENG, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('100000', 'onehundredthousand', 'common_language_english')]},
      {'input' : 'onethousandfifty', 'language' : NumeralWordsLanguage.ENG, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('1050', 'onethousandfifty', 'common_language_english')]},
      {'input' : 'one thousand fifty', 'language' : NumeralWordsLanguage.ENG, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('1000', 'onethousand', 'common_language_english'),
          NumeralWordsDecodeOutput('50', 'fifty', 'common_language_english')]},

      {'input' : 'a thousand and fifty-five', 'language' : NumeralWordsLanguage.ENG, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('1055', 'onethousandfifty-five', 'common_language_english')]},
      {'input' : 'two thousand and fifty-five', 'language' : NumeralWordsLanguage.ENG, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('2055', 'twothousandfifty-five', 'common_language_english')]},
      {'input' : 'a thousand and fiftyfive', 'language' : NumeralWordsLanguage.ENG, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('1055', 'onethousandfiftyfive', 'common_language_english')]},
      {'input' : 'two thousand and fiftyfive', 'language' : NumeralWordsLanguage.ENG, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('2055', 'twothousandfiftyfive', 'common_language_english')]},

      {'input' : 'thousandhundred', 'language' : NumeralWordsLanguage.ENG, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('1100', 'thousandhundred', 'common_language_english')]},
      {'input' : 'thousand hundred', 'language' : NumeralWordsLanguage.ENG, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('1000', 'thousand', 'common_language_english'),
          NumeralWordsDecodeOutput('100', 'hundred', 'common_language_english')]},
      {'input' : 'a thousand and hundred', 'language' : NumeralWordsLanguage.ENG, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('1100', 'onethousandhundred', 'common_language_english')]},
      {'input' : 'a thousand and onehundred', 'language' : NumeralWordsLanguage.ENG, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('1100', 'onethousandonehundred', 'common_language_english')]},
      {'input' : 'onethousand and onehundred', 'language' : NumeralWordsLanguage.ENG, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('1100', 'onethousandonehundred', 'common_language_english')]},
      {'input' : 'a hundredthousandhundred', 'language' : NumeralWordsLanguage.ENG, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('100100', 'onehundredthousandhundred', 'common_language_english')]},
      {'input' : 'a hundredthousandhundredone', 'language' : NumeralWordsLanguage.ENG, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('100101', 'onehundredthousandhundredone', 'common_language_english')]},
      {'input' : 'twohundredseventy-fivethousandhundred and one', 'language' : NumeralWordsLanguage.ENG, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('275101', 'twohundredseventy-fivethousandhundredone', 'common_language_english')]},
      {'input' : 'twohundredseventyfivethousandhundred and one', 'language' : NumeralWordsLanguage.ENG, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('275101', 'twohundredseventyfivethousandhundredone', 'common_language_english')]},
    ];

    _inputsToExpected.forEach((elem) {
      test('input: ${elem['input']}, language: ${elem['language']}, decodeMode: ${elem['decodeMode']}', () {
        var _actual = decodeNumeralwords(input: removeAccents(elem['input'].toString().toLowerCase()), language: elem['language'], decodeModeWholeWords: elem['decodeMode']);
        var length = elem['expectedOutput'].length;
        for (int i = 0; i < length; i++) {
          expect(_actual[i].number, elem['expectedOutput'][i].number);
          expect(_actual[i].numWord, elem['expectedOutput'][i].numWord);
          expect(_actual[i].language, elem['expectedOutput'][i].language);
        }
      });
    });
  });

  group("NumeralWords.decodeNumeralwordsEntireWordsAsParts:", () {
    List<Map<String, dynamic>> _inputsToExpected = [
      {'input' : '', 'language' : NumeralWordsLanguage.DEU, 'decodeMode' : false, 'expectedOutput' : ''},
      {'input' : 'fünfundzwanzig', 'language' : NumeralWordsLanguage.DEU, 'decodeMode' : false,
        'expectedOutput' : [NumeralWordsDecodeOutput('5', 'fuenf', 'common_language_german'),
                            NumeralWordsDecodeOutput('20', 'zwanzig', 'common_language_german')]},
      {'input' : 'hundert', 'language' : NumeralWordsLanguage.DEU, 'decodeMode' : false,
        'expectedOutput' : [NumeralWordsDecodeOutput('100', 'hundert', 'common_language_german')]},
      {'input' : 'hunderteins', 'language' : NumeralWordsLanguage.DEU, 'decodeMode' : false,
        'expectedOutput' : [NumeralWordsDecodeOutput('100', 'hundert', 'common_language_german'),
                            NumeralWordsDecodeOutput('1', 'eins', 'common_language_german')]},
      {'input' : 'hundertundeins', 'language' : NumeralWordsLanguage.DEU, 'decodeMode' : false,
        'expectedOutput' : [NumeralWordsDecodeOutput('100', 'hundert', 'common_language_german'),
                            NumeralWordsDecodeOutput('1', 'eins', 'common_language_german')]},
      {'input' : 'einhundert', 'language' : NumeralWordsLanguage.DEU, 'decodeMode' : false,
        'expectedOutput' : [NumeralWordsDecodeOutput('100', 'hundert', 'common_language_german')]},
      {'input' : 'einhunderteins', 'language' : NumeralWordsLanguage.DEU, 'decodeMode' : false,
        'expectedOutput' : [NumeralWordsDecodeOutput('100', 'hundert', 'common_language_german'),
                            NumeralWordsDecodeOutput('1', 'eins', 'common_language_german')]},
      {'input' : 'einhundertundeins', 'language' : NumeralWordsLanguage.DEU, 'decodeMode' : false,
        'expectedOutput' : [NumeralWordsDecodeOutput('100', 'hundert', 'common_language_german'),
                            NumeralWordsDecodeOutput('1', 'eins', 'common_language_german')]},
      {'input' : 'hundertfünfundzwanzig', 'language' : NumeralWordsLanguage.DEU, 'decodeMode' : false,
        'expectedOutput' : [NumeralWordsDecodeOutput('100', 'hundert', 'common_language_german'),
                            NumeralWordsDecodeOutput('5', 'fuenf', 'common_language_german'),
                            NumeralWordsDecodeOutput('20', 'zwanzig', 'common_language_german')]},
      {'input' : 'abc einhundertfünfundzwanzig abc', 'language' : NumeralWordsLanguage.DEU, 'decodeMode' : false,
        'expectedOutput' : [NumeralWordsDecodeOutput('100', 'hundert', 'common_language_german'),
                            NumeralWordsDecodeOutput('5', 'fuenf', 'common_language_german'),
                            NumeralWordsDecodeOutput('20', 'zwanzig', 'common_language_german')]},
      {'input' : 'zweihundertfünfundzwanzig', 'language' : NumeralWordsLanguage.DEU, 'decodeMode' : false,
        'expectedOutput' : [NumeralWordsDecodeOutput('2', 'zwei', 'common_language_german'),
                            NumeralWordsDecodeOutput('100', 'hundert', 'common_language_german'),
                            NumeralWordsDecodeOutput('5', 'fuenf', 'common_language_german'),
                            NumeralWordsDecodeOutput('20', 'zwanzig', 'common_language_german')]},
      {'input' : 'tausend', 'language' : NumeralWordsLanguage.DEU, 'decodeMode' : false,
        'expectedOutput' : [NumeralWordsDecodeOutput('1000', 'tausend', 'common_language_german')]},
      {'input' : 'eintausend', 'language' : NumeralWordsLanguage.DEU, 'decodeMode' : false,
        'expectedOutput' : [NumeralWordsDecodeOutput('1000', 'tausend', 'common_language_german')]},
      {'input' : 'zweitausend', 'language' : NumeralWordsLanguage.DEU, 'decodeMode' : false,
        'expectedOutput' : [NumeralWordsDecodeOutput('2', 'zwei', 'common_language_german'),
                            NumeralWordsDecodeOutput('1000', 'tausend', 'common_language_german')]},
      {'input' : 'hunderttausend', 'language' : NumeralWordsLanguage.DEU, 'decodeMode' : false,
        'expectedOutput' : [NumeralWordsDecodeOutput('100', 'hundert', 'common_language_german'),
                            NumeralWordsDecodeOutput('1000', 'tausend', 'common_language_german')]},
      {'input' : 'hunderttausendhundert', 'language' : NumeralWordsLanguage.DEU, 'decodeMode' : false,
        'expectedOutput' : [NumeralWordsDecodeOutput('100', 'hundert', 'common_language_german'),
                            NumeralWordsDecodeOutput('1000', 'tausend', 'common_language_german'),
                            NumeralWordsDecodeOutput('100', 'hundert', 'common_language_german')]},
      {'input' : 'hunderttausendeinhundert', 'language' : NumeralWordsLanguage.DEU, 'decodeMode' : false,
        'expectedOutput' : [NumeralWordsDecodeOutput('100', 'hundert', 'common_language_german'),
                            NumeralWordsDecodeOutput('1000', 'tausend', 'common_language_german'),
                            NumeralWordsDecodeOutput('100', 'hundert', 'common_language_german')]},
      {'input' : 'hunderttausendhunderteins', 'language' : NumeralWordsLanguage.DEU, 'decodeMode' : false,
        'expectedOutput' : [NumeralWordsDecodeOutput('100', 'hundert', 'common_language_german'),
                            NumeralWordsDecodeOutput('1000', 'tausend', 'common_language_german'),
                            NumeralWordsDecodeOutput('100', 'hundert', 'common_language_german'),
                            NumeralWordsDecodeOutput('1', 'eins', 'common_language_german')]},
      {'input' : 'hunderttausendhundertundeins', 'language' : NumeralWordsLanguage.DEU, 'decodeMode' : false,
        'expectedOutput' : [NumeralWordsDecodeOutput('100', 'hundert', 'common_language_german'),
                            NumeralWordsDecodeOutput('1000', 'tausend', 'common_language_german'),
                            NumeralWordsDecodeOutput('100', 'hundert', 'common_language_german'),
                            NumeralWordsDecodeOutput('1', 'eins', 'common_language_german')]},
      {'input' : 'einhunderttausend', 'language' : NumeralWordsLanguage.DEU, 'decodeMode' : false,
        'expectedOutput' : [NumeralWordsDecodeOutput('100', 'hundert', 'common_language_german'),
                            NumeralWordsDecodeOutput('1000', 'tausend', 'common_language_german')]},
      {'input' : 'einhunderttausendeins', 'language' : NumeralWordsLanguage.DEU, 'decodeMode' : false,
        'expectedOutput' : [NumeralWordsDecodeOutput('100', 'hundert', 'common_language_german'),
                            NumeralWordsDecodeOutput('1000', 'tausend', 'common_language_german'),
                            NumeralWordsDecodeOutput('1', 'eins', 'common_language_german')]},
      {'input' : 'hunderteinstausendeins', 'language' : NumeralWordsLanguage.DEU, 'decodeMode' : false,
        'expectedOutput' : [NumeralWordsDecodeOutput('100', 'hundert', 'common_language_german'),
                            NumeralWordsDecodeOutput('1', 'eins', 'common_language_german'),
                            NumeralWordsDecodeOutput('1000', 'tausend', 'common_language_german'),
                            NumeralWordsDecodeOutput('1', 'eins', 'common_language_german')]},
      {'input' : 'hundertundeinstausendeins', 'language' : NumeralWordsLanguage.DEU, 'decodeMode' : false,
        'expectedOutput' : [NumeralWordsDecodeOutput('100', 'hundert', 'common_language_german'),
                            NumeralWordsDecodeOutput('1', 'eins', 'common_language_german'),
                            NumeralWordsDecodeOutput('1000', 'tausend', 'common_language_german'),
                            NumeralWordsDecodeOutput('1', 'eins', 'common_language_german')]},
      {'input' : 'einhundertundeinstausendeins', 'language' : NumeralWordsLanguage.DEU, 'decodeMode' : false,
        'expectedOutput' : [NumeralWordsDecodeOutput('100', 'hundert', 'common_language_german'),
                            NumeralWordsDecodeOutput('1', 'eins', 'common_language_german'),
                            NumeralWordsDecodeOutput('1000', 'tausend', 'common_language_german'),
                            NumeralWordsDecodeOutput('1', 'eins', 'common_language_german')]},
      {'input' : 'einhunderttausendundeins', 'language' : NumeralWordsLanguage.DEU, 'decodeMode' : false,
        'expectedOutput' : [NumeralWordsDecodeOutput('100', 'hundert', 'common_language_german'),
                            NumeralWordsDecodeOutput('1000', 'tausend', 'common_language_german'),
                            NumeralWordsDecodeOutput('1', 'eins', 'common_language_german')]},
      {'input' : 'zweihunderttausend', 'language' : NumeralWordsLanguage.DEU, 'decodeMode' : false,
        'expectedOutput' : [NumeralWordsDecodeOutput('2', 'zwei', 'common_language_german'),
                            NumeralWordsDecodeOutput('100', 'hundert', 'common_language_german'),
                            NumeralWordsDecodeOutput('1000', 'tausend', 'common_language_german')]},
      {'input' : 'fünfundzwanzigtausendsiebenhundertzweiundvierzig', 'language' : NumeralWordsLanguage.DEU, 'decodeMode' : false,
        'expectedOutput' : [NumeralWordsDecodeOutput('5', 'fuenf', 'common_language_german'),
                            NumeralWordsDecodeOutput('20', 'zwanzig', 'common_language_german'),
                            NumeralWordsDecodeOutput('1000', 'tausend', 'common_language_german'),
                            NumeralWordsDecodeOutput('7', 'sieben', 'common_language_german'),
                            NumeralWordsDecodeOutput('100', 'hundert', 'common_language_german'),
                            NumeralWordsDecodeOutput('2', 'zwei', 'common_language_german'),
                            NumeralWordsDecodeOutput('4', 'vier', 'common_language_german')]},

      {'input' : 'one', 'language' : NumeralWordsLanguage.ENG, 'decodeMode' : false,
        'expectedOutput' : [NumeralWordsDecodeOutput('1', 'one', 'common_language_english')]},
      {'input' : 'ten', 'language' : NumeralWordsLanguage.ENG, 'decodeMode' : false,
        'expectedOutput' : [NumeralWordsDecodeOutput('10', 'ten', 'common_language_english')]},
      {'input' : 'abc ten def one abc', 'language' : NumeralWordsLanguage.ENG, 'decodeMode' : false,
        'expectedOutput' : [NumeralWordsDecodeOutput('10', 'ten', 'common_language_english'),
                            NumeralWordsDecodeOutput('1', 'one', 'common_language_english')]},

      {'input' : 'fifty', 'language' : NumeralWordsLanguage.ENG, 'decodeMode' : false,
        'expectedOutput' : [NumeralWordsDecodeOutput('50', 'fifty', 'common_language_english')]},
      {'input' : 'fiftyone', 'language' : NumeralWordsLanguage.ENG, 'decodeMode' : false,
        'expectedOutput' : [NumeralWordsDecodeOutput('50', 'fifty', 'common_language_english'),
                            NumeralWordsDecodeOutput('1', 'one', 'common_language_english')]},
      {'input' : 'fifty-one', 'language' : NumeralWordsLanguage.ENG, 'decodeMode' : false,
        'expectedOutput' : [NumeralWordsDecodeOutput('50', 'fifty', 'common_language_english'),
                            NumeralWordsDecodeOutput('1', 'one', 'common_language_english')]},
      {'input' : 'fifty one', 'language' : NumeralWordsLanguage.ENG, 'decodeMode' : false,
        'expectedOutput' : [NumeralWordsDecodeOutput('50', 'fifty', 'common_language_english'),
                            NumeralWordsDecodeOutput('1', 'one', 'common_language_english')]},

      {'input' : 'hundred', 'language' : NumeralWordsLanguage.ENG, 'decodeMode' : false,
        'expectedOutput' : [NumeralWordsDecodeOutput('100', 'hundred', 'common_language_english')]},
      {'input' : 'a hundred', 'language' : NumeralWordsLanguage.ENG, 'decodeMode' : false,
        'expectedOutput' : [NumeralWordsDecodeOutput('100', 'hundred', 'common_language_english')]},
      {'input' : 'one hundred', 'language' : NumeralWordsLanguage.ENG, 'decodeMode' : false,
        'expectedOutput' : [NumeralWordsDecodeOutput('1', 'one', 'common_language_english'),
                            NumeralWordsDecodeOutput('100', 'hundred', 'common_language_english')]},
      {'input' : 'onehundredfifty', 'language' : NumeralWordsLanguage.ENG, 'decodeMode' : false,
        'expectedOutput' : [NumeralWordsDecodeOutput('1', 'one', 'common_language_english'),
                            NumeralWordsDecodeOutput('100', 'hundred', 'common_language_english'),
                            NumeralWordsDecodeOutput('50', 'fifty', 'common_language_english')]},
      {'input' : 'one hundred fifty', 'language' : NumeralWordsLanguage.ENG, 'decodeMode' : false,
        'expectedOutput' : [NumeralWordsDecodeOutput('1', 'one', 'common_language_english'),
                            NumeralWordsDecodeOutput('100', 'hundred', 'common_language_english'),
                            NumeralWordsDecodeOutput('50', 'fifty', 'common_language_english')]},
      {'input' : 'a hundred and fifty-five', 'language' : NumeralWordsLanguage.ENG, 'decodeMode' : false,
        'expectedOutput' : [NumeralWordsDecodeOutput('100', 'hundred', 'common_language_english'),
                            NumeralWordsDecodeOutput('50', 'fifty', 'common_language_english') ,
                            NumeralWordsDecodeOutput('5', 'five', 'common_language_english')]},
      {'input' : 'two hundred and fifty-five', 'language' : NumeralWordsLanguage.ENG, 'decodeMode' : false,
        'expectedOutput' : [NumeralWordsDecodeOutput('2', 'two', 'common_language_english'),
                            NumeralWordsDecodeOutput('100', 'hundred', 'common_language_english'),
                            NumeralWordsDecodeOutput('50', 'fifty', 'common_language_english') ,
                            NumeralWordsDecodeOutput('5', 'five', 'common_language_english')]},

      {'input' : 'thousand', 'language' : NumeralWordsLanguage.ENG, 'decodeMode' : false,
        'expectedOutput' : [NumeralWordsDecodeOutput('1000', 'thousand', 'common_language_english')]},
      {'input' : 'a thousand', 'language' : NumeralWordsLanguage.ENG, 'decodeMode' : false,
        'expectedOutput' : [NumeralWordsDecodeOutput('1000', 'thousand', 'common_language_english')]},
      {'input' : 'one thousand', 'language' : NumeralWordsLanguage.ENG, 'decodeMode' : false,
        'expectedOutput' : [NumeralWordsDecodeOutput('1', 'one', 'common_language_english'),
                            NumeralWordsDecodeOutput('1000', 'thousand', 'common_language_english')]},
      {'input' : 'onethousandfifty', 'language' : NumeralWordsLanguage.ENG, 'decodeMode' : false,
        'expectedOutput' : [NumeralWordsDecodeOutput('1', 'one', 'common_language_english'),
                            NumeralWordsDecodeOutput('1000', 'thousand', 'common_language_english'),
                            NumeralWordsDecodeOutput('50', 'fifty', 'common_language_english')]},
      {'input' : 'one thousand fifty', 'language' : NumeralWordsLanguage.ENG, 'decodeMode' : false,
        'expectedOutput' : [NumeralWordsDecodeOutput('1', 'one', 'common_language_english'),
                            NumeralWordsDecodeOutput('1000', 'thousand', 'common_language_english'),
                            NumeralWordsDecodeOutput('50', 'fifty', 'common_language_english')]},
      {'input' : 'a thousand and fifty-five', 'language' : NumeralWordsLanguage.ENG, 'decodeMode' : false,
        'expectedOutput' : [NumeralWordsDecodeOutput('1000', 'thousand', 'common_language_english'),
                            NumeralWordsDecodeOutput('50', 'fifty', 'common_language_english'),
                            NumeralWordsDecodeOutput('5', 'five', 'common_language_english')]},
      {'input' : 'two thousand and fifty-five', 'language' : NumeralWordsLanguage.ENG, 'decodeMode' : false,
        'expectedOutput' : [NumeralWordsDecodeOutput('2', 'two', 'common_language_english'),
                            NumeralWordsDecodeOutput('1000', 'thousand', 'common_language_english'),
                            NumeralWordsDecodeOutput('50', 'fifty', 'common_language_english'),
                            NumeralWordsDecodeOutput('5', 'five', 'common_language_english')]},

      {'input' : 'thousandhundred', 'language' : NumeralWordsLanguage.ENG, 'decodeMode' : false,
        'expectedOutput' : [NumeralWordsDecodeOutput('1000', 'thousand', 'common_language_english'),
                            NumeralWordsDecodeOutput('100', 'hundred', 'common_language_english'),]},
      {'input' : 'thousand hundred', 'language' : NumeralWordsLanguage.ENG, 'decodeMode' : false,
        'expectedOutput' : [NumeralWordsDecodeOutput('1000', 'thousand', 'common_language_english'),
                            NumeralWordsDecodeOutput('100', 'hundred', 'common_language_english'),]},
      {'input' : 'a thousand and hundred', 'language' : NumeralWordsLanguage.ENG, 'decodeMode' : false,
        'expectedOutput' : [NumeralWordsDecodeOutput('1000', 'thousand', 'common_language_english'),
                            NumeralWordsDecodeOutput('100', 'hundred', 'common_language_english'),]},
      {'input' : 'a thousand and onehundred', 'language' : NumeralWordsLanguage.ENG, 'decodeMode' : false,
        'expectedOutput' : [NumeralWordsDecodeOutput('1000', 'thousand', 'common_language_english'),
                            NumeralWordsDecodeOutput('1', 'one', 'common_language_english'),
                            NumeralWordsDecodeOutput('100', 'hundred', 'common_language_english'),]},
      {'input' : 'onethousand and onehundred', 'language' : NumeralWordsLanguage.ENG, 'decodeMode' : false,
        'expectedOutput' : [NumeralWordsDecodeOutput('1', 'one', 'common_language_english'),
                            NumeralWordsDecodeOutput('1000', 'thousand', 'common_language_english'),
                            NumeralWordsDecodeOutput('1', 'one', 'common_language_english'),
                            NumeralWordsDecodeOutput('100', 'hundred', 'common_language_english')]},
      {'input' : 'a hundredthousandhundred', 'language' : NumeralWordsLanguage.ENG, 'decodeMode' : false,
        'expectedOutput' : [NumeralWordsDecodeOutput('100', 'hundred', 'common_language_english'),
                            NumeralWordsDecodeOutput('1000', 'thousand', 'common_language_english'),
                            NumeralWordsDecodeOutput('100', 'hundred', 'common_language_english')]},
      {'input' : 'a hundredthousandhundredone', 'language' : NumeralWordsLanguage.ENG, 'decodeMode' : false,
        'expectedOutput' : [NumeralWordsDecodeOutput('100', 'hundred', 'common_language_english'),
                            NumeralWordsDecodeOutput('1000', 'thousand', 'common_language_english'),
                            NumeralWordsDecodeOutput('100', 'hundred', 'common_language_english'),
                            NumeralWordsDecodeOutput('1', 'one', 'common_language_english')]},
      {'input' : 'twohundredseventy-fivethousandhundredandone', 'language' : NumeralWordsLanguage.ENG, 'decodeMode' : false,
        'expectedOutput' : [NumeralWordsDecodeOutput('2', 'two', 'common_language_english'),
                            NumeralWordsDecodeOutput('100', 'hundred', 'common_language_english'),
                            NumeralWordsDecodeOutput('7', 'seven', 'common_language_english'),
                            NumeralWordsDecodeOutput('70', 'seventy', 'common_language_english'),
                            NumeralWordsDecodeOutput('5', 'five', 'common_language_english'),
                            NumeralWordsDecodeOutput('1000', 'thousand', 'common_language_english'),
                            NumeralWordsDecodeOutput('100', 'hundred', 'common_language_english'),
                            NumeralWordsDecodeOutput('1', 'one', 'common_language_english')]},

      {'input' : 'huit cinq seize sis one two eins', 'language' : NumeralWordsLanguage.ALL, 'decodeMode' : false,
        'expectedOutput' : [NumeralWordsDecodeOutput('8', 'huit', 'common_language_french'),
                            NumeralWordsDecodeOutput('2', 'i', 'common_language_sino_korean'),
                            NumeralWordsDecodeOutput('5', 'cinq', 'common_language_french'),
                            NumeralWordsDecodeOutput('3', 'ci', 'numeralwords_language_loj'),
                            NumeralWordsDecodeOutput('2', 'i', 'common_language_sino_korean'),
                            NumeralWordsDecodeOutput('16', 'seize', 'common_language_french'),
                            NumeralWordsDecodeOutput('6', 'sei', 'numeralwords_language_bas'),
                            NumeralWordsDecodeOutput('6', 'sei', 'common_language_italian'),
                            NumeralWordsDecodeOutput('3', 'se', 'common_language_korean'),
                            NumeralWordsDecodeOutput('3', 'se', 'numeralwords_language_per'),
                            NumeralWordsDecodeOutput('2', 'i', 'common_language_sino_korean'),
                            NumeralWordsDecodeOutput('6', 'zes', 'common_language_dutch'),
                            NumeralWordsDecodeOutput('7', 'ze', 'numeralwords_language_loj'),
                            NumeralWordsDecodeOutput('4', 'si', 'numeralwords_language_chi'),
                            NumeralWordsDecodeOutput('', 'si', 'common_language_thai_rtgs'),
                            NumeralWordsDecodeOutput('2', 'i', 'common_language_sino_korean'),
                            NumeralWordsDecodeOutput('9', 'so', 'numeralwords_language_loj'),
                            NumeralWordsDecodeOutput('1', 'one', 'common_language_english'),
                            NumeralWordsDecodeOutput('100', 'on', 'common_language_korean'),
                            NumeralWordsDecodeOutput('5', 'o', 'common_language_sino_korean'),
                            NumeralWordsDecodeOutput('10', 'on', 'numeralwords_language_tur'),
                            NumeralWordsDecodeOutput('4', 'net', 'common_language_korean'),
                            NumeralWordsDecodeOutput('', 'ne', 'common_language_korean'),
                            NumeralWordsDecodeOutput('2', 'two', 'common_language_english'),
                            NumeralWordsDecodeOutput('5', 'o', 'common_language_sino_korean'),
                            NumeralWordsDecodeOutput('1', 'eins', 'common_language_german'),
                            NumeralWordsDecodeOutput('2', 'i', 'common_language_sino_korean'),
        ]},
    ];

    _inputsToExpected.forEach((elem) {
      test('input: ${elem['input']}, language: ${elem['language']}, decodeMode: ${elem['decodeMode']}', () {
        var _actual = decodeNumeralwords(input: removeAccents(elem['input'].toString().toLowerCase()), language: elem['language'], decodeModeWholeWords: elem['decodeMode']);
        var length = elem['expectedOutput'].length;
        for (int i = 0; i < length; i++) {
          expect(_actual[i].number, elem['expectedOutput'][i].number);
          expect(_actual[i].numWord, elem['expectedOutput'][i].numWord);
          expect(_actual[i].language, elem['expectedOutput'][i].language);
        }
      });
    });
  });

  group("NumeralWords.decodeNumeralwordsWordParts:", () {
    List<Map<String, dynamic>> _inputsToExpected = [
      {'input' : 'Susi wacht einsam während Vater und Mutter zweifelnd Sand sieben. Null Bock, denkt sich Jörg. Ich lasse fünfe grade sein und kegel lieber alle Neune!', 'language' : NumeralWordsLanguage.DEU, 'decodeMode' : false,
        'expectedOutput' : [
          NumeralWordsDecodeOutput('8', 'acht', 'common_language_german'),
          NumeralWordsDecodeOutput('1', 'eins', 'common_language_german'),
          NumeralWordsDecodeOutput('2', 'zwei', 'common_language_german'),
          NumeralWordsDecodeOutput('7', 'sieben', 'common_language_german'),
          NumeralWordsDecodeOutput('0', 'null', 'common_language_german'),
          NumeralWordsDecodeOutput('5', 'fuenf', 'common_language_german'),
          NumeralWordsDecodeOutput('°', 'grad', 'common_language_german'),
          NumeralWordsDecodeOutput('9', 'neun', 'common_language_german')]},

      {'input' : 'Hui trällert Balthasar. Null Bock auf nichts sondern den Sessel hüten um nicht die gute Laune zu verlieren. Und wahrlich, das ist ok.', 'language' : NumeralWordsLanguage.ALL, 'decodeMode' : false,
        'expectedOutput' : [
          NumeralWordsDecodeOutput('8', 'huit', 'common_language_french'),
          NumeralWordsDecodeOutput('2', 'i', 'common_language_sino_korean'),
          NumeralWordsDecodeOutput('1', 'ae', 'numeralwords_language_sco'),
          NumeralWordsDecodeOutput('2', 'er', 'numeralwords_language_chi'),
          NumeralWordsDecodeOutput('8', 'ba', 'numeralwords_language_chi'),
          NumeralWordsDecodeOutput('1', 'bal', 'common_language_volapuek'),
          NumeralWordsDecodeOutput('3', 'ba', 'numeralwords_language_vie'),
          NumeralWordsDecodeOutput('5', 'ha', 'common_language_thai_rtgs'),
          NumeralWordsDecodeOutput('4', 'sa', 'common_language_sino_korean'),
          NumeralWordsDecodeOutput('0', 'null', 'common_language_german'),
          NumeralWordsDecodeOutput('', 'nul', 'common_language_dutch'),
          NumeralWordsDecodeOutput('', 'nul', 'common_language_danish'),
          NumeralWordsDecodeOutput('', 'nul', 'common_language_norwegian'),
          NumeralWordsDecodeOutput('', 'nul', 'common_language_russian'),
          NumeralWordsDecodeOutput('5', 'o', 'common_language_sino_korean'),
          NumeralWordsDecodeOutput('9', 'ni', 'common_language_danish'),
          NumeralWordsDecodeOutput('', 'ni', 'common_language_norwegian'),
          NumeralWordsDecodeOutput('2', 'ni', 'numeralwords_language_jap'),
          NumeralWordsDecodeOutput('2', 'i', 'common_language_sino_korean'),
          NumeralWordsDecodeOutput('9', 'so', 'numeralwords_language_loj'),
          NumeralWordsDecodeOutput('100', 'on', 'common_language_korean'),
          NumeralWordsDecodeOutput('5', 'o', 'common_language_sino_korean'),
          NumeralWordsDecodeOutput('10', 'on', 'numeralwords_language_tur'),
          NumeralWordsDecodeOutput('2', 'er', 'numeralwords_language_chi'),
          NumeralWordsDecodeOutput('1', 'en', 'common_language_danish'),
          NumeralWordsDecodeOutput('', 'en', 'common_language_norwegian'),
          NumeralWordsDecodeOutput('', 'en', 'common_language_swedish'),
          NumeralWordsDecodeOutput('3', 'se', 'common_language_korean'),
          NumeralWordsDecodeOutput('6', 'ses', 'common_language_esperanto'),
          NumeralWordsDecodeOutput('', 'se', 'numeralwords_language_per'),
          NumeralWordsDecodeOutput('3', 'se', 'common_language_korean'),
          NumeralWordsDecodeOutput('', 'se', 'numeralwords_language_per'),
          NumeralWordsDecodeOutput('10', 'ten', 'common_language_english'),
          NumeralWordsDecodeOutput('1', 'en', 'common_language_danish'),
          NumeralWordsDecodeOutput('', 'en', 'common_language_norwegian'),
          NumeralWordsDecodeOutput('', 'en', 'common_language_swedish'),
          NumeralWordsDecodeOutput('1', 'um', 'common_language_portuguese'),
          NumeralWordsDecodeOutput('9', 'ni', 'common_language_danish'),
          NumeralWordsDecodeOutput('', 'ni', 'common_language_norwegian'),
          NumeralWordsDecodeOutput('2', 'ni', 'numeralwords_language_jap'),
          NumeralWordsDecodeOutput('2', 'i', 'common_language_sino_korean'),
          NumeralWordsDecodeOutput('2', 'i', 'common_language_sino_korean'),
          NumeralWordsDecodeOutput('9', 'gu', 'common_language_sino_korean'),
          NumeralWordsDecodeOutput('2', 'tel', 'common_language_volapuek'),
          NumeralWordsDecodeOutput('4', 'lau', 'numeralwords_language_bas'),
          NumeralWordsDecodeOutput('1', 'un', 'common_language_french'),
          NumeralWordsDecodeOutput('', 'une', 'common_language_french'),
          NumeralWordsDecodeOutput('4', 'ne', 'common_language_korean'),
          NumeralWordsDecodeOutput('2', 'er', 'numeralwords_language_chi'),
          NumeralWordsDecodeOutput('2', 'i', 'common_language_sino_korean'),
          NumeralWordsDecodeOutput('2', 'er', 'numeralwords_language_chi'),
          NumeralWordsDecodeOutput('2', 're', 'numeralwords_language_loj'),
          NumeralWordsDecodeOutput('1', 'en', 'common_language_danish'),
          NumeralWordsDecodeOutput('', 'en', 'common_language_norwegian'),
          NumeralWordsDecodeOutput('', 'en', 'common_language_swedish'),
          NumeralWordsDecodeOutput('1', 'un', 'common_language_french'),
          NumeralWordsDecodeOutput('2', 'dwa', 'common_language_polish'),
          NumeralWordsDecodeOutput('', 'dwa', 'common_language_russian'),
          NumeralWordsDecodeOutput('', 'dwa', 'common_language_bulgarian'),
          NumeralWordsDecodeOutput('2', 'i', 'common_language_sino_korean'),
          NumeralWordsDecodeOutput('4', 'si', 'numeralwords_language_chi'),
          NumeralWordsDecodeOutput('', 'si', 'common_language_thai_rtgs'),
          NumeralWordsDecodeOutput('2', 'i', 'common_language_sino_korean'),
          NumeralWordsDecodeOutput('100', 'sto', 'common_language_polish'),
          NumeralWordsDecodeOutput('', 'sto', 'common_language_russian'),
          NumeralWordsDecodeOutput('', 'sto', 'common_language_bulgarian'),
          NumeralWordsDecodeOutput('2', 'to', 'common_language_danish'),
          NumeralWordsDecodeOutput('', 'to', 'common_language_norwegian'),
          NumeralWordsDecodeOutput('5', 'o', 'common_language_sino_korean'),
          NumeralWordsDecodeOutput('8', 'ok', 'common_language_esperanto'),
        ]},

      {'input' : 'Gen Norden wand er sich. Zweiundfünfzig Tage lang wanderte er an der Elbe entlang. Als die Gegend immer flacher wurde, kam er ins Grübeln. Da er sich nicht auskannte, fragte er mal diesen und mal jenen Einheimischen, wo es in diesen Landen Berge geben konnte. Erst der fünfundzwanzigste verriet ihm, dass es weiter östlich ein paar Berge neben einem großen See gab. Erleichtert gab Rübezahl dem Mann als Dank vierhundertunddreißig Taler. Rübezahl wand sich also nach Osten und wanderte weiter durch dieses Land. Im Morgengrauen des dreizehnten Tages kam er an einer großen Siedlung vorbei, die an einer Wasserkreuzung mit drei Flussarmen lag und sieben Brücken hatte. Hinter der Siedlung, zwischen zwei der drei Flussarme, entdeckte er einen großen See. Dies musste der See sein, von dem ihm erzählt wurde. Als sich der Morgennebel lichtete, erblickte er hinter dem See eine Bergkette, bestehend aus 2 Gipfeln. Der eine war dreihundertfünfundneunzig und der andere gar vierhundertundfünfundsechzig Meter hoch. Für diese Gegend also zusammen gewaltige … Meter. Schnellen Schrittes erreichte er den Fuß der Bergkette. Er suchte eine Weile nach einem passenden Versteck für sein Goldenes Drachenei. An einer flachen, offenen Stelle wurde er eines Wegelagerers gewahr. Er belegte ihn mit einem tausendjährigen TAPIR-Fluch und verbannte ihn in ein enges Grab, bewacht von 7 schwarz-weißen. Unbemerkt konnte er nun ein geeignetes Objekt finden, um sein Goldenes Drachenei darin zu verstecken. Zur Absicherung baute er noch ein paar Hürden ein, und sicherte das Ganze noch mit einem Schloss.', 'language' : NumeralWordsLanguage.DEU, 'decodeMode' : true,
        'expectedOutput' : [
          NumeralWordsDecodeOutput('.', '.', ''),
          NumeralWordsDecodeOutput('52', 'zweiundfuenfzig', 'common_language_german'),
          NumeralWordsDecodeOutput('.', '.', ''),
          NumeralWordsDecodeOutput('.', '.', ''),
          NumeralWordsDecodeOutput('.', '.', ''),
          NumeralWordsDecodeOutput('25', 'fuenfundzwanzig', 'common_language_german'),
          NumeralWordsDecodeOutput('.', '.', ''),
          NumeralWordsDecodeOutput('430', 'vierhundertdreissig', 'common_language_german'),
          NumeralWordsDecodeOutput('.', '.', ''),
          NumeralWordsDecodeOutput('.', '.', ''),
          NumeralWordsDecodeOutput('13', 'dreizehn', 'common_language_german'),
          NumeralWordsDecodeOutput('3', 'drei', 'common_language_german'),
          NumeralWordsDecodeOutput('7', 'sieben', 'common_language_german'),
          NumeralWordsDecodeOutput('.', '.', ''),
          NumeralWordsDecodeOutput('2', 'zwei', 'common_language_german'),
          NumeralWordsDecodeOutput('3', 'drei', 'common_language_german'),
          NumeralWordsDecodeOutput('.', '.', ''),
          NumeralWordsDecodeOutput('.', '.', ''),
          NumeralWordsDecodeOutput('2', '2', 'numeralwords_language_num'),
          NumeralWordsDecodeOutput('.', '.', ''),
          NumeralWordsDecodeOutput('395', 'dreihundertfuenfundneunzig', 'common_language_german'),
          NumeralWordsDecodeOutput('465', 'vierhundertfuenfundsechzig', 'common_language_german'),
          NumeralWordsDecodeOutput('.', '.', ''),
          NumeralWordsDecodeOutput('.', '.', ''),
          NumeralWordsDecodeOutput('.', '.', ''),
          NumeralWordsDecodeOutput('.', '.', ''),
          NumeralWordsDecodeOutput('.', '.', ''),
          NumeralWordsDecodeOutput('7', '7', 'numeralwords_language_num'),
          NumeralWordsDecodeOutput('.', '.', ''),
          NumeralWordsDecodeOutput('.', '.', ''),
          NumeralWordsDecodeOutput('.', '.', ''),
        ]},

      {'input' : 'einszwei', 'language' : NumeralWordsLanguage.DEU, 'decodeMode' : false,
        'expectedOutput' : [NumeralWordsDecodeOutput('1', 'eins', 'common_language_german'),
                            NumeralWordsDecodeOutput('2', 'zwei', 'common_language_german')]},
      {'input' : 'einszw', 'language' : NumeralWordsLanguage.DEU, 'decodeMode' : false,
        'expectedOutput' : [NumeralWordsDecodeOutput('1', 'eins', 'common_language_german')]},
      {'input' : 'abczweihundert', 'language' : NumeralWordsLanguage.DEU, 'decodeMode' : false,
        'expectedOutput' : [NumeralWordsDecodeOutput('2', 'zwei', 'common_language_german'),
                            NumeralWordsDecodeOutput('100', 'hundert', 'common_language_german')]},
      {'input' : 'abchundert', 'language' : NumeralWordsLanguage.DEU, 'decodeMode' : false,
        'expectedOutput' : [NumeralWordsDecodeOutput('100', 'hundert', 'common_language_german')]},
      {'input' : 'abceinhundert', 'language' : NumeralWordsLanguage.DEU, 'decodeMode' : false,
        'expectedOutput' : [NumeralWordsDecodeOutput('100', 'hundert', 'common_language_german')]},

      {'input' : 'abchundred', 'language' : NumeralWordsLanguage.ENG, 'decodeMode' : false,
        'expectedOutput' : [NumeralWordsDecodeOutput('100', 'hundred', 'common_language_english')]},
      {'input' : 'abc hundreddef', 'language' : NumeralWordsLanguage.ENG, 'decodeMode' : false,
        'expectedOutput' : [NumeralWordsDecodeOutput('100', 'hundred', 'common_language_english')]},
      {'input' : 'abconehundreddef def', 'language' : NumeralWordsLanguage.ENG, 'decodeMode' : false,
        'expectedOutput' : [NumeralWordsDecodeOutput('1', 'one', 'common_language_english'),
                            NumeralWordsDecodeOutput('100', 'hundred', 'common_language_english')]},
      {'input' : 'onehundredfiftydef', 'language' : NumeralWordsLanguage.ENG, 'decodeMode' : false,
        'expectedOutput' : [NumeralWordsDecodeOutput('1', 'one', 'common_language_english'),
                            NumeralWordsDecodeOutput('100', 'hundred', 'common_language_english'),
                            NumeralWordsDecodeOutput('50', 'fifty', 'common_language_english')]},
      {'input' : 'abcone hundred fiftydef', 'language' : NumeralWordsLanguage.ENG, 'decodeMode' : false,
        'expectedOutput' : [NumeralWordsDecodeOutput('1', 'one', 'common_language_english'),
                            NumeralWordsDecodeOutput('100', 'hundred', 'common_language_english'),
                            NumeralWordsDecodeOutput('50', 'fifty', 'common_language_english')]},
      {'input' : 'abca hundred and fifty-fivedef', 'language' : NumeralWordsLanguage.ENG, 'decodeMode' : false,
        'expectedOutput' : [NumeralWordsDecodeOutput('100', 'hundred', 'common_language_english'),
                            NumeralWordsDecodeOutput('50', 'fifty', 'common_language_english'),
                            NumeralWordsDecodeOutput('5', 'five', 'common_language_english')]},
      {'input' : 'abctwo hundred and fifty-fivedef', 'language' : NumeralWordsLanguage.ENG, 'decodeMode' : false,
        'expectedOutput' : [NumeralWordsDecodeOutput('2', 'two', 'common_language_english'),
                            NumeralWordsDecodeOutput('100', 'hundred', 'common_language_english'),
                            NumeralWordsDecodeOutput('50', 'fifty', 'common_language_english'),
                            NumeralWordsDecodeOutput('5', 'five', 'common_language_english')]},
    ];

    _inputsToExpected.forEach((elem) {
      test('input: ${elem['input']}, language: ${elem['language']}, decodeMode: ${elem['decodeMode']}', () {
        var _actual = decodeNumeralwords(input: removeAccents(elem['input'].toString().toLowerCase()), language: elem['language'], decodeModeWholeWords: elem['decodeMode']);
        var length = elem['expectedOutput'].length;
        for (int i = 0; i < length; i++) {
          expect(_actual[i].number, elem['expectedOutput'][i].number);
          expect(_actual[i].numWord, elem['expectedOutput'][i].numWord);
          expect(_actual[i].language, elem['expectedOutput'][i].language);
        }
      });
    });
  });

  group("NumeralWords.decodeNumeralwordsEntireWordsVOL:", () {
    List<Map<String, dynamic>> _inputsToExpected = [
      {'input' : '', 'language' : NumeralWordsLanguage.VOL, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('', '', 'numeralwords_language_empty')]},
      {'input' : 'fünfundzwanzig', 'language' : NumeralWordsLanguage.VOL, 'decodeMode' : true,
        'expectedOutput' : []},

      {'input' : 'degbal', 'language' : NumeralWordsLanguage.VOL, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('11', 'degbal', 'common_language_volapuek')]},
      {'input' : 'teldegtel', 'language' : NumeralWordsLanguage.VOL, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('22', 'teldegtel', 'common_language_volapuek')]},
      {'input' : 'tumteldegkil', 'language' : NumeralWordsLanguage.VOL, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('123', 'tumteldegkil', 'common_language_volapuek')]},
      {'input' : 'teldegfol', 'language' : NumeralWordsLanguage.VOL, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('24', 'teldegfol', 'common_language_volapuek')]},
      {'input' : 'telmil kiltumfoldeglul', 'language' : NumeralWordsLanguage.VOL, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('2345', 'telmilkiltumfoldeglul', 'common_language_volapuek')]},
      {'input' : 'tummäl', 'language' : NumeralWordsLanguage.VOL, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('106', 'tummael', 'common_language_volapuek')]},
      {'input' : 'veldeg', 'language' : NumeralWordsLanguage.VOL, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('70', 'veldeg', 'common_language_volapuek')]},
      {'input' : 'jölmil', 'language' : NumeralWordsLanguage.VOL, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('8000', 'joelmil', 'common_language_volapuek')]},
      {'input' : 'teltum', 'language' : NumeralWordsLanguage.VOL, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('200', 'teltum', 'common_language_volapuek')]},
      {'input' : 'degmil', 'language' : NumeralWordsLanguage.VOL, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('10000', 'degmil', 'common_language_volapuek')]},
      {'input' : 'jöltumveldegmälmil kiltumteldegzül', 'language' : NumeralWordsLanguage.VOL, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('876329', 'joeltumveldegmaelmilkiltumteldegzuel', 'common_language_volapuek')]},
    ];

    _inputsToExpected.forEach((elem) {
      test('input: ${elem['input']}, language: ${elem['language']}, decodeMode: ${elem['decodeMode']}', () {
        var _actual = decodeNumeralwords(input: removeAccents(elem['input'].toString().toLowerCase()), language: elem['language'], decodeModeWholeWords: elem['decodeMode']);
        var length = elem['expectedOutput'].length;
        for (int i = 0; i < length; i++) {
          expect(_actual[i].number, elem['expectedOutput'][i].number);
          expect(_actual[i].numWord, elem['expectedOutput'][i].numWord);
          expect(_actual[i].language, elem['expectedOutput'][i].language);
        }
      });
    });
  });

  group("NumeralWords.decodeNumeralwordsEntireWordsEPO:", () {
    List<Map<String, dynamic>> _inputsToExpected = [
      {'input' : '', 'language' : NumeralWordsLanguage.EPO, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('', '', 'numeralwords_language_empty')]},
      {'input' : 'fünfundzwanzig', 'language' : NumeralWordsLanguage.EPO, 'decodeMode' : true,
        'expectedOutput' : []},

      {'input' : 'dek du', 'language' : NumeralWordsLanguage.EPO, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('12', 'dekdu', 'common_language_esperanto')]},
      {'input' : 'kvardek tri', 'language' : NumeralWordsLanguage.EPO, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('43', 'kvardektri', 'common_language_esperanto')]},
      {'input' : 'naudek ok', 'language' : NumeralWordsLanguage.EPO, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('98', 'naudekok', 'common_language_esperanto')]},
      {'input' : 'tricent', 'language' : NumeralWordsLanguage.EPO, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('300', 'tricent', 'common_language_esperanto')]},
      {'input' : 'kvincent naudek ok', 'language' : NumeralWordsLanguage.EPO, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('598', 'kvincentnaudekok', 'common_language_esperanto')]},
      {'input' : 'sep mil dudek kvar', 'language' : NumeralWordsLanguage.EPO, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('7024', 'sepmildudekkvar', 'common_language_esperanto')]},
      {'input' : 'nau mil okcent dek kvin', 'language' : NumeralWordsLanguage.EPO, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('9815', 'naumilokcentdekkvin', 'common_language_esperanto')]},
      {'input' : 'kvarcent tridek kvin mil sescent okdek nau', 'language' : NumeralWordsLanguage.EPO, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('435689', 'kvarcenttridekkvinmilsescentokdeknau', 'common_language_esperanto')]},
    ];

    _inputsToExpected.forEach((elem) {
      test('input: ${elem['input']}, language: ${elem['language']}, decodeMode: ${elem['decodeMode']}', () {
        var _actual = decodeNumeralwords(input: removeAccents(elem['input'].toString().toLowerCase()), language: elem['language'], decodeModeWholeWords: elem['decodeMode']);
        var length = elem['expectedOutput'].length;
        for (int i = 0; i < length; i++) {
          expect(_actual[i].number, elem['expectedOutput'][i].number);
          expect(_actual[i].numWord, elem['expectedOutput'][i].numWord);
          expect(_actual[i].language, elem['expectedOutput'][i].language);
        }
      });
    });
  });

  group("NumeralWords.decodeNumeralwordsEntireWordsSOL:", () {
    List<Map<String, dynamic>> _inputsToExpected = [
      {'input' : '', 'language' : NumeralWordsLanguage.SOL, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('', '', 'numeralwords_language_empty')]},
      {'input' : 'fünfundzwanzig', 'language' : NumeralWordsLanguage.SOL, 'decodeMode' : true,
        'expectedOutput' : []},

      {'input' : 'mimisi', 'language' : NumeralWordsLanguage.SOL, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('12', 'mimisi', 'common_language_solresol')]},
      {'input' : 'fafasol refafa', 'language' : NumeralWordsLanguage.SOL, 'decodeMode' : true,
        'expectedOutput' : [
          NumeralWordsDecodeOutput('43', 'fafasolrefafa', 'common_language_solresol')]},
      {'input' : 'fadodo mimisol mimire', 'language' : NumeralWordsLanguage.SOL, 'decodeMode' : true,
        'expectedOutput' : [
          NumeralWordsDecodeOutput('98', 'fadodomimisolmimire', 'common_language_solresol')]},
      {'input' : 'refafa famimi', 'language' : NumeralWordsLanguage.SOL, 'decodeMode' : true,
        'expectedOutput' : [
          NumeralWordsDecodeOutput('3000', 'refafafamimi', 'common_language_solresol')]},
      {'input' : 'relala farere fadodo mimisol mimire', 'language' : NumeralWordsLanguage.SOL, 'decodeMode' : true,
        'expectedOutput' : [
          NumeralWordsDecodeOutput('598', 'relalafarerefadodomimisolmimire', 'common_language_solresol')]},
      {'input' : 'mimido famimi fafare resolsol', 'language' : NumeralWordsLanguage.SOL, 'decodeMode' : true,
        'expectedOutput' : [
          NumeralWordsDecodeOutput('7024', 'mimidofamimifafareresolsol', 'common_language_solresol')]},
      {'input' : 'mimifa famimi mimire farere mifafa', 'language' : NumeralWordsLanguage.SOL, 'decodeMode' : true,
        'expectedOutput' : [
          NumeralWordsDecodeOutput('9815', 'mimifafamimimimirefareremifafa', 'common_language_solresol')]},
      {'input' : 'resolsol farere fafami relala famimi resisi farere fadodo mimifa', 'language' : NumeralWordsLanguage.SOL, 'decodeMode' : true,
        'expectedOutput' : [
          NumeralWordsDecodeOutput('435689', 'resolsolfarerefafamirelalafamimiresisifarerefadodomimifa', 'common_language_solresol')]},
    ];

    _inputsToExpected.forEach((elem) {
      test('input: ${elem['input']}, language: ${elem['language']}, decodeMode: ${elem['decodeMode']}', () {
        var _actual = decodeNumeralwords(input: removeAccents(elem['input'].toString().toLowerCase()), language: elem['language'], decodeModeWholeWords: elem['decodeMode']);
        var length = elem['expectedOutput'].length;
        for (int i = 0; i < length; i++) {
          expect(_actual[i].number, elem['expectedOutput'][i].number);
          expect(_actual[i].numWord, elem['expectedOutput'][i].numWord);
          expect(_actual[i].language, elem['expectedOutput'][i].language);
        }
      });
    });
  });

  group("NumeralWords.decodeNumeralwordsEntireWordsLAT:", () {
    List<Map<String, dynamic>> _inputsToExpected = [
      {'input' : '', 'language' : NumeralWordsLanguage.LAT, 'decodeMode' : true,
        'expectedOutput' : [NumeralWordsDecodeOutput('', '', 'numeralwords_language_empty')]},
      {'input' : 'fünfundzwanzig', 'language' : NumeralWordsLanguage.LAT, 'decodeMode' : true,
        'expectedOutput' : []},

      {'input' : 'quinque duo gradus quattuor quattuor punctum octo octo octo zerum unus tria gradus zerum unus punctum tria hexas quinque', 'language' : NumeralWordsLanguage.LAT, 'decodeMode' : true,
        'expectedOutput' : [
          NumeralWordsDecodeOutput('5', 'quinque', 'common_language_latin'),
          NumeralWordsDecodeOutput('2', 'duo', 'common_language_latin'),
          NumeralWordsDecodeOutput('°', 'gradus', 'common_language_latin'),
          NumeralWordsDecodeOutput('4', 'quattuor', 'common_language_latin'),
          NumeralWordsDecodeOutput('4', 'quattuor', 'common_language_latin'),
          NumeralWordsDecodeOutput('.', 'punctum', 'common_language_latin'),
          NumeralWordsDecodeOutput('8', 'octo', 'common_language_latin'),
          NumeralWordsDecodeOutput('8', 'octo', 'common_language_latin'),
          NumeralWordsDecodeOutput('8', 'octo', 'common_language_latin'),
          NumeralWordsDecodeOutput('0', 'zerum', 'common_language_latin'),
          NumeralWordsDecodeOutput('1', 'unus', 'common_language_latin'),
          NumeralWordsDecodeOutput('3', 'tria', 'common_language_latin'),
          NumeralWordsDecodeOutput('°', 'gradus', 'common_language_latin'),
          NumeralWordsDecodeOutput('0', 'zerum', 'common_language_latin'),
          NumeralWordsDecodeOutput('1', 'unus', 'common_language_latin'),
          NumeralWordsDecodeOutput('.', 'punctum', 'common_language_latin'),
          NumeralWordsDecodeOutput('3', 'tria', 'common_language_latin'),
          NumeralWordsDecodeOutput('6', 'hexas', 'common_language_latin'),
          NumeralWordsDecodeOutput('5', 'quinque', 'common_language_latin'),
        ]},
    ];

    _inputsToExpected.forEach((elem) {
      test('input: ${elem['input']}, language: ${elem['language']}, decodeMode: ${elem['decodeMode']}', () {
        var _actual = decodeNumeralwords(input: removeAccents(elem['input'].toString().toLowerCase()), language: elem['language'], decodeModeWholeWords: elem['decodeMode']);
        var length = elem['expectedOutput'].length;
        for (int i = 0; i < length; i++) {
          expect(_actual[i].number, elem['expectedOutput'][i].number);
          expect(_actual[i].numWord, elem['expectedOutput'][i].numWord);
          expect(_actual[i].language, elem['expectedOutput'][i].language);
        }
      });
    });
  });

  group("NumeralWords.decodeNumeralwordsEntireWordsGC97P76:", () {
    List<Map<String, dynamic>> _inputsToExpected = [
      {
        'input': 'hat nocht arat hai bir dau mann satu hamar',
        'language': NumeralWordsLanguage.ALL,
        'decodeMode': true,
        'expectedOutput': [
          NumeralWordsDecodeOutput('6', 'hat', 'numeralwords_language_ung'),
          NumeralWordsDecodeOutput('0', 'nocht', 'numeralwords_language_sco'),
          NumeralWordsDecodeOutput('4', 'arat', 'numeralwords_language_amh'),
          NumeralWordsDecodeOutput('2', 'hai', 'numeralwords_language_vie'),
          NumeralWordsDecodeOutput('1', 'bir', 'numeralwords_language_tur'),
          NumeralWordsDecodeOutput('2', 'dau', 'numeralwords_language_meg'),
          NumeralWordsDecodeOutput('0', 'mann', 'numeralwords_language_bre'),
          NumeralWordsDecodeOutput('1', 'satu', 'numeralwords_language_ind'),
          NumeralWordsDecodeOutput('10', 'hamar', 'numeralwords_language_bas'),
        ]
      },
    ];

    _inputsToExpected.forEach((elem) {
      test(
          'input: ${elem['input']}, language: ${elem['language']}, decodeMode: ${elem['decodeMode']}', () {
        var _actual = decodeNumeralwords(input: removeAccents(elem['input'].toString().toLowerCase()), language: elem['language'], decodeModeWholeWords: elem['decodeMode']);
        var length = elem['expectedOutput'].length;
        for (int i = 0; i < length; i++) {
          expect(_actual[i].number, elem['expectedOutput'][i].number);
          expect(_actual[i].numWord, elem['expectedOutput'][i].numWord);
          expect(_actual[i].language, elem['expectedOutput'][i].language);
        }
      });
    });
  });

  group("NumeralWords.Minions:", () {
      List<Map<String, dynamic>> _inputsToExpected = [
        {
          'input': 'hana dul sae saesae saedul dulsae hanadulsae hanahana duldul',
          'language': NumeralWordsLanguage.MIN,
          'decodeMode': true,
          'expectedOutput': [
            NumeralWordsDecodeOutput('1', 'hana', 'numeralwords_language_min'),
            NumeralWordsDecodeOutput('2', 'dul', 'numeralwords_language_min'),
            NumeralWordsDecodeOutput('3', 'sae', 'numeralwords_language_min'),
            NumeralWordsDecodeOutput('6', 'saesae', 'numeralwords_language_min'),
            NumeralWordsDecodeOutput('5', 'saedul', 'numeralwords_language_min'),
            NumeralWordsDecodeOutput('5', 'dulsae', 'numeralwords_language_min'),
            NumeralWordsDecodeOutput('6', 'hanadulsae', 'numeralwords_language_min'),
            NumeralWordsDecodeOutput('2', 'hanahana', 'numeralwords_language_min'),
            NumeralWordsDecodeOutput('4', 'duldul', 'numeralwords_language_min'),
          ]
        },
      ];

      _inputsToExpected.forEach((elem) {
        test(
            'input: ${elem['input']}, language: ${elem['language']}, decodeMode: ${elem['decodeMode']}', () {
          var _actual = decodeNumeralwords(input: removeAccents(elem['input'].toString().toLowerCase()), language: elem['language'], decodeModeWholeWords: elem['decodeMode']);
          var length = elem['expectedOutput'].length;
          for (int i = 0; i < length; i++) {
            expect(_actual[i].number, elem['expectedOutput'][i].number);
            expect(_actual[i].numWord, elem['expectedOutput'][i].numWord);
            expect(_actual[i].language, elem['expectedOutput'][i].language);
          }
        });
      });
    });

  group("NumeralWords.Shadoks:", () {
        List<Map<String, dynamic>> _inputsToExpected = [
          {
            'input': 'ga bu zo meu meumeu zobugameu zozo gazo gaga',
            'language': NumeralWordsLanguage.SHA,
            'decodeMode': true,
            'expectedOutput': [
              NumeralWordsDecodeOutput('0', 'ga', 'numeralwords_language_sha'),
              NumeralWordsDecodeOutput('1', 'bu', 'numeralwords_language_sha'),
              NumeralWordsDecodeOutput('2', 'zo', 'numeralwords_language_sha'),
              NumeralWordsDecodeOutput('3', 'meu', 'numeralwords_language_sha'),
              NumeralWordsDecodeOutput('15', 'meumeu', 'numeralwords_language_sha'),
              NumeralWordsDecodeOutput('147', 'zobugameu', 'numeralwords_language_sha'),
              NumeralWordsDecodeOutput('10', 'zozo', 'numeralwords_language_sha'),
              NumeralWordsDecodeOutput('2', 'gazo', 'numeralwords_language_sha'),
              NumeralWordsDecodeOutput('0', 'gaga', 'numeralwords_language_sha'),
            ]
          },
        ];

        _inputsToExpected.forEach((elem) {
          test(
              'input: ${elem['input']}, language: ${elem['language']}, decodeMode: ${elem['decodeMode']}', () {
            var _actual = decodeNumeralwords(input: removeAccents(elem['input'].toString().toLowerCase()), language: elem['language'], decodeModeWholeWords: elem['decodeMode']);
            var length = elem['expectedOutput'].length;
            for (int i = 0; i < length; i++) {
              expect(_actual[i].number, elem['expectedOutput'][i].number);
              expect(_actual[i].numWord, elem['expectedOutput'][i].numWord);
              expect(_actual[i].language, elem['expectedOutput'][i].language);
            }
          });
        });
      });

  group("NumeralWords.Klingon:", () {
    List<Map<String, dynamic>> _inputsToExpected = [
      {// GC8J08H
        'input': "north         cha'maH-jav         cha' wa'vatlh 'ej loSmaH-Hut       chan         nineteen        pagh-wej-chorgh",
        'language': NumeralWordsLanguage.ALL,
        'decodeMode': true,
        'expectedOutput': [
          NumeralWordsDecodeOutput('numeralwords_n', 'north', 'common_language_english'),
          NumeralWordsDecodeOutput("26", "cha'mah jav", 'numeralwords_language_kli'),
          NumeralWordsDecodeOutput("2", "cha'", 'numeralwords_language_kli'),
          NumeralWordsDecodeOutput("100", "wa'vatlh", 'numeralwords_language_kli'),
          NumeralWordsDecodeOutput("49", "losmah hut", 'numeralwords_language_kli'),
          NumeralWordsDecodeOutput("numeralwords_e", 'chan', 'numeralwords_language_kli'),
          NumeralWordsDecodeOutput("19", 'nineteen', 'common_language_english'),
          NumeralWordsDecodeOutput("0", 'pagh', 'numeralwords_language_kli'),
          NumeralWordsDecodeOutput("3", 'wej', 'numeralwords_language_kli'),
          NumeralWordsDecodeOutput("8", 'chorgh', 'numeralwords_language_kli'),
        ]
      },
      {// http://klingon.wiki/De/Zahlen
        'input': "vaghbIp loSvatlh wa'",
        'language': NumeralWordsLanguage.KLI,
        'decodeMode': true,
        'expectedOutput': [
          NumeralWordsDecodeOutput("500401", "vaghbip losvatlh wa'", 'numeralwords_language_kli'),
        ]
      },
      {// http://klingon.wiki/De/Zahlen
        'input': "cha'maH wej",
        'language': NumeralWordsLanguage.KLI,
        'decodeMode': true,
        'expectedOutput': [
          NumeralWordsDecodeOutput("23", "cha'mah wej", 'numeralwords_language_kli'),
        ]
      },
      {
        'input': "vaghbIp loSvatlh wa' chan nau cha'mah wej",
        'language': NumeralWordsLanguage.ALL,
        'decodeMode': true,
        'expectedOutput': [
          NumeralWordsDecodeOutput("500401", "vaghbip losvatlh wa'", 'numeralwords_language_kli'),
          NumeralWordsDecodeOutput("numeralwords_e", "chan", 'numeralwords_language_kli'),
          NumeralWordsDecodeOutput("9", "nau", 'common_language_esperanto'),
          NumeralWordsDecodeOutput("", "", 'numeralwords_language_meg'),
          NumeralWordsDecodeOutput("23", "cha'mah wej", 'numeralwords_language_kli'),
        ]
      },
      {
        'input': "'oy' vaghmaH cha' Qoch cha'maH Soch ngev wejvatlh javmah Hut chan pagh wa'maH wej Qoch cha'maH hut ghob pagh Hutmah loS",
        'language': NumeralWordsLanguage.KLI,
        'decodeMode': true,
        'expectedOutput': [
          NumeralWordsDecodeOutput("numeralwords_n", "'oy'", 'numeralwords_language_kli'),
          NumeralWordsDecodeOutput("52", "vaghmah cha'", 'numeralwords_language_kli'),
          NumeralWordsDecodeOutput("°", "qoch", 'numeralwords_language_kli'),
          NumeralWordsDecodeOutput("27", "cha\'mah soch", 'numeralwords_language_kli'),
          NumeralWordsDecodeOutput(".", "ngev", 'numeralwords_language_kli'),
          NumeralWordsDecodeOutput("369", "wejvatlh javmah hut", 'numeralwords_language_kli'),
          NumeralWordsDecodeOutput("numeralwords_e", "chan", 'numeralwords_language_kli'),
          NumeralWordsDecodeOutput("0", "pagh", 'numeralwords_language_kli'),
          NumeralWordsDecodeOutput("13", "wa'mah wej", 'numeralwords_language_kli'),
          NumeralWordsDecodeOutput("°", "qoch", 'numeralwords_language_kli'),
          NumeralWordsDecodeOutput("29", "cha'mah hut", 'numeralwords_language_kli'),
          NumeralWordsDecodeOutput(".", "ghob", 'numeralwords_language_kli'),
          NumeralWordsDecodeOutput("0", "pagh", 'numeralwords_language_kli'),
          NumeralWordsDecodeOutput("94", "hutmah los", 'numeralwords_language_kli'),
        ]
      },
    ];

    _inputsToExpected.forEach((elem) {
      test(
          'input: ${elem['input']}, language: ${elem['language']}, decodeMode: ${elem['decodeMode']}', () {
        var _actual = decodeNumeralwords(input: removeAccents(elem['input'].toString().toLowerCase()), language: elem['language'], decodeModeWholeWords: elem['decodeMode']);
        var length = elem['expectedOutput'].length;
        for (int i = 0; i < length; i++) {
          expect(_actual[i].number, elem['expectedOutput'][i].number);
          expect(_actual[i].numWord, elem['expectedOutput'][i].numWord);
          expect(_actual[i].language, elem['expectedOutput'][i].language);
        }
      });
    });
  });

  group("NumeralWords.Navi:", () {
    List<Map<String, dynamic>> _inputsToExpected = [
      {// GC5MJ89
        'input': "nefä puvol° mrrvomun.mezam mevohin    skien volaw° kew.vozam mezam mune",
        'language': NumeralWordsLanguage.NAVI,
        'decodeMode': true,
        'expectedOutput': [
          NumeralWordsDecodeOutput('numeralwords_n', 'nefae', 'numeralwords_language_navi'),
          NumeralWordsDecodeOutput("48", "puvol", 'numeralwords_language_navi'),
          NumeralWordsDecodeOutput("°", "°", ''),
          NumeralWordsDecodeOutput("42", "mrrvomun", 'numeralwords_language_navi'),
          NumeralWordsDecodeOutput(".", ".", ''),
          NumeralWordsDecodeOutput("128", "mezam", 'numeralwords_language_navi'),
          NumeralWordsDecodeOutput("23", "mevohin", 'numeralwords_language_navi'),
          NumeralWordsDecodeOutput("numeralwords_e", 'skien', 'numeralwords_language_navi'),
          NumeralWordsDecodeOutput("9", 'volaw', 'numeralwords_language_navi'),
          NumeralWordsDecodeOutput("°", "°", ''),
          NumeralWordsDecodeOutput("0", 'kew', 'numeralwords_language_navi'),
          NumeralWordsDecodeOutput(".", ".", ''),
          NumeralWordsDecodeOutput("512", 'vozam', 'numeralwords_language_navi'),
          NumeralWordsDecodeOutput("128", 'mezam', 'numeralwords_language_navi'),
          NumeralWordsDecodeOutput("2", 'mune', 'numeralwords_language_navi'),
        ]
      },
      {// https://learnnavi.org/navi-numbers/
        'input': "kizazamkivozamkizamkivohin",
        'language': NumeralWordsLanguage.NAVI,
        'decodeMode': true,
        'expectedOutput': [
          NumeralWordsDecodeOutput("32767", "kizazamkivozamkizamkivohin", 'numeralwords_language_navi'),
        ]
      },
      {// https://learnnavi.org/navi-numbers/
        'input': "tsìvozamezampxevosìng",
        'language': NumeralWordsLanguage.NAVI,
        'decodeMode': true,
        'expectedOutput': [
          NumeralWordsDecodeOutput("2204", "tsivozamezampxevosing", 'numeralwords_language_navi'),
        ]
      },
      {// https://learnnavi.org/navi-numbers/
        'input': "kew",
        'language': NumeralWordsLanguage.NAVI,
        'decodeMode': true,
        'expectedOutput': [
          NumeralWordsDecodeOutput("0", "kew", 'numeralwords_language_navi'),
        ]
      },
      {// https://learnnavi.org/navi-numbers/
        'input': "mrr",
        'language': NumeralWordsLanguage.NAVI,
        'decodeMode': true,
        'expectedOutput': [
          NumeralWordsDecodeOutput("5", "mrr", 'numeralwords_language_navi'),
        ]
      },
      {// https://learnnavi.org/navi-numbers/
        'input': "pxevozampuzampuvol",
        'language': NumeralWordsLanguage.NAVI,
        'decodeMode': true,
        'expectedOutput': [
          NumeralWordsDecodeOutput("1968", "pxevozampuzampuvol", 'numeralwords_language_navi'),
        ]
      },
    ];

    _inputsToExpected.forEach((elem) {
      test(
          'input: ${elem['input']}, language: ${elem['language']}, decodeMode: ${elem['decodeMode']}', () {
        var _actual = decodeNumeralwords(input: removeAccents(elem['input'].toString().toLowerCase()), language: elem['language'], decodeModeWholeWords: elem['decodeMode']);
        var length = elem['expectedOutput'].length;
        for (int i = 0; i < length; i++) {
          expect(_actual[i].number, elem['expectedOutput'][i].number);
          expect(_actual[i].numWord, elem['expectedOutput'][i].numWord);
          expect(_actual[i].language, elem['expectedOutput'][i].language);
        }
      });
    });
  });

  group("NumeralWords.unicode languages:", () {
    List<Map<String, dynamic>> _inputsToExpected = [
      {
        'input': 'шестнадцать 十八 じゅうしち 이십 열다섯 百 единайсет สามสิบ',
        'language': NumeralWordsLanguage.ALL,
        'decodeMode': true,
        'expectedOutput': [
          NumeralWordsDecodeOutput('16', 'шестнадцать', 'numeralwords_language_kyr'),
          NumeralWordsDecodeOutput('18', '十八', 'numeralwords_language_chi_symbol'),
          NumeralWordsDecodeOutput('', '', 'common_language_hanja'),
          NumeralWordsDecodeOutput('17', 'じゅうしち', 'numeralwords_language_jap_hiragana'),
          NumeralWordsDecodeOutput('20', '이십', 'common_language_hangul_sino_korean'),
          NumeralWordsDecodeOutput('15', '열다섯', 'common_language_hangul_korean'),
          NumeralWordsDecodeOutput('100', '百', 'numeralwords_language_chi_symbol'),
          NumeralWordsDecodeOutput('', '', 'common_language_hanja'),
          NumeralWordsDecodeOutput('11', 'единайсет', 'numeralwords_language_bul_kyr'),
          NumeralWordsDecodeOutput('30', 'สามสิบ', 'common_language_thai'),
        ]
      },
    ];

    _inputsToExpected.forEach((elem) {
      test(
          'input: ${elem['input']}, language: ${elem['language']}, decodeMode: ${elem['decodeMode']}', () {
        var _actual = decodeNumeralwords(input: removeAccents(elem['input'].toString().toLowerCase()), language: elem['language'], decodeModeWholeWords: elem['decodeMode']);
        var length = elem['expectedOutput'].length;
        for (int i = 0; i < length; i++) {
          expect(_actual[i].number, elem['expectedOutput'][i].number);
          expect(_actual[i].numWord, elem['expectedOutput'][i].numWord);
          expect(_actual[i].language, elem['expectedOutput'][i].language);
        }
      });
    });
  });
}