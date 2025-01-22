import 'dart:convert';
import 'dart:typed_data';
import 'package:gc_wizard/tools/images_and_files/jabcode/logic/detector.dart';
import 'package:gc_wizard/tools/images_and_files/jabcode/logic/encoder.dart';
import 'package:gc_wizard/tools/images_and_files/jabcode/logic/image.dart';
import 'package:gc_wizard/tools/images_and_files/jabcode/logic/jabcode_h.dart';
import 'package:tuple/tuple.dart';

/*
 JABCode reader main function
 @return item1 decoded data
 @return item2 0: success | 255: not detectable | other non-zero: decoding failed
*/
Future<Tuple2<String?, String>?> scanBytes(Uint8List bytes) async {
	//load image
	var bitmap = readImage(bytes);

	if(bitmap == null) {
	  return null;
	}

	//find and decode JABCode in the image
	int? decode_status;
	var result = decodeJABCode(bitmap, NORMAL_DECODE);
	var decoded_data = result?.item1;
	decode_status = result?.item2;
	if(decoded_data == null) {
		// reportError("Decoding JABCode failed");
		if(decode_status != null) {
			return Future.value(Tuple2<String?, String>(
					null, 0.toString())); //(symbols[0].module_size + 0.5).toInt();
		} else {
			return Future.value(Tuple2<String?, String>(null, 255.toString()));
		}
	}

	//output warning if the code is only partly decoded with COMPATIBLE_DECODE mode
	if(decode_status == 2) {
		return Future.value(const Tuple2<String?, String> (null,
				"The code is only partly decoded. Some slave symbols have not been decoded and are ignored."));
		// JAB_REPORT_INFO(("The code is only partly decoded. Some slave symbols have not been decoded and are ignored."));
	}

	return Future.value(Tuple2<String, String> (String.fromCharCodes(decoded_data.data), ''));
}

/// Generating Jab Code
Future<Uint8List?> generateJabCode(String? code,
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

	return saveImage(enc.bitmap!, border);
}
