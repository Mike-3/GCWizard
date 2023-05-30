import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:gc_wizard/tools/symbol_tables/_common/logic/symbol_table_data.dart';
import 'package:gc_wizard/tools/symbol_tables/_common/widget/gcw_symbol_container.dart';
import 'package:gc_wizard/tools/symbol_tables/symbol_replacer/logic/hash_config_file.dart';
import 'package:gc_wizard/tools/symbol_tables/symbol_replacer/logic/hash_config_file.dart';
import 'package:gc_wizard/utils/file_utils/file_utils.dart';

class SymbolReplacerSymbolTableViewData {
  final String symbolKey;
  final GCWSymbolContainer? icon;
  final String? toolName;
  final String? description;
  SymbolReplacerSymbolTableData? data;

  SymbolReplacerSymbolTableViewData({
    required this.symbolKey,
    required this.icon,
    required this.toolName,
    required this.description,
    this.data});

  Future<SymbolReplacerSymbolTableData?> initialize(BuildContext context, Future<HashConfigFile?>? hashConfigFile) async {
    var originalData = SymbolTableData(context, symbolKey);
    await originalData.initialize(importEncryption: false);

    data = SymbolReplacerSymbolTableData(originalData, symbolKey, hashConfigFile);
    return Future.value(data);
  }
}

class SymbolReplacerSymbolTableData {
  late List<Map<String, SymbolReplacerSymbolData>> images;

  SymbolReplacerSymbolTableData(SymbolTableData data, String? symbolKey, Future<HashConfigFile?>? hashConfigFile) {
    images = data.images.map((Map<String, SymbolData> elem) {
      Map<String, SymbolReplacerSymbolData> _tempMap = {};
      elem.forEach((String key, SymbolData value) {
        _tempMap.putIfAbsent(key, () => SymbolReplacerSymbolData(value, symbolKey, hashConfigFile));
      });

      return _tempMap;
    }).toList();
  }
}

class SymbolReplacerSymbolData {
  Uint8List? bytes;
  String? displayName;
  int hash = 0;

  SymbolReplacerSymbolData(SymbolData data, String? symbolKey, Future<HashConfigFile?>? hashConfigFile) {
    bytes = data.bytes;
    displayName = data.displayName;
    if (symbolKey != null && hashConfigFile != null) {
      hashConfigFile.then((value) {
        hash = value?.symbolTableHashes(symbolKey)?[changeExtension(data.path, '')] ?? 0;
      });
    }
  }
}
