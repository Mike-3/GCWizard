import 'package:gc_wizard/tools/science_and_technology/irrational_numbers/e/logic/e.dart';
import 'package:gc_wizard/tools/science_and_technology/irrational_numbers/irrationalnumbers_decimalrange/widget/irrationalnumbers_decimalrange.dart';
import 'package:gc_wizard/tools/science_and_technology/irrational_numbers/irrationalnumbers_nthdecimal/widget/irrationalnumbers_nthdecimal.dart';
import 'package:gc_wizard/tools/science_and_technology/irrational_numbers/irrationalnumbers_search/widget/irrationalnumbers_search.dart';

class ENthDecimal extends IrrationalNumbersNthDecimal {
  const ENthDecimal({super.key}) : super(irrationalNumber: E);
}

class EDecimalRange extends IrrationalNumbersDecimalRange {
  const EDecimalRange({super.key}) : super(irrationalNumber: E);
}

class ESearch extends IrrationalNumbersSearch {
  const ESearch({super.key}) : super(irrationalNumber: E);
}
