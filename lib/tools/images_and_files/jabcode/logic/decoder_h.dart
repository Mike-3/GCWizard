/*
 libjabcode - JABCode Encoding/Decoding Library

 Copyright 2016 by Fraunhofer SIT. All rights reserved.
 See LICENSE file for full terms of use and distribution.

 Contact: Huajian Liu <liu@sit.fraunhofer.de>
			Waldemar Berchtold <waldemar.berchtold@sit.fraunhofer.de>

 Decoder header
*/

import 'dart:typed_data';

import 'package:gc_wizard/tools/images_and_files/jabcode/logic/jabcode_h.dart';

const DECODE_METADATA_FAILED = -1;
const FATAL_ERROR = -2;	//e.g. out of memory

const MASTER_METADATA_X =	6;
const MASTER_METADATA_Y	= 1;

const MASTER_METADATA_PART1_LENGTH = 6;			//master metadata part 1 encoded length
const MASTER_METADATA_PART2_LENGTH = 38;			//master metadata part 2 encoded length
const MASTER_METADATA_PART1_MODULE_NUMBER = 4;	//the number of modules used to encode master metadata part 1

/*
 The positions of the first 32 color palette modules in slave symbol
*/
final slave_palette_position = List<jab_vector2d>.from(
	[	{4, 5}, {4, 6}, {4, 7}, {4, 8}, {4, 9}, {4, 10}, {4, 11}, {4, 12},
		{5, 12}, {5, 11}, {5, 10}, {5, 9}, {5, 8}, {5, 7}, {5, 6}, {5, 5},
		{6, 5}, {6, 6}, {6, 7}, {6, 8}, {6, 9}, {6, 10}, {6, 11}, {6, 12},
		{7, 12}, {7, 11}, {7, 10}, {7, 9}, {7, 8}, {7, 7}, {7, 6}, {7, 5}
	]);

/*
 Decoding tables
*/
final jab_decoding_table_upper   = Int8List.fromList([32, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90]);
final jab_decoding_table_lower   = Int8List.fromList([32, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122]);
final jab_decoding_table_numeric = Int8List.fromList([32, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 44, 46]);
final jab_decoding_table_punct   = Int8List.fromList([33, 34, 36, 37, 38, 39, 40, 41, 44, 45, 46, 47, 58, 59, 63, 64]);
final jab_decoding_table_mixed   = Int8List.fromList([35, 42, 43, 60, 61, 62, 91, 92, 93, 94, 95, 96, 123, 124, 125, 126, 9, 10, 13, 0, 0, 0, 0, 164, 167, 196, 214, 220, 223, 228, 246, 252]);
final jab_decoding_table_alphanumeric = Int8List.fromList([32, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85,
															 86, 87, 88, 89, 90, 97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122]);

/*
 Encoding mode
*/
class jab_encode_mode {
	static const None = -1;
	static const Upper = 0;
	static const Lower = 1;
	static const Numeric = 2;
	static const Punct = 3;
	static const Mixed = 4;
	static const Alphanumeric = 5;
	static const Byte = 6;
	static const ECI = 7;
	static const FNC1 = 8;
}

