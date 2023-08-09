import 'package:flutter/material.dart';
import 'package:gc_wizard/tools/science_and_technology/countries/countries/widget/countries.dart';
import 'package:gc_wizard/tools/science_and_technology/countries/logic/countries.dart';

class CountriesCallingCodes extends Countries {
  CountriesCallingCodes({Key? key}) : super(key: key, fields: [CountryProperties.callingcode]);
}
