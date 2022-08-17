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

import 'detector.dart';
import 'image.dart';
import 'jabcode_h.dart';

/**
 * @brief JABCode reader main function
 * @return 0: success | 255: not detectable | other non-zero: decoding failed
*/
int main(int argc, String argv[])
{
	// if(argc < 2 || (0 == strcmp(argv[1],"--help")))
	// {
	// 	printUsage();
	// 	return 255;
	// }

	bool output_as_file = false;
	// if(argc > 2)
	// {
	// 	if(0 == strcmp(argv[2], "--output"))
	// 		output_as_file = true;
	// 	else
	// 	{
	// 		// printf("Unknown parameter: %s\n", argv[2]);
	// 		return 255;
	// 	}
	// }

	//load image
	var bitmap = readImage(@"C:\"); //argv[1]

	if(bitmap == null)
		return 255;

	//find and decode JABCode in the image
	int decode_status;
	var symbols = List<jab_decoded_symbol>.filled(MAX_SYMBOL_NUMBER, null);
	var result = decodeJABCodeEx(bitmap, NORMAL_DECODE, symbols, MAX_SYMBOL_NUMBER);
	var decoded_data = result.item1;
	decode_status = result.item2;
	if(decoded_data == null)
	{
		// free(bitmap);
		// reportError("Decoding JABCode failed");
		if(decode_status > 0)
			return (symbols[0].module_size + 0.5).toInt();
		else
			return 255;
	}

	//output warning if the code is only partly decoded with COMPATIBLE_DECODE mode
	if(decode_status == 2)
	{
		JAB_REPORT_INFO(("The code is only partly decoded. Some slave symbols have not been decoded and are ignored."));
	}

	//output result
	if(output_as_file)
	{
		// FILE* output_file = fopen(argv[3], "wb");
		// if(output_file == null)
		// {
		// 	// reportError("Can not open the output file");
		// 	return 255;
		// }
		// fwrite(decoded_data.data, decoded_data.length, 1, output_file);
		// fclose(output_file);
	}
	else
	{
		for(int i=0; i<decoded_data.length; i++)
			print(decoded_data.data[i]);
		print("\n");
	}

	// free(bitmap);
	// free(decoded_data);
    return 0;
}
