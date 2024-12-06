part of 'package:gc_wizard/tools/games/game_of_life/logic/game_of_life.dart';

GameOfLifeData? importRLE(GCWFile file) {
  var sizeRegex = RegExp(r'^[xX]\s*=\s*(\d+)\s*,\s*[yY]\s*=\s*(\d+)', multiLine: true);
  var ruleRegex = RegExp(r',\s*rule\s*=\s*([sSbB])(\d+)\s*\\\s*([sSbB])(\d+)');
  var patternRegex = RegExp(r'(\d*)([bo$])', multiLine: true);

  var text = convertBytesToString(file.bytes);

  var sizeMatch = sizeRegex.firstMatch(text);
  if (sizeMatch == null) return null;

  var dataStart = text.indexOf('\n', sizeMatch.end);
  var dataEnd = text.indexOf('!', sizeMatch.end);
  if (dataStart < 0 || dataEnd < 0) return null;

  var rules = buildRule(ruleRegex.firstMatch(text.substring(sizeMatch.end, dataStart));

  var count = 0;
  var count2 = 0;
  var currentLine = 0;
  var currentPos = 0;
  var dataError = false;
  var board = GameOfLifeData(Point<int>(int.parse(sizeMatch[1]!), int.parse(sizeMatch[2]!)), rules);

  patternRegex.allMatches(text.substring(dataStart + 1, dataEnd + 1)).forEach((pattern) {
    count = (pattern[1] == null || pattern[1]!.isEmpty) ? 1 : int.parse(pattern[1]!);
    switch (pattern[2]) {
      case 'o':
        for (var i = 0; i < count; i++) {
          if (currentLine < board.currentBoard.length &&  currentPos + i < board.currentBoard[currentLine].length) {
            board.currentBoard[currentLine][currentPos + i] = true;
          } else {
            dataError = true;
          }
        }
      case 'b':
        currentPos += count;
        break;
      case '\$':
        currentLine += count;
        currentPos = 0;
        break;
    }
      count2++;

  });
  print(count.toString() + ' ' + (board.size.x * board.size.y).toString() + ' ' + count2.toString());
  return board;
}

GameOfLifeRules buildRules(RegExpMatch? match) {
  if (match == null) return DEFAULT_GAME_OF_LIFE_RULES.values.first;

  var survivalsIndex = match[1] == 's' || match[1] == 'S' ? 2 : 4;
  var birthIndex = survivalsIndex == 2 ? 4 : 2;

  var survivals = GameOfLifeRules.toSet(match[survivalsIndex]).sort();
  var births = GameOfLifeRules.toSet(match[birthIndex]).sort();

  DEFAULT_GAME_OF_LIFE_RULES.forEach((rule) {
    if (listEquals(rule.survivals, survivals) && listEquals(rule.births, births)) {
      return rule;
    }
  });

  return GameOfLifeRules(
      survivals: survivals,
      births: births,
      key: KEY_CUSTOM_RULES);
}
