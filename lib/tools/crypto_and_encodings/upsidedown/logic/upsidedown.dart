// https://de.wikipedia.org/wiki/Upside_Down_Text
// https://fonts.webtoolhub.com/font-n34162-quirkus-upside-down.aspx?lic=1
// Dieses Werk ist unter einem Creative Commons Namensnennung 3.0 Deutschland Lizenzvertrag lizenziert.
// Copyright (c) 2009 by Peter Wiegel Licensed under Creative Commons Attribution 3.0 Germany, This Font is "E-Mail-Ware" Please mail your comment or donate via PayPal to wiegel@peter-wiegel.de

import 'package:gc_wizard/common_widgets/switches/gcw_twooptions_switch.dart';
import 'package:gc_wizard/utils/collection_utils.dart';

Map<String, String> ENCODE_FLIP = {
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
  'I' : '',
  'J' : '',
  'K' : '',
  'L' : '',
  'M' : 'W',
  'N' : '',
  'O' : 'O',
  'P' : '',
  'Q' : '',
  'R' : '',
  'S' : '5',
  'T' : '',
  'U' : '',
  'V' : '',
  'W' : 'M',
  'X' : 'X',
  'Y' : '',
  'Z' : '',
  ' ' : ' ',
  '.' : '',
  ':' : ':',
  ',' : "'",
  ';' : '',
  '-' : '-',
  '_' : '',
  '+' : '+',
  '*' : '*',
  '~' : '',
  '?' : '',
  '!' : '',
  '/' : '\\',
  '\\' : '/',
  '[' : '[',
  ']' : ']',
  '(' : '(',
  ')' : ')',
  '=' : '=',
};

Map<String, String> ENCODE_FLIP_ROTATE = {
  '0' : '0',
  '1' : '',
  '2' : '',
  '3' : '',
  '4' : '',
  '5' : '5',
  '6' : '',
  '7' : '',
  '8' : '8',
  '9' : '6',
  'a' : 'ɐ',
  'b' : 'p',
  'c' : 'c',
  'd' : 'q',
  'e' : 'a',
  'f' : 'ɟ',
  'g' : 'ƃ',
  'h' : '	ɥ',
  'i' : '!',
  'j' : 'ɾ',
  'k' : 'ʞ',
  'l' : 'l',
  'm' : 'w',
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
  'A' : '',
  'B' : '',
  'C' : 'C',
  'D' : '',
  'E' : 'E',
  'F' : '',
  'G' : '',
  'H' : 'H',
  'I' : '',
  'J' : '',
  'K' : '',
  'L' : '',
  'M' : 'W',
  'N' : '',
  'O' : 'O',
  'P' : '',
  'Q' : '',
  'R' : '',
  'S' : '5',
  'T' : '',
  'U' : '',
  'V' : '',
  'W' : 'M',
  'X' : 'X',
  'Y' : '',
  'Z' : '',
  ' ' : ' ',
  '.' : '',
  ':' : ':',
  ',' : "'",
  ';' : '',
  '-' : '-',
  '_' : '',
  '+' : '+',
  '*' : '*',
  '~' : '',
  '?' : '¿',
  '!' : 'i',
  '/' : '\\',
  '\\' : '/',
  '[' : '[',
  ']' : ']',
  '(' : '(',
  ')' : ')',
  '=' : '=',
};

Map<String, String> DECODE_FLIP = switchMapKeyValue(ENCODE_FLIP);
Map<String, String> DECODE_FLIP_ROTATE = switchMapKeyValue(ENCODE_FLIP_ROTATE);

String decodeUpsideDownText(String input, GCWSwitchPosition mode) {
  String result = '';
  switch (mode) {
    case GCWSwitchPosition.left:
      for (int i = 0; i < input.length; i++) {
        if (DECODE_FLIP[input[i]] != null) {
          result = result + DECODE_FLIP[input[i]]!;
        } else {
          result = result + ' ';
        }
      }
      break;
    case GCWSwitchPosition.right:
      input = input.split('').reversed.join('');
      for (int i = 0; i < input.length; i++) {
        if (DECODE_FLIP_ROTATE[input[i]] != null) {
          result = result + DECODE_FLIP_ROTATE[input[i]]!;
        } else {
          result = result + ' ';
        }
      }
      break;
  }

  return result;
}

String encodeUpsideDownText(String input, GCWSwitchPosition mode) {
  String result = '';
  switch (mode) {
    case GCWSwitchPosition.left:
      for (int i = 0; i < input.length; i++) {
        if (ENCODE_FLIP[input[i]] != null) {
          result = result + ENCODE_FLIP[input[i]]!;
        } else {
          result = result + ' ';
        }
      }
      break;
    case GCWSwitchPosition.right:
      input = input.split('').reversed.join('');
      for (int i = 0; i < input.length; i++) {
        if (ENCODE_FLIP_ROTATE[input[i]] != null) {
          result = result + ENCODE_FLIP_ROTATE[input[i]]!;
        } else {
          result = result + ' ';
        }
      }
      break;
  }

  return result;
}