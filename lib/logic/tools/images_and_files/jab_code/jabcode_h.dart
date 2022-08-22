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
int SIZE2VERSION(int x) { return ((x - 17) / 4).toInt();}

/*
 2-dimensional integer vector
*/
class jab_vector2d {
	int	x;
	int	y;

	jab_vector2d(intx, inty) {
		this.x = x;
		this.y = y;
	}
}

/*
 2-dimensional float vector
*/
class jab_point {
	double	x;
	double	y;

	jab_point(double x, double y) {
		this.x = x;
		this.y = y;
	}
}

/*
 Data structure
*/
class jab_data {
	int	length;
	Uint8List data;
}

/*
 Code bitmap
*/
class jab_bitmap {
	int	width;
	int	height;
	int	bits_per_pixel;
	int	bits_per_channel;
	int	channel_count;
	Uint8List		pixel;

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
	int		index;
	jab_vector2d	side_size;
	int		host;
	var		slaves = List<int>.filled(4,0);
	var 		wcwr =  List<int>.filled(2,0);
	jab_data		data;
	Int8List		data_map;
	jab_data		metadata;
	Int8List		matrix;
}

/*
 Encode parameters
*/
class jab_encode {
	int		color_number;
	int		symbol_number;
	int		module_size;
	int		master_symbol_width;
	int		master_symbol_height;
	Int8List		palette;				///< Palette holding used module colors in format RGB
	List<jab_vector2d>	symbol_versions;
	Int8List 		symbol_ecc_levels;
	Int32List		symbol_positions;
	List<jab_symbol>		symbols;				///< Pointer to internal representation of JAB Code symbols
	jab_bitmap		bitmap;
}

/*
 Decoded metadata
*/
class jab_metadata {
	bool default_mode;
	int Nc;
	int mask_type;
	int docked_position;
	jab_vector2d side_version;
	jab_vector2d ecl;
}

/*
 Decoded symbol
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

