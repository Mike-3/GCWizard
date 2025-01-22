/*
 libjabcode - JABCode Encoding/Decoding Library

 Copyright 2016 by Fraunhofer SIT. All rights reserved.
 See LICENSE file for full terms of use and distribution.

 Contact: Huajian Liu <liu@sit.fraunhofer.de>
			Waldemar Berchtold <waldemar.berchtold@sit.fraunhofer.de>

 Main libjabcode header
*/

import 'dart:core';
import 'dart:typed_data';

const VERSION ="2.0.0";
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

// const BITMAP_BITS_PER_PIXEL	= 32;
 const BITMAP_BITS_PER_CHANNEL	= 8;
 const BITMAP_CHANNEL_COUNT	= 4;

const	JAB_SUCCESS		= 1;
const	JAB_FAILURE		= 0;

const NORMAL_DECODE		= 0;
const COMPATIBLE_DECODE	= 1;

int VERSION2SIZE(int x) {return (x * 4 + 17);}
int SIZE2VERSION(int x) { return (x - 17) ~/ 4;}

/*
 2-dimensional integer vector
*/
class jab_vector2d {
	int	x;
	int	y;

	jab_vector2d(this.x, this.y) {}
}

/*
 2-dimensional float vector
*/
class jab_point {
	double	x;
	double	y;

	jab_point(this.x, this.y) {}
}

/*
 Data structure
*/
class jab_data {
	int	length = 0;
	Uint8List data = Uint8List(0);
}

/*
 Code bitmap
*/
class jab_bitmap {
	int	width = 0;
	int	height = 0;
	int	bits_per_pixel = 0;
	int	bits_per_channel = 0;
	int	channel_count = 0;
	Uint8List	pixel = Uint8List(0);

	jab_bitmap clone() {
		var _clone = jab_bitmap();
		_clone.width = width;
		_clone.height = height;
		_clone.bits_per_pixel = bits_per_pixel;
		_clone.bits_per_channel = bits_per_channel;
		_clone.channel_count = channel_count;
		_clone.pixel = Uint8List.fromList(pixel);

		return _clone;
	}
}

/*
 Symbol parameters
*/
class jab_symbol {
	int	index = 0;
	jab_vector2d	side_size = jab_vector2d(0, 0);
	int	host = 0;
	var	slaves = List<int>.filled(4,0);
	var wcwr =  List<int>.filled(2,0);
	jab_data		data = jab_data();
	Int8List		data_map = Int8List(0);
	jab_data		metadata= jab_data();
	Int8List		matrix = Int8List(0);
}

/*
 Encode parameters
*/
class jab_encode {
	int	color_number = 0;
	int	symbol_number = 0;
	int	module_size = 0;
	int	master_symbol_width = 0;
	int	master_symbol_height = 0;
	Int8List?	palette;				///< Palette holding used module colors in format RGB
	List<jab_vector2d> symbol_versions = [];
	Int8List symbol_ecc_levels = Int8List(0);
	Int32List symbol_positions = Int32List(0);
	List<jab_symbol>	symbols = [];				///< Pointer to internal representation of JAB Code symbols
	jab_bitmap?	bitmap;
}

/*
 Decoded metadata
*/
class jab_metadata {
	bool default_mode = false;
	int Nc = 0;
	int mask_type = 0;
	int docked_position = 0;
	jab_vector2d? side_version;
	jab_vector2d? ecl;
}

/*
 Decoded symbol
*/
class jab_decoded_symbol {
	int index = 0;
	int host_index = 0 ;
	int host_position = 0 ;
	jab_vector2d? side_size;
	double module_size = 0;
	var pattern_positions = List<jab_point>.filled(4, jab_point(0,0)); //4
	jab_metadata? metadata;
	List<jab_metadata?> slave_metadata = List<jab_metadata?>.filled(4, null); //4
	Int8List? palette;
	jab_data? data;
}

