import 'package:flutter/material.dart';
import 'package:gc_wizard/tools/science_and_technology/countries/countries/widget/countries.dart';
import 'package:gc_wizard/tools/science_and_technology/countries/logic/countries.dart';

class CountriesIOCCodes extends Countries {
  CountriesIOCCodes({Key? key}) : super(key: key, fields: [CountryProperties.ioccode]);
}
