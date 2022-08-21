// #include <stdio.h>
// #include <stdlib.h>
// #include <string.h>
// #include "jabcode.h"
//
// /**
//  * @brief Print usage of JABCode reader
// */
// void printUsage()
// {
// 	printf("\n");
// 	printf("jabcodeReader (Version %s Build date: %s) - Fraunhofer SIT\n\n", VERSION, BUILD_DATE);
// 	printf("Usage:\n\n");
// 	printf("jabcodeReader input-image(png) [--output output-file]\n");
// 	printf("\n");
// 	printf("--output\tOutput file for decoded data.\n");
// 	printf("--help\t\tPrint this help.\n");
// 	printf("\n");
// }

import 'dart:convert';
import 'dart:typed_data';
import 'package:tuple/tuple.dart';
import 'package:utility/utility.dart';

import 'detector.dart';
import 'encoder.dart';
import 'image.dart';
import 'jabcode_h.dart';

/**
 * @brief JABCode reader main function
 * @return 0: success | 255: not detectable | other non-zero: decoding failed
*/
Future<Tuple2<String, String>> scanBytes(Uint8List bytes) async {
	//load image
	var bitmap = readImage(bytes); //argv[1]

	if(bitmap == null)
		return null;

	//find and decode JABCode in the image
	int decode_status;
	var symbols = List<jab_decoded_symbol>.filled(MAX_SYMBOL_NUMBER, null);
	var result = decodeJABCodeEx(bitmap, NORMAL_DECODE, symbols, MAX_SYMBOL_NUMBER);
	var decoded_data = result.item1;
	decode_status = result.item2;
	if(decoded_data == null) {
		// free(bitmap);
		// reportError("Decoding JABCode failed");
		if(decode_status > 0)
			return Future.value(Tuple2<String, String> (null, (symbols[0].module_size + 0.5).toInt().toString())); //(symbols[0].module_size + 0.5).toInt();
		else
			return Future.value(Tuple2<String, String> (null, 255.toString()));;
	}

	//output warning if the code is only partly decoded with COMPATIBLE_DECODE mode
	if(decode_status == 2) {
		return Future.value(Tuple2<String, String> (null,
				"The code is only partly decoded. Some slave symbols have not been decoded and are ignored."));
		// JAB_REPORT_INFO(("The code is only partly decoded. Some slave symbols have not been decoded and are ignored."));
	}

	return Future.value(Tuple2<String, String> (null, String.fromCharCodes(decoded_data.data)));
}

/// Generating Jab Code
Future<Uint8List> generateJabCode(String code,
		{int color_number = 8,
			int moduleSize = 12,
			int symbol_number = 1,
			double border = 10}) async {
	if (code == null || code == "") return null;

	var enc = createEncode(color_number, symbol_number);
	var data = jab_data();
	data.data = utf8.encode(code);
	data.length= data.data.length;

	var result = generateJABCode(enc, data) ;
	if (result != 0) return null;

	return saveImage(enc.bitmap, border);
}
