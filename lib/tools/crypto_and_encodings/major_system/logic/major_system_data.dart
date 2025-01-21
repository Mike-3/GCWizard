part of 'package:gc_wizard/tools/crypto_and_encodings/major_system/logic/major_system.dart';

enum MajorSystemLanguage { DE, EN, FR, PL }

String languageName(MajorSystemLanguage country) {
  switch (country) {
    case MajorSystemLanguage.DE: return "common_language_german";
    case MajorSystemLanguage.EN: return "common_language_english";
    case MajorSystemLanguage.FR: return "common_language_french";
    case MajorSystemLanguage.PL: return "common_language_polish";
  }
}

Map<String, String> _getTranslations(MajorSystemLanguage country) {
  switch (country) {
    case MajorSystemLanguage.DE: return _translationDE;
    case MajorSystemLanguage.EN: return _translationEN;
    case MajorSystemLanguage.FR: return _translationFR;
    case MajorSystemLanguage.PL: return _translationPL;
  }
}

Map<String, String> _getSpecialTranslations(MajorSystemLanguage country) {
  switch (country) {
    case MajorSystemLanguage.DE: return _specialTranslationsDE;
    case MajorSystemLanguage.EN: return _specialTranslationsEN;
    case MajorSystemLanguage.FR: return _specialTranslationsFR;
    case MajorSystemLanguage.PL: return _specialTranslationsPL;
  }
}

RegExp _getSplitPattern(MajorSystemLanguage country) {
  late String splitletters;
  switch (country) {
    case MajorSystemLanguage.DE: splitletters = _splitLettersDE; break;
    case MajorSystemLanguage.EN: splitletters = _splitLettersEN; break;
    case MajorSystemLanguage.FR: splitletters = _splitLettersFR; break;
    case MajorSystemLanguage.PL: splitletters = _splitLettersPL; break;
  }
  return RegExp('[$splitletters]+');
}


const Map<String, String> _translationDE = {
  's': '0', 'z': '0', 't': '1', 'd': '1', 'n': '2', 'm': '3',
  'r': '4', 'l': '5', 'j': '6', 'g': '7', 'k': '7', 'c': '7',
  'f': '8', 'v': '8', 'w': '8', 'b': '9', 'p': '9'
};

const Map<String, String> _specialTranslationsDE = {
  'sch': 'j', 'ch': 'j', 'ck': 'k', 'ph': 'f'
};

const _splitLettersDE = 'aeiouqxy';

const Map<String, String> _translationEN = {
  's': '0', 'z': '0', 't': '1', 'd': '1', 'n': '2', 'm': '3',
  'r': '4', 'l': '5', 'j': '6', 'g': '7', 'k': '7', 'c': '7',
  'q': '7', 'f': '8', 'v': '8', 'w': '8', 'b': '9', 'p': '9'
};

const Map<String, String> _specialTranslationsEN = {
  'sh': 'j', 'ch': 'j', 'ck': 'k', 'ph': 'f', 'th': 't'
};

const _splitLettersEN = 'aeiouwhxy';

const Map<String, String> _translationFR = {
  's': '0', 'z': '0', 't': '1', 'd': '1', 'n': '2', 'm': '3',
  'r': '4', 'l': '5', 'j': '6', 'g': '7', 'k': '7', 'c': '7',
  'f': '8', 'v': '8', 'b': '9', 'p': '9'
};

const Map<String, String> _specialTranslationsFR = {
  'gn': 'n', 'ng': 'n', 'ch': 'j', 'sh': 'j', 'ph': 'f'
};

const _splitLettersFR = 'aeiouwhxy';

const Map<String, String> _translationPL = {
  's': '0', 'z': '0', 't': '1', 'd': '1', 'n': '2',
  'm': '3', 'r': '4', 'l': '5', 'j': '6', 'k': '7',
  'g': '7', 'f': '8', 'w': '8', 'b': '9', 'p': '9'
};

const Map<String, String> _specialTranslationsPL = {};

const _splitLettersPL = 'aeiouvhxy';

// Without knowing the pronunciation,
// it is not possible to implement this algorithmically
// for Spanish and Italian