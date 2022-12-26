import 'package:gc_wizard/tools/science_and_technology/number_sequences/logic/number_sequence.dart';
import 'package:gc_wizard/tools/science_and_technology/number_sequences/base/numbersequences_check/widget/numbersequences_check.dart';
import 'package:gc_wizard/tools/science_and_technology/number_sequences/base/numbersequences_containsdigits/widget/numbersequences_containsdigits.dart';
import 'package:gc_wizard/tools/science_and_technology/number_sequences/base/numbersequences_digits/widget/numbersequences_digits.dart';
import 'package:gc_wizard/tools/science_and_technology/number_sequences/base/numbersequences_nthnumber/widget/numbersequences_nthnumber.dart';
import 'package:gc_wizard/tools/science_and_technology/number_sequences/base/numbersequences_range/widget/numbersequences_range.dart';

class NumberSequencePellCheckNumber extends NumberSequenceCheckNumber {
  NumberSequencePellCheckNumber() : super(mode: NumberSequencesMode.PELL, maxIndex: 55555);
}

class NumberSequencePellDigits extends NumberSequenceDigits {
  NumberSequencePellDigits() : super(mode: NumberSequencesMode.PELL, maxDigits: 1111);
}

class NumberSequencePellRange extends NumberSequenceRange {
  NumberSequencePellRange() : super(mode: NumberSequencesMode.PELL, maxIndex: 55555);
}

class NumberSequencePellNthNumber extends NumberSequenceNthNumber {
  NumberSequencePellNthNumber() : super(mode: NumberSequencesMode.PELL, maxIndex: 55555);
}

class NumberSequencePellContainsDigits extends NumberSequenceContainsDigits {
  NumberSequencePellContainsDigits() : super(mode: NumberSequencesMode.PELL, maxIndex: 5555);
}