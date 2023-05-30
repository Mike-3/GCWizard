import 'dart:convert';
import 'dart:core';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:gc_wizard/utils/json_utils.dart';

class HashConfigFile {
  static const _SYMBOLREPLACER_ASSETLOCATION = 'assets/symbol_replacer/config.zip';
  static const _CONFIG_FILENAME = 'config.file';
  Map<String, Map<String, int>>? configFile;

  Future<HashConfigFile?> loadConfigFile(BuildContext context) async {
    // Read the Zip file from disk.
    final bytes = await DefaultAssetBundle.of(context).load(_SYMBOLREPLACER_ASSETLOCATION);
    InputStream input = InputStream(bytes.buffer.asByteData());
    // Decode the Zip file
    final Archive archive = ZipDecoder().decodeBuffer(input);

    var configFile = archive.files.firstWhereOrNull((file) => file.name == _CONFIG_FILENAME);
    if (configFile == null) return Future.value(null);

    var jsonConfig = asJsonMap(json.decode(utf8.decode((configFile.content as Uint8List))));

    var output = <String, Map<String, int>>{};

    jsonConfig.forEach((key, value) {
      if (value is Map) {
        var sublist = <String, int>{};
        value.forEach((key, value) {
          if (value is int) {
            sublist.addAll({key.toString(): value});
          } else if (value is double) {
            sublist.addAll({key.toString(): value.toInt()});
          }
        });
        if (sublist. isNotEmpty) {
          output.addAll({key: sublist});
        } else {
          output = output;
        }
      } else {
        output = output;
      }
    });

    this.configFile = output;
    return this;
  }

  Map<String, int>? symbolTableHashes(String symbolKey) {
    return configFile?[symbolKey];
  }
}
