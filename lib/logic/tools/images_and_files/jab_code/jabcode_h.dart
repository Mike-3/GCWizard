import 'dart:core';
import 'dart:ffi';
import 'dart:typed_data';

/**
 * libjabcode - JABCode Encoding/Decoding Library
 *
 * Copyright 2016 by Fraunhofer SIT. All rights reserved.
 * See LICENSE file for full terms of use and distribution.
 *
 * Contact: Huajian Liu <liu@sit.fraunhofer.de>
 *			Waldemar Berchtold <waldemar.berchtold@sit.fraunhofer.de>
 *
 * @file jabcode.h
 * @brief Main libjabcode header
 */

// #ifndef JABCODE_H
// const JABCODE_H

const VERSION ="2.0.0";
//const BUILD_DATE = __DATE__

const MAX_SYMBOL_NUMBER       = 61;
const MAX_COLOR_NUMBER        = 256;
const MAX_SIZE_ENCODING_MODE  = 256;
const JAB_ENCODING_MODES      = 6;
const ENC_MAX                 = 1000000;
const NUMBER_OF_MASK_PATTERNS	= 8;

const DEFAULT_SYMBOL_NUMBER 		=	1;
const DEFAULT_MODULE_SIZE				= 12;
const DEFAULT_COLOR_NUMBER 			= 8;
const DEFAULT_MODULE_COLOR_MODE =	2;
const DEFAULT_ECC_LEVEL				  = 3;
const DEFAULT_MASKING_REFERENCE = 7;


const DISTANCE_TO_BORDER      = 4;
const MAX_ALIGNMENT_NUMBER    = 9;
const COLOR_PALETTE_NUMBER	= 4;

const BITMAP_BITS_PER_PIXEL	= 32;
const BITMAP_BITS_PER_CHANNEL	= 8;
const BITMAP_CHANNEL_COUNT	= 4;

const	JAB_SUCCESS		= 1;
const	JAB_FAILURE		= 0;

const NORMAL_DECODE		= 0;
const COMPATIBLE_DECODE	= 1;

// const VERSION2SIZE(x)		(x * 4 + 17)
// const SIZE2VERSION(x)		((x - 17) / 4)
// const MAX(a,b) 			({__typeof__ (a) _a = (a); __typeof__ (b) _b = (b); _a > _b ? _a : _b;})
// const MIN(a,b) 			({__typeof__ (a) _a = (a); __typeof__ (b) _b = (b); _a < _b ? _a : _b;})

JAB_REPORT_ERROR(String x)	{ print("JABCode Error: "); print (x); print("\n"); }
JAB_REPORT_INFO(String x)	{ print("JABCode Info: "); print (x); print("\n"); }

//typedef byte 		jab_byte;
//typedef char 				jab_char;
//typedef unsigned char 		jab_boolean;
//typedef int 				jab_int32;
//typedef unsigned int 		jab_uint32;
//typedef short 				jab_int16;
//typedef unsigned short 		jab_uint16;
//typedef long long 			jab_int64;
//typedef unsigned long long	jab_uint64;
//typedef float				jab_float;
//typedef double              jab_double;

/**
 * @brief 2-dimensional integer vector
*/
class jab_vector2d {
	int	x;
	int	y;
}

/**
 * @brief 2-dimensional float vector
*/
class jab_point {
	double	x;
double	y;
}

/**
 * @brief Data structure
*/
class jab_data {
	int	length;
	String	data;
}

/**
 * @brief Code bitmap
*/
class jab_bitmap {
   int	width;
   int	height;
   int	bits_per_pixel;
   int	bits_per_channel;
   int	channel_count;
   Int8List		pixel;
}

/**
 * @brief Symbol parameters
*/
class jab_symbol {
	int		index;
	jab_vector2d	side_size;
	int		host;
	var		slaves = List<int>.filled(4,0); //[4]
	var 		wcwr =  List<int>.filled(2,0); //[2]
	jab_data		data;
	Int8List		data_map;
	jab_data		metadata;
	Int8List		matrix;
}

/**
 * @brief Encode parameters
*/
class jab_encode {
	int		color_number;
	int		symbol_number;
	int		module_size;
	int		master_symbol_width;
	int		master_symbol_height;
	Int8List		palette;				///< Palette holding used module colors in format RGB
	jab_vector2d	symbol_versions;
	Int8List 		symbol_ecc_levels;
	Int32List		symbol_positions;
	jab_symbol		symbols;				///< Pointer to internal representation of JAB Code symbols
	jab_bitmap		bitmap;
}

/**
 * @brief Decoded metadata
*/
class jab_metadata {
	bool default_mode;
	int Nc;
	int mask_type;
	int docked_position;
	jab_vector2d side_version;
	jab_vector2d ecl;
}

/**
 * @brief Decoded symbol
*/
class jab_decoded_symbol {
	int index;
	int host_index;
	int host_position;
	jab_vector2d side_size;
	double module_size;
	var pattern_positions = List<jab_point>.filled(4, null); //4
	jab_metadata metadata;
	var slave_metadata = List<jab_metadata>.filled(4, null); //4
	Int8List palette;
	jab_data data;
}


//extern jab_encode* createEncode(jab_int32 color_number, jab_int32 symbol_number);
//extern void destroyEncode(jab_encode* enc);
//extern jab_int32 generateJABCode(jab_encode* enc, jab_data* data);
//extern jab_data* decodeJABCode(jab_bitmap* bitmap, jab_int32 mode, jab_int32* status);
//extern jab_data* decodeJABCodeEx(jab_bitmap* bitmap, jab_int32 mode, jab_int32* status, jab_decoded_symbol* symbols, jab_int32 max_symbol_number);
//extern jab_boolean saveImage(jab_bitmap* bitmap, jab_char* filename);
//extern jab_boolean saveImageCMYK(jab_bitmap* bitmap, jab_boolean isCMYK, jab_char* filename);
//extern jab_bitmap* readImage(jab_char* filename);
//extern void reportError(jab_char* message);
//
//#endif
