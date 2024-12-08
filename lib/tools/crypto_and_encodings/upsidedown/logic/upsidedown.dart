// https://de.wikipedia.org/wiki/Upside_Down_Text
// https://en.wikipedia.org/wiki/Transformation_of_text#Upside-down_text

import 'package:gc_wizard/common_widgets/switches/gcw_twooptions_switch.dart';
import 'package:gc_wizard/utils/collection_utils.dart';

const Map<String, String> ENCODE_FLIP_H = {
  '0' : '0',
  '1' : '',
  '2' : '',
  '3' : '',
  '4' : '',
  '5' : 'S',
  '6' : '',
  '7' : '',
  '8' : '8',
  '9' : '',
  'a' : 'e',
  'b' : 'p',
  'c' : 'c',
  'd' : 'q',
  'e' : 'a',
  'f' : '',
  'g' : '6',
  'h' : '',
  'i' : '',
  'j' : '',
  'k' : '',
  'l' : '',
  'm' : 'w',
  'n' : 'u',
  'o' : 'o',
  'p' : '',
  'q' : '',
  'r' : '',
  's' : '',
  't' : '',
  'u' : 'n',
  'v' : '^',
  'w' : 'm',
  'x' : 'x',
  'y' : '',
  'z' : '',
  'A' : '',
  'B' : '',
  'C' : 'C',
  'D' : '',
  'E' : 'E',
  'F' : '',
  'G' : '',
  'H' : 'H',
  'I' : 'I',
  'J' : '',
  'K' : '',
  'L' : '',
  'M' : 'W',
  'N' : '',
  'O' : 'O',
  'P' : '',
  'Q' : '',
  'R' : '',
  'S' : '',
  'T' : 'Ʇ',
  'U' : 'Ո',
  'V' : 'Ʌ',
  'W' : '𐤵',
  'X' : 'X',
  'Y' : '⅄',
  'Z' : '',
  ' ' : ' ',
  '.' : '',
  ':' : ':',
  ',' : "'",
  '-' : '-',
  '_' : '‾',
  '+' : '+',
  '*' : '*',
  '#' : '#',
  '~' : '',
  '?' : '',
  '!' : 'i',
  '/' : '\\',
  '\\' : '/',
  '[' : '[',
  ']' : ']',
  '(' : '(',
  ')' : ')',
  '=' : '=',
};

const Map<String, String> ENCODE_FLIP_V = {
  '0' : '0',
  '1' : '',
  '2' : '',
  '3' : '',
  '4' : '',
  '5' : 'S',
  '6' : '',
  '7' : '',
  '8' : '8',
  '9' : '',
  'a' : 'e',
  'b' : 'p',
  'c' : 'c',
  'd' : 'q',
  'e' : 'a',
  'f' : '',
  'g' : '6',
  'h' : '',
  'i' : '',
  'j' : '',
  'k' : '',
  'l' : '',
  'm' : 'w',
  'n' : 'u',
  'o' : 'o',
  'p' : '',
  'q' : '',
  'r' : '',
  's' : '',
  't' : '',
  'u' : 'n',
  'v' : '^',
  'w' : 'm',
  'x' : 'x',
  'y' : '',
  'z' : '',
  'A' : '',
  'B' : '',
  'C' : 'C',
  'D' : '',
  'E' : 'E',
  'F' : '',
  'G' : '',
  'H' : 'H',
  'I' : 'I',
  'J' : '',
  'K' : '',
  'L' : '',
  'M' : 'W',
  'N' : '',
  'O' : 'O',
  'P' : '',
  'Q' : '',
  'R' : '',
  'S' : '',
  'T' : 'Ʇ',
  'U' : 'Ո',
  'V' : 'Ʌ',
  'W' : '𐤵',
  'X' : 'X',
  'Y' : '⅄',
  'Z' : '',
  ' ' : ' ',
  '.' : '',
  ':' : ':',
  ',' : "'",
  '-' : '-',
  '_' : '‾',
  '+' : '+',
  '*' : '*',
  '#' : '#',
  '~' : '',
  '?' : '',
  '!' : 'i',
  '/' : '\\',
  '\\' : '/',
  '[' : '[',
  ']' : ']',
  '(' : '(',
  ')' : ')',
  '=' : '=',
};

const Map<String, String> ENCODE_FLIP_ROTATE = {
  '0' : '0',
  '1' : '⇂',
  '2' : '↊',
  '3' : '↋',
  '4' : '߈',
  '5' : 'ဌ',
  '6' : '9',
  '7' : '𝘓',
  '8' : '8',
  '9' : '6',
  'a' : 'ɐ',
  'b' : 'q',
  'c' : 'ɔ',
  'd' : 'p',
  'e' : 'ǝ',
  'f' : 'ɟ',
  'g' : 'ᵷ',
  'h' : 'ɥ',
  'i' : '!',
  'j' : 'ſ̣',
  'k' : 'ʞ',
  'l' : 'l',
  'm' : 'ɯ',
  'n' : 'u',
  'o' : 'o',
  'p' : 'd',
  'q' : 'b',
  'r' : 'ɹ',
  's' : 's',
  't' : 'ʇ',
  'u' : 'n',
  'v' : 'ʌ',
  'w' : 'ʍ',
  'x' : 'x',
  'y' : 'ʎ',
  'z' : 'z',
  'A' : 'Ɐ',
  'B' : 'ꓭ',
  'C' : 'Ɔ',
  'D' : 'ꓷ',
  'E' : 'E',
  'F' : 'Ⅎ',
  'G' : '⅁',
  'H' : 'H',
  'I' : 'I',
  'J' : 'ꓩ',
  'K' : 'ꓘ',
  'L' : '⅂',
  'M' : 'ꟽ',
  'N' : 'N',
  'O' : 'O',
  'P' : 'Ԁ',
  'Q' : 'Ꝺ',
  'R' : 'ꓤ',
  'S' : 'S',
  'T' : 'Ʇ',
  'U' : 'Ո',
  'V' : 'Ʌ',
  'W' : '𐤵',
  'X' : 'X',
  'Y' : '⅄',
  'Z' : 'Z',
  ' ' : ' ',
  '.' : '˙',
  ':' : ':',
  ',' : "'",
  '-' : '-',
  '_' : '‾',
  '+' : '+',
  '*' : '*',
  '#' : '#',
  '~' : '~',
  '?' : '¿',
  '!' : 'i',
  '/' : '\\',
  '\\' : '/',
  '[' : ']',
  ']' : '[',
  '(' : ')',
  ')' : '(',
  '=' : '=',
  '"' : '„',
};

Map<String, String> DECODE_FLIP_H = switchMapKeyValue(ENCODE_FLIP_H);
Map<String, String> DECODE_FLIP_V = switchMapKeyValue(ENCODE_FLIP_V);
Map<String, String> DECODE_FLIP_ROTATE = switchMapKeyValue(ENCODE_FLIP_ROTATE);

String decodeUpsideDownText(String input, int mode) {
  String result = '';
  Map<String, String> table = {};

  switch (mode) {
    case 0:
      table = DECODE_FLIP_H;
      break;
    case 1: // FLIP Vertical
      table = DECODE_FLIP_V;
      break;
    case 2:
      input = input.split('').reversed.join('');
      table = DECODE_FLIP_ROTATE;
      break;
  }

  for (int i = 0; i < input.length; i++) {
    if (table[input[i]] != null) {
      result = result + table[input[i]]!;
    } else {
      result = result + input[i];
    }
  }

  return result;
}

String encodeUpsideDownText(String input, int mode) {
  String result = '';
  Map<String, String> table = {};

  switch (mode) {
    case 0:
      table = ENCODE_FLIP_H;
      break;
    case 1: // FLIP Vertical
      table = ENCODE_FLIP_V;
      break;
    case 2:
      input = input.split('').reversed.join('');
      table = ENCODE_FLIP_ROTATE;
      break;
  }

  for (int i = 0; i < input.length; i++) {
    if (table[input[i]] != null) {
      result = result + table[input[i]]!;
    } else {
      result = result + input[i];
    }
  }

  return result;
}