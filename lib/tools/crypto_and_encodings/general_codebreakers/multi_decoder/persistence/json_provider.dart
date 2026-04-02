import 'dart:convert';
import 'dart:math';

import 'package:gc_wizard/application/settings/logic/preferences.dart';
import 'package:gc_wizard/tools/crypto_and_encodings/general_codebreakers/multi_decoder/persistence/model.dart';
import 'package:gc_wizard/utils/json_utils.dart';
import 'package:gc_wizard/utils/persistence_utils.dart';
import 'package:prefs/prefs.dart';

void refreshMultiDecoderTools() {
  var tools = Prefs.getStringList(PREFERENCE_MULTIDECODER_TOOLS);

  multiDecoderTools = tools.where((tool) => tool.isNotEmpty).map((tool) {
    return MultiDecoderToolEntity.fromJson(asJsonMap(jsonDecode(tool)));
  }).toList();
}

void _saveData() {
  var jsonData = multiDecoderTools.map((tool) => jsonEncode(tool.toMap())).toList();
  Prefs.setStringList(PREFERENCE_MULTIDECODER_TOOLS, jsonData);
}

int insertMultiDecoderTool(MultiDecoderToolEntity tool) {
  tool.name = tool.name;
  var id = newID(multiDecoderTools.map((group) => group.id).toList());
  tool.id = id;
  multiDecoderTools.insert(0, tool);

  _saveData();

  return id;
}

void deleteMultiDecoderTool(int toolId) {
  multiDecoderTools.removeWhere((tool) => tool.id == toolId);

  _saveData();
}

void clearMultiDecoderTools() {
  multiDecoderTools.clear();

  _saveData();
}

int moveMultiDecoderTool(int oldIndex, int newIndex) {
  newIndex = max(newIndex, 0);
  newIndex = min(newIndex, multiDecoderTools.length - 1);

  if (oldIndex >= 0 && oldIndex < multiDecoderTools.length) {
    var mdtTool = multiDecoderTools.removeAt(oldIndex);
    multiDecoderTools.insert(newIndex, mdtTool);

    _saveData();
  }
  return newIndex;
}

void updateMultiDecoderTools() {
  _saveData();
}

void updateMultiDecoderTool(MultiDecoderToolEntity tool) {
  multiDecoderTools = multiDecoderTools.map((currentTool) {
    if (currentTool.id == tool.id) return tool;

    return currentTool;
  }).toList();

  _saveData();
}
