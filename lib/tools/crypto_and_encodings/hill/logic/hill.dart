//ported from https://www.geeksforgeeks.org/hill-cipher/
//https://crypto.interactive-maths.com/hill-cipher.html

import 'dart:core';
import 'dart:math';

import 'package:gc_wizard/tools/science_and_technology/divisor/logic/divisor.dart';
import 'package:gc_wizard/utils/collection_utils.dart';
import 'package:gc_wizard/utils/complex_return_types.dart';
import 'package:gc_wizard/utils/constants.dart';
import 'package:gc_wizard/utils/math_utils.dart';
import 'package:gc_wizard/utils/string_utils.dart';

StringText encryptText(String message, String key, int matrixSize, Map<String, String> alphabet,
    [String fillCharacter = "X"]) {

  key = _removeNonAlphabetCharacters(key, alphabet);
  var checkInputResult = _checkInput(key, matrixSize, alphabet);
  if (checkInputResult.isNotEmpty) return StringText(checkInputResult, '');

  return _encryptHillCipher(message, key, matrixSize, alphabet, fillCharacter);
}

StringText decryptText(String message, String key, int matrixSize, Map<String, String> alphabet,
    [String fillCharacter = "X"]) {

  key = _removeNonAlphabetCharacters(key, alphabet);
  var checkInputResult = _checkInput(key, matrixSize, alphabet);
  if (checkInputResult.isNotEmpty) return StringText(checkInputResult, '');

  return _decryptHillCipher(message, key, matrixSize, alphabet, fillCharacter);
}

String _checkInput(String key, int matrixSize, Map<String, String> alphabet) {
  if (alphabet.isEmpty) return 'AlphabetEmpty';
  if (key.isEmpty) return 'KeyEmpty';
  if (matrixSize < 2 || matrixSize > 10) return 'MatrixSize';
  return '';
}

Map<String, String> buildAlphabet(String alphabet) {
  var _alphabet  = <String, String>{};
  alphabet = removeDuplicateCharacters(alphabet.toUpperCase());

  for (int i = 0; i < alphabet.length; i++) {
    _alphabet.addAll({alphabet[i]: i.toString()});
  }
  return _alphabet;
}

StringText _decryptHillCipher(String message, String key, int matrixSize, Map<String, String> alphabet,
    String fillCharacter) {

  // Get inverted key matrix from the key string
  var keyMatrix = _getKeyMatrix(key, matrixSize, alphabet);
  var keyMatrixInverted = matrixInvert(keyMatrix);
  if ((keyMatrixInverted == null) || !_validKeyMatrix(keyMatrix, alphabet.length)) {
    return StringText('InvalidKeyMatrix', '');
  }

  var determinant = matrixDeterminant(keyMatrix);
  var inversDeterminant = _multiplicativeInverseOfDeterminant(determinant.round(), alphabet.length);

  for (int i = 0; i < matrixSize; i++) {
    for (int j = 0; j < matrixSize; j++) {
      keyMatrixInverted[i][j] = (keyMatrixInverted[i][j] * determinant * inversDeterminant) % alphabet.length;
    }
  }

  return _convertMessage(message, alphabet, keyMatrixInverted, fillCharacter);
}

StringText _encryptHillCipher(String message, String key, int matrixSize, Map<String, String> alphabet,
    String fillCharacter) {

  // Get key matrix from the key string
  var keyMatrix = _getKeyMatrix(key, matrixSize, alphabet);
  var cipherText = _convertMessage(message, alphabet, keyMatrix, fillCharacter);
  var errorText = cipherText.text;

  if (errorText.isEmpty) {
    var keyMatrixInverted = matrixInvert(keyMatrix);
    errorText = ((keyMatrixInverted == null) || !_validKeyMatrix(keyMatrix, alphabet.length)) ? 'InvalidKeyMatrix' : '';
  }
  return StringText(errorText, cipherText.value);
}

StringText _convertMessage(String message, Map<String, String> alphabet, List<List<double>> keyMatrix,
    String fillCharacter) {
  var messageVector = List<List<double>>.generate(keyMatrix.length, (index) => List<double>.filled(1, 0));
  var alphabetMap = switchMapKeyValue(alphabet);
  var _message = _removeNonAlphabetCharacters(message, alphabet);
  String convertedText = '';
  var k = 0;
  var k1 = 0;

  if (message.isEmpty || _message.isEmpty) return StringText('', message);
  if ((fillCharacter.isEmpty || fillCharacter.length != 1) && _message.length % keyMatrix.length != 0) {
    return StringText('InvalidFillCharacter', '');
  }

  do {
    // Generate vector for the message
    for (int i = 0; i < keyMatrix.length; i++) {
      messageVector[i][0] = _charToValue(k + i < _message.length
          ? _message[k + i]
          : fillCharacter, alphabet).toDouble();
    }

    // Following function generates the converted vector
    _matrixMultiplication(keyMatrix, messageVector, alphabet.length)?.forEach((value) {
      while (k1 < message.length && !alphabet.containsKey(message[k1].toUpperCase())) {
        convertedText += message[k1];
        k1++;
      }
      // Generate the text from the vector
      convertedText += _valueToChar(value[0].round() % alphabet.length, alphabetMap);

      k++;
      k1++;
    });
  } while (k < _message.length);
  return StringText('', convertedText);
}

// Following function generates the key matrix for the key string
List<List<double>> _getKeyMatrix(String key, int matrixSize, Map<String, String> alphabet) {
  if (alphabet.isEmpty || key.isEmpty) matrixSize = 0;
  var keyMatrix = List<List<double>>.generate(matrixSize, (index) => List<double>.filled(matrixSize, 0));
  int k = 0;
  for (int i = 0; i < matrixSize; i++) {
    for (int j = 0; j < matrixSize; j++) {
      keyMatrix[i][j] = _charToValue(k < key.length ? key[k]
          : alphabet.keys.elementAt(min(k - key.length, alphabet.length-1)), alphabet).toDouble();
      k++;
    }
  }
  return keyMatrix;
}

// Following function generates a valid key string
String generateValidKey(int matrixSize, Map<String, String> alphabet) {
  var key = '';
  List<List<double>>? _matrix;
  var values = alphabet.values.map((value) => double.parse(value)).toList();

  for(var i=0; i< 10000; i++) {
    _matrix = _generateRandomMatrix(matrixSize, values);
    if (_validKeyMatrix(_matrix, alphabet.length)) {
      break;
    } else {
      _matrix = null;
    }
  }

  if (_matrix != null) {
    var alphabetMap = switchMapKeyValue(alphabet);
    for (int i = 0; i < matrixSize; i++) {
      for (int j = 0; j < matrixSize; j++) {
        key += _valueToChar(_matrix[i][j].round() % alphabetMap.length, alphabetMap);
      }
    }
  }
  return key;
}

List<List<double>> _generateRandomMatrix(int matrixSize, List<double> values) {
  Random rand = Random();
  var _matrix = List<List<double>>.generate(matrixSize, (index) => List<double>.filled(matrixSize, 0));
  for (int i = 0; i < matrixSize; i++) {
    for (int j = 0; j < matrixSize; j++) {
      _matrix[i][j] = values[rand.nextInt(values.length)];
    }
  }
  return _matrix;
}

String getViewKeyMatrix(String key, int matrixSize, Map<String, String> alphabet) {
  key = _removeNonAlphabetCharacters(key, alphabet);
  var keyMatrix = _getKeyMatrix(key, matrixSize, alphabet);
  var output = '';
  for (int i = 0; i < keyMatrix.length; i++) {
    for (int j = 0; j < keyMatrix[i].length; j++) {
      output += keyMatrix[i][j].round().toString().padLeft(2, ' ') + ' ';
    }
    output = output.trimRight() + '\n';
  }
  return output;
}

String getViewAlphabet(Map<String, String> alphabet) {
  var output = List<String>.filled(2, '', growable: true);
  var lineOffset = 0;
  for (var entry in alphabet.entries) {
    output[lineOffset + 0] += entry.key.padLeft(3, ' ');
    output[lineOffset + 1] += entry.value.padLeft(3, ' ');
  }

  return output.join('\n');
}

int _charToValue(String char, Map<String, String> alphabet) {
  var value = alphabet[char.toUpperCase()];
  return value == null ? -1 : int.parse(value);
}

String _valueToChar(int value, Map<String, String> alphabet) {
  var char = alphabet[value.toString()];
  return char ?? UNKNOWN_ELEMENT;
}

bool _validKeyMatrix(List<List<double>> keyMatrix, int alphabetLength) {
  var determinant = matrixDeterminant(keyMatrix);
  var inversDeterminant = _multiplicativeInverseOfDeterminant(determinant.round(), alphabetLength);
  if (inversDeterminant == 0) return false;

  var _divisors = divisors(alphabetLength);
  _divisors.remove(1);
  _divisors.remove(alphabetLength);
  if (_divisors.isEmpty) return false;

  return true;
}

String _removeNonAlphabetCharacters(String text, Map<String, String> alphabet ) {
  return text.split('').map((char) => alphabet.containsKey(char.toUpperCase()) ? char : '').join();
}

// Following function convert the message
List<List<double>>? _matrixMultiplication(List<List<double>> keyMatrix, List<List<double>> messageVector, int alphabetLength) {
  var resultMatrix = matrixMultiplication(keyMatrix, messageVector);
  if (resultMatrix == null) return null;

  for (int i = 0; i < resultMatrix.length; i++) {
    for (int j = 0; j < resultMatrix[i].length; j++) {
      resultMatrix[i][j] %= alphabetLength;
    }
  }
  return resultMatrix;
}

int _multiplicativeInverseOfDeterminant(int matrixDeterminant, int modulo) {
  for (int i = 1; i < modulo; i++) {
    if (((matrixDeterminant * i) % modulo) == 1) return i;
  }
  return 0;
}