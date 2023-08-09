import "package:flutter_test/flutter_test.dart";
import 'package:gc_wizard/tools/science_and_technology/apparent_temperature/summer_simmer/logic/summer_simmer.dart';
import 'package:gc_wizard/tools/science_and_technology/unit_converter/logic/temperature.dart';

void main() {
  group("SummerSimmer.calculate:", () {
    List<Map<String, Object?>> _inputsToExpected = [
      {'temperature' : 0.0, 'humidity' : 0.0, 'temperatureUnit' : TEMPERATURE_CELSIUS, 'expectedOutput' : '1.580'},
      {'temperature' : 45.0, 'humidity' : 55.0, 'temperatureUnit' : TEMPERATURE_CELSIUS, 'expectedOutput' : '59.976'},
      {'temperature' : 56.0, 'humidity' : 30.0, 'temperatureUnit' : TEMPERATURE_FAHRENHEIT, 'expectedOutput' : '55.575'},
      {'temperature' : 18.0, 'humidity' : 75.0, 'temperatureUnit' : TEMPERATURE_CELSIUS, 'expectedOutput' : '20.522'},
      {'temperature' : 0.0, 'humidity' : 0.0, 'temperatureUnit' : TEMPERATURE_FAHRENHEIT, 'expectedOutput' : '6.332'},
    ];

    for (var elem in _inputsToExpected) {
      test('temperature: ${elem['temperature']}, humidity: ${elem['humidity']}, temperatureUnit: ${(elem['temperatureUnit'] as Temperature).symbol}', () {
        var _actual = calculateSummerSimmerIndex(elem['temperature'] as double, elem['humidity'] as double, elem['temperatureUnit'] as Temperature);
        expect(_actual.toStringAsFixed(3), elem['expectedOutput']);
      });
    }
  });
}
