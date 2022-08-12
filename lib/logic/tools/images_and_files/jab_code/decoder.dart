/**
 * libjabcode - JABCode Encoding/Decoding Library
 *
 * Copyright 2016 by Fraunhofer SIT. All rights reserved.
 * See LICENSE file for full terms of use and distribution.
 *
 * Contact: Huajian Liu <liu@sit.fraunhofer.de>
 *			Waldemar Berchtold <waldemar.berchtold@sit.fraunhofer.de>
 *
 * @file decoder.c
 * @brief Data decoding
 */

//#include <stdio.h>
//#include <stdlib.h>
//#include <string.h>
//#include <math.h>
//#include "jabcode.h"
//#include "detector.h"
//#include "decoder.h"
//#include "ldpc.h"
//#include "encoder.h"

import 'dart:core';
import 'dart:ffi';
import 'dart:math';
import 'dart:typed_data';

import 'package:tuple/tuple.dart';

import 'binarizer.dart';
import 'decoder_h.dart';
import 'detector_h.dart';
import 'encoder_h.dart';
import 'jabcode_h.dart';
import 'ldpc.dart';



memcpy(Int8List palette,int dst, int src, int length) {
	palette.replaceRange(dst, dst + length, palette.getRange(src, src + length));
}

/**
 * @brief Copy 16-color sub-blocks of 64-color palette into 32-color blocks of 256-color palette and interpolate into 32 colors
 * @param palette the color palette
 * @param dst_offset the start offset in the destination palette
 * @param src_offset the start offset in the source palette
*/
void copyAndInterpolateSubblockFrom16To32(Int8List palette, int dst_offset, int src_offset)
{
	//copy
	memcpy(palette, dst_offset + 84, src_offset + 36, 12);
	memcpy(palette, dst_offset + 60, src_offset + 24, 12);
	memcpy(palette, dst_offset + 24, src_offset + 12, 12);
	memcpy(palette, dst_offset + 0, src_offset + 0, 12);
	
	//interpolate
	for(int j=0; j<12; j++)
	{
		int sum = palette[dst_offset + 0 + j] + palette[dst_offset + 24 + j];
		palette[dst_offset + 12 + j] = (sum / 2) as int;
	}
	for(int j=0; j<12; j++)
	{
		int sum = palette[dst_offset + 24 + j] * 2 + palette[dst_offset + 60 + j];
		palette[dst_offset + 36 + j] = (sum / 3) as int;
		sum = palette[dst_offset + j] + palette[dst_offset + 60 + j] * 2;
		palette[dst_offset + 48 + j] = (sum / 3) as int;
	}
	for(int j=0; j<12; j++)
	{
		int sum = palette[dst_offset + 60 + j] + palette[dst_offset + 84 + j];
		palette[dst_offset + 72 + j] = (sum / 2) as int;
	}
}

/**
 * @brief Interpolate 64-color palette into 128-/256-color palette
 * @param palette the color palette
 * @param color_number the number of colors
*/
void interpolatePalette(Int8List palette, int color_number)
{
	for(int i=0; i<COLOR_PALETTE_NUMBER; i++)
	{
		int offset = color_number * 3 * i;
		if(color_number == 128)											//each block includes 16 colors
		{																//block 1 remains the same
			memcpy(palette, offset + 336, offset + 144, 48); //copy block 4 to block 8
			memcpy(palette, offset + 240, offset + 96,  48); //copy block 3 to block 6
			memcpy(palette, offset + 96,  offset + 48,  48); //copy block 2 to block 3

			//interpolate block 1 and block 3 to get block 2
			for(int j=0; j<48; j++)
			{
				int sum = palette[offset + 0 + j] + palette[offset + 96 + j];
				palette[offset + 48 + j] = (sum / 2) as int;
			}
			//interpolate block 3 and block 6 to get block 4 and block 5
			for(int j=0; j<48; j++)
			{
				int sum = palette[offset + 96 + j] * 2 + palette[offset + 240 + j];
				palette[offset + 144 + j] = (sum / 3) as int;
				sum = palette[offset + 96 + j] + palette[offset + 240 + j] * 2;
				palette[offset + 192 + j] = (sum / 3) as int;
			}
			//interpolate block 6 and block 8 to get block 7
			for(int j=0; j<48; j++)
			{
				int sum = palette[offset + 240 + j] + palette[offset + 336 + j];
				palette[offset + 288 + j] = (sum / 2) as int;
			}
		}
		else if(color_number == 256)									//each block includes 32 colors
		{
			//copy sub-block 4 to block 8 and interpolate 16 colors into 32 colors
			copyAndInterpolateSubblockFrom16To32(palette, offset + 672, offset + 144);
			//copy sub-block 3 to block 6 and interpolate 16 colors into 32 colors
			copyAndInterpolateSubblockFrom16To32(palette, offset + 480, offset + 96);
			//copy sub-block 2 to block 3 and interpolate 16 colors into 32 colors
			copyAndInterpolateSubblockFrom16To32(palette, offset + 192, offset + 48);
			//copy sub-block 1 to block 1 and interpolate 16 colors into 32 colors
			copyAndInterpolateSubblockFrom16To32(palette, offset + 0, offset + 0);

			//interpolate block 1 and block 3 to get block 2
			for(int j=0; j<96; j++)
			{
				int sum = palette[offset + 0 + j] + palette[offset + 192 + j];
				palette[offset + 96 + j] = (sum / 2) as int;
			}
			//interpolate block 3 and block 6 to get block 4 and block 5
			for(int j=0; j<96; j++)
			{
				int sum = palette[offset + 192 + j] * 2 + palette[offset + 480 + j];
				palette[offset + 288 + j] = (sum / 3) as int;
				sum = palette[offset + 192 + j] + palette[offset + 480 + j] * 2;
				palette[offset + 384 + j] = (sum / 3) as int;
			}
			//interpolate block 6 and block 8 to get block 7
			for(int j=0; j<96; j++)
			{
				int sum = palette[offset + 480 + j] + palette[offset + 672 + j];
				palette[offset + 576 + j] = (sum / 2) as int;
			}
		}
		else
			return;
	}
}

/**
 * @brief Write colors into color palettes
 * @param matrix the symbol matrix
 * @param symbol the master/slave symbol
 * @param p_index the color palette index
 * @param color_index the color index in color palette
 * @param x the x coordinate of the color module
 * @param y the y coordinate of the color module
*/
void writeColorPalette(jab_bitmap matrix, jab_decoded_symbol symbol, int p_index, int color_index, int x, int y)
{
	int color_number = pow(2, symbol.metadata.Nc + 1);
	int mtx_bytes_per_pixel = (matrix.bits_per_pixel / 8).toInt();
  int mtx_bytes_per_row = matrix.width * mtx_bytes_per_pixel;

	int palette_offset = color_number * 3 * p_index;
	int mtx_offset = y * mtx_bytes_per_row + x * mtx_bytes_per_pixel;
	symbol.palette[palette_offset + color_index*3 + 0] = matrix.pixel[mtx_offset + 0];
	symbol.palette[palette_offset + color_index*3 + 1] = matrix.pixel[mtx_offset + 1];
	symbol.palette[palette_offset + color_index*3 + 2] = matrix.pixel[mtx_offset + 2];
}

/**
 * @brief Get the coordinates of the modules in finder/alignment patterns used for color palette
 * @param p_index the color palette index
 * @param matrix_width the matrix width
 * @param matrix_height the matrix height
 * @param p1 the coordinate of the first module
 * @param p2 the coordinate of the second module
*/
void getColorPalettePosInFP(int p_index, int matrix_width, int matrix_height, jab_vector2d p1, jab_vector2d p2)
{
	switch(p_index)
	{
	case 0:
		p1.x = DISTANCE_TO_BORDER - 1;
		p1.y = DISTANCE_TO_BORDER - 1;
		p2.x = p1.x + 1;
		p2.y = p1.y;
		break;
	case 1:
		p1.x = matrix_width - DISTANCE_TO_BORDER;
		p1.y = DISTANCE_TO_BORDER - 1;
		p2.x = p1.x - 1;
		p2.y = p1.y;
		break;
	case 2:
		p1.x = matrix_width - DISTANCE_TO_BORDER;
		p1.y = matrix_height - DISTANCE_TO_BORDER;
		p2.x = p1.x - 1;
		p2.y = p1.y;
		break;
	case 3:
		p1.x = DISTANCE_TO_BORDER - 1;
		p1.y = matrix_height - DISTANCE_TO_BORDER;
		p2.x = p1.x + 1;
		p2.y = p1.y;
		break;
	}
}

/**
 * @brief Read the color palettes in master symbol
 * @param matrix the symbol matrix
 * @param symbol the master symbol
 * @param data_map the data module positions
 * @param module_count the start module index
 * @param x the x coordinate of the start module
 * @param y the y coordinate of the start module
 * @return JAB_SUCCESS | FATAL_ERROR
*/
int readColorPaletteInMaster(jab_bitmap matrix, jab_decoded_symbol symbol, Int8List data_map, int module_count, int x, int y) // toDo module_count x, y ?? als Reference/ Rückgabe
{
	////allocate buffer for palette
	int color_number = pow(2, symbol.metadata.Nc + 1);
	//free(symbol.palette);
	//symbol.palette = (Int8*)malloc(color_number * sizeof(Int8) * 3 * COLOR_PALETTE_NUMBER);
	//if(symbol.palette == NULL)
	//{
	//	reportError("Memory allocation for master palette failed");
	//	return FATAL_ERROR;
	//}
	symbol.palette = new Int8List(color_number * 3 * COLOR_PALETTE_NUMBER); //ToDo sizecheck

	//read colors from finder patterns
	int color_index;			//the color index number in color palette
	for(int i=0; i<COLOR_PALETTE_NUMBER; i++)
	{
		jab_vector2d p1, p2;
		getColorPalettePosInFP(i, matrix.width, matrix.height, p1, p2);
		//color 0
		color_index = master_palette_placement_index[i][0] % color_number; //for 4-color and 8-color symbols
		writeColorPalette(matrix, symbol, i, color_index, p1.x, p1.y);
		//color 1
		color_index = master_palette_placement_index[i][1] % color_number; //for 4-color and 8-color symbols
		writeColorPalette(matrix, symbol, i, color_index, p2.x, p2.y);
	}

	//read colors from metadata
	int color_counter = 2;	//the color counter
	while(color_counter < min(color_number, 64))
	{
		//color palette 0
		color_index = master_palette_placement_index[0][color_counter] % color_number; //for 4-color and 8-color symbols
		writeColorPalette(matrix, symbol, 0, color_index, x, y);
		//set data map
		data_map[y * matrix.width + x] = 1;
		//go to the next module
		module_count++;
		getNextMetadataModuleInMaster(matrix.height, matrix.width, module_count, x, y);

		//color palette 1
		color_index = master_palette_placement_index[1][color_counter] % color_number; //for 4-color and 8-color symbols
		writeColorPalette(matrix, symbol, 1, color_index, x, y);
		//set data map
		data_map[y * matrix.width + x] = 1;
		//go to the next module
		module_count++;
		getNextMetadataModuleInMaster(matrix.height, matrix.width, (*module_count), x, y);

		//color palette 2
		color_index = master_palette_placement_index[2][color_counter] % color_number; //for 4-color and 8-color symbols
		writeColorPalette(matrix, symbol, 2, color_index, x, y);
		//set data map
		data_map[y * matrix.width + x] = 1;
		//go to the next module
		module_count++;
		getNextMetadataModuleInMaster(matrix.height, matrix.width, module_count, x, y);

		//color palette 3
		color_index = master_palette_placement_index[3][color_counter] % color_number; //for 4-color and 8-color symbols
		writeColorPalette(matrix, symbol, 3, color_index, x, y);
		//set data map
		data_map[y * matrix.width + x] = 1;
		//go to the next module
		module_count++;
		getNextMetadataModuleInMaster(matrix.height, matrix.width, (*module_count), x, y);

		//next color
		color_counter++;
	}

	//interpolate the palette if there are more than 64 colors
	if(color_number > 64)
	{
		interpolatePalette(symbol.palette, color_number);
	}
	return JAB_SUCCESS;
}

/**
 * @brief Read the color palettes in master symbol
 * @param matrix the symbol matrix
 * @param symbol the slave symbol
 * @param data_map the data module positions
 * @return JAB_SUCCESS | FATAL_ERROR
*/
int readColorPaletteInSlave(jab_bitmap matrix, jab_decoded_symbol symbol, Int8List data_map)
{
	//allocate buffer for palette
	int color_number = pow(2, symbol.metadata.Nc + 1);
	symbol.palette?.clear();
	// symbol.palette = (Int8*)malloc(color_number * sizeof(Int8) * 3 * COLOR_PALETTE_NUMBER);
  //   if(symbol.palette == null)
  //   {
	// 	reportError("Memory allocation for slave palette failed");
	// 	return FATAL_ERROR;
  //   }

    //read colors from alignment patterns
    int color_index;			//the color index number in color palette
	for(int i=0; i<COLOR_PALETTE_NUMBER; i++)
	{
		jab_vector2d p1, p2;
		getColorPalettePosInFP(i, matrix.width, matrix.height, &p1, &p2);
		//color 0
		color_index = slave_palette_placement_index[0] % color_number;
		writeColorPalette(matrix, symbol, i, color_index, p1.x, p1.y);
		//color 1
		color_index = slave_palette_placement_index[1] % color_number;
		writeColorPalette(matrix, symbol, i, color_index, p2.x, p2.y);
	}

	//read colors from metadata
	int color_counter = 2;	//the color counter
	while(color_counter < min(color_number, 64))
	{
		int px, py;

		//color palette 0
		px = slave_palette_position[color_counter-2].x;
		py = slave_palette_position[color_counter-2].y;
		color_index = slave_palette_placement_index[color_counter] % color_number;
		writeColorPalette(matrix, symbol, 0, color_index, px, py);
		//set data map
		data_map[py * matrix.width + px] = 1;

		//color palette 1
		px = matrix.width - 1 - slave_palette_position[color_counter-2].y;
		py = slave_palette_position[color_counter-2].x;
		color_index = slave_palette_placement_index[color_counter] % color_number;
		writeColorPalette(matrix, symbol, 1, color_index, px, py);
		//set data map
		data_map[py * matrix.width + px] = 1;

		//color palette 2
		px = matrix.width - 1 - slave_palette_position[color_counter-2].x;
		py = matrix.height - 1 - slave_palette_position[color_counter-2].y;
		color_index = slave_palette_placement_index[color_counter] % color_number;
		writeColorPalette(matrix, symbol, 2, color_index, px, py);
		//set data map
		data_map[py * matrix.width + px] = 1;

		//color palette 3
		px = slave_palette_position[color_counter-2].y;
		py = matrix.height - 1 - slave_palette_position[color_counter-2].x;
		color_index = slave_palette_placement_index[color_counter] % color_number;
		writeColorPalette(matrix, symbol, 3, color_index, px, py);
		//set data map
		data_map[py * matrix.width + px] = 1;

		//next color
		color_counter++;
	}

	//interpolate the palette if there are more than 64 colors
	if(color_number > 64)
	{
		interpolatePalette(symbol.palette, color_number);
	}
	return JAB_SUCCESS;
}

/**
 * @brief Get the index of the nearest color palette
 * @param matrix the symbol matrix
 * @param x the x coordinate of the module
 * @param y the y coordinate of the module
 * @return the index of the nearest color palette
*/
int getNearestPalette(jab_bitmap matrix, int x, int y)
{
	//set the palette coordinate
	var px = List<int>.filled(COLOR_PALETTE_NUMBER, 0);
	var py= List<int>.filled(COLOR_PALETTE_NUMBER, 0);
	px[0] = DISTANCE_TO_BORDER - 1 + 3;
	py[0] = DISTANCE_TO_BORDER - 1;
	px[1] = matrix.width - DISTANCE_TO_BORDER - 3;
	py[1] = DISTANCE_TO_BORDER - 1;
	px[2] = matrix.width - DISTANCE_TO_BORDER - 3;
	py[2] = matrix.height- DISTANCE_TO_BORDER;
	px[3] = DISTANCE_TO_BORDER - 1 + 3;
	py[3] = matrix.height- DISTANCE_TO_BORDER;

	//calculate the nearest palette
	double min = DIST(0, 0, matrix.width, matrix.height);
	int p_index = 0;
	for(int i=0; i<COLOR_PALETTE_NUMBER; i++)
	{
		double dist = DIST(x, y, px[i], py[i]);
		if(dist < min)
		{
			min = dist;
			p_index = i;
		}
	}
	return p_index;
}

/**
 * @brief Decode a module using hard decision
 * @param matrix the symbol matrix
 * @param palette the color palettes
 * @param color_number the number of module colors
 * @param norm_palette the normalized color palettes
 * @param pal_ths the palette RGB value thresholds
 * @param x the x coordinate of the module
 * @param y the y coordinate of the module
 * @return the decoded value
*/
int decodeModuleHD(jab_bitmap matrix, Int8List palette, int color_number, List<double> norm_palette, List<double> pal_ths, int x, int y)
{
	//get the nearest palette
	int p_index = getNearestPalette(matrix, x, y);

	//read the RGB values
	var rgb = Int8List(3);
	int mtx_bytes_per_pixel = (matrix.bits_per_pixel / 8).toInt();
	int mtx_bytes_per_row = matrix.width * mtx_bytes_per_pixel;
	int mtx_offset = y * mtx_bytes_per_row + x * mtx_bytes_per_pixel;
	rgb[0] = matrix.pixel[mtx_offset + 0];
	rgb[1] = matrix.pixel[mtx_offset + 1];
	rgb[2] = matrix.pixel[mtx_offset + 2];

	int index1 = 0;
	int index2 = 0;

	//check black module
	if(rgb[0] < pal_ths[p_index*3 + 0] && rgb[1] < pal_ths[p_index*3 + 1] && rgb[2] < pal_ths[p_index*3 + 2])
	{
		index1 = 0;
		return index1;
	}
	if(palette != null)
	{
	    //normalize the RGB values
        double rgb_max = max(rgb[0].toDouble(), max(rgb[1].toDouble(), rgb[2].toDouble()));
        double r = rgb[0] / rgb_max;
        double g = rgb[1] / rgb_max;
        double b = rgb[2] / rgb_max;
        //double l = ((rgb[0] + rgb[1] + rgb[2]) / 3.0f) / 255.0f;

		double min1 = 255*255*3.0;
		double min2 = 255*255*3.0;
		for(int i=0; i<color_number; i++)
		{
			//normalize the color values in color palette
			double pr = norm_palette[color_number*4*p_index + i*4 + 0];
			double pg = norm_palette[color_number*4*p_index + i*4 + 1];
			double pb = norm_palette[color_number*4*p_index + i*4 + 2];
			//double pl = norm_palette[color_number*4*p_index + i*4 + 3];

			//compare the normalized module color with palette
			double diff = (pr - r) * (pr - r) + (pg - g) * (pg - g) + (pb - b) * (pb - b);// + (pl - l) * (pl - l);

			if(diff < min1)
			{
				//copy min1 to min2
				min2 = min1;
				index2 = index1;
				//update min1
				min1 = diff;
				index1 = i;
			}
			else if(diff < min2)
			{
				min2 = diff;
				index2 = i;
			}
		}

		if(index1 == 0 || index1 == 7)
		{
			int rgb_sum = rgb[0] + rgb[1] + rgb[2];
			int p0_sum = palette[color_number*3*p_index + 0*3 + 0] + palette[color_number*3*p_index + 0*3 + 1] + palette[color_number*3*p_index + 0*3 + 2];
			int p7_sum = palette[color_number*3*p_index + 7*3 + 0] + palette[color_number*3*p_index + 7*3 + 1] + palette[color_number*3*p_index + 7*3 + 2];

			if(rgb_sum < ((p0_sum + p7_sum) / 2))
			{
				index1 = 0;
			}
			else
			{
				index1 = 7;
			}
		}
		//if the minimum is close to the second minimum, do further match
/*		if(min1 * 1.5 > min2)
		{
			//printf("min1(%d) * 1.5 > min2(%d), %d %d %d", index1, index2, rgb[0], rgb[1], rgb[2]);
			int rg = abs(rgb[0] - rgb[1]);
			int rb = abs(rgb[0] - rgb[2]);
			int gb = abs(rgb[1] - rgb[2]);

			int c1rg = abs(palette[color_number*3*p_index + index1*3 + 0] - palette[color_number*3*p_index + index1*3 + 1]);
			int c1rb = abs(palette[color_number*3*p_index + index1*3 + 0] - palette[color_number*3*p_index + index1*3 + 2]);
			int c1gb = abs(palette[color_number*3*p_index + index1*3 + 1] - palette[color_number*3*p_index + index1*3 + 2]);
			int diff1 = abs(rg - c1rg) + abs(rb - c1rb) + abs(gb - c1gb);

			int c2rg = abs(palette[color_number*3*p_index + index2*3 + 0] - palette[color_number*3*p_index + index2*3 + 1]);
			int c2rb = abs(palette[color_number*3*p_index + index2*3 + 0] - palette[color_number*3*p_index + index2*3 + 2]);
			int c2gb = abs(palette[color_number*3*p_index + index2*3 + 1] - palette[color_number*3*p_index + index2*3 + 2]);
			int diff2 = abs(rg - c2rg) + abs(rb - c2rb) + abs(gb - c2gb);

			if(diff2 < diff1)
				index1 = index2;
			//printf("final: %d\n", index1);
		}
*/
	}
	else	//if no palette is available, decode the module as black/white
	{
		index1 = ((rgb[0] > 100 ? 1 : 0) + (rgb[1] > 100 ? 1 : 0) + (rgb[2] > 100 ? 1 : 0)) > 1 ? 1 : 0;
	}
	return index1;
}

/**
 * @brief Decode a module for PartI (Nc) of the metadata of master symbol
 * @param rgb the pixel value in RGB format
 * @return the decoded value
*/
int decodeModuleNc(Uint8List rgb)
{
	int ths_black = 80;
	double ths_std = 0.08;
	//check black pixel
	if(rgb[0] < ths_black && rgb[1] < ths_black && rgb[2] < ths_black)
	{
		return 0;//000
	}
	//check color
	// double ave, vari;
	var result = getAveVar(rgb);
	double std = sqrt(result.item2);	//standard deviation
	// int min, mid, max;
	// int index_min, index_mid, index_max;
	// getMinMax(rgb, &min, &mid, &max, &index_min, &index_mid, &index_max);
	std /= rgb.reduce((curr, next) => curr > next ? curr: next); // max;	//normalize std
	var bits = List<int>.filled(3, 0);
	if(std > ths_std)
	{
		bits[index_max] = 1;
		bits[index_min] = 0;
		double r1 = rgb[index_mid] / rgb[index_min];
		double r2 = rgb[index_max] / rgb[index_mid];
		if(r1 > r2)
			bits[index_mid] = 1;
		else
			bits[index_mid] = 0;
	}
	else
	{
		return 7;//111
	}
	return ((bits[0] << 2) + (bits[1] << 1) + bits[2]);
}

/**
 * @brief Get the pixel value thresholds for each channel of the colors in the palette
 * @param palette the color palette
 * @param color_number the number of colors
 * @param palette_ths the palette RGB value thresholds
*/
void getPaletteThreshold(Int8List palette, int color_number, List<double> palette_ths)
{
	if(color_number == 4)
	{
		int cpr0 = max(palette[0], palette[3]);
		int cpr1 = min(palette[6], palette[9]);
		int cpg0 = max(palette[1], palette[7]);
		int cpg1 = min(palette[4], palette[10]);
		int cpb0 = max(palette[8], palette[11]);
		int cpb1 = min(palette[2], palette[5]);

		palette_ths[0] = (cpr0 + cpr1) / 2.0;
		palette_ths[1] = (cpg0 + cpg1) / 2.0;
		palette_ths[2] = (cpb0 + cpb1) / 2.0;
	}
	else if(color_number == 8)
	{
		int cpr0 = max(max(max(palette[0], palette[3]), palette[6]), palette[9]);
		int cpr1 = min(min(min(palette[12], palette[15]), palette[18]), palette[21]);
		int cpg0 = max(max(max(palette[1], palette[4]), palette[13]), palette[16]);
		int cpg1 = min(min(min(palette[7], palette[10]), palette[19]), palette[22]);
		int cpb0 = max(max(max(palette[2], palette[8]), palette[14]), palette[20]);
		int cpb1 = min(min(min(palette[5], palette[11]), palette[17]), palette[23]);

		palette_ths[0] = (cpr0 + cpr1) / 2.0;
		palette_ths[1] = (cpg0 + cpg1) / 2.0;
		palette_ths[2] = (cpb0 + cpb1) / 2.0;
	}
}

/**
 * @brief Get the coordinate of the next metadata module in master symbol
 * @param matrix_height the height of the matrix
 * @param matrix_width the width of the matrix
 * @param next_module_count the index number of the next module
 * @param x the x coordinate of the current and the next module
 * @param y the y coordinate of the current and the next module
*/
void getNextMetadataModuleInMaster(int matrix_height, int matrix_width, int next_module_count, int x, int y) //ToDo x und y als Referenz/ Rückgabewert
{
	if(next_module_count % 4 == 0 || next_module_count % 4 == 2)
	{
		y = matrix_height - 1 - y;
	}
	if(next_module_count % 4 == 1 || next_module_count % 4 == 3)
	{
		x = matrix_width -1 - x;
	}
	if(next_module_count % 4 == 0)
	{
        if( next_module_count <= 20 ||
           (next_module_count >= 44  && next_module_count <= 68)  ||
           (next_module_count >= 96  && next_module_count <= 124) ||
           (next_module_count >= 156 && next_module_count <= 172))
		{
			y += 1;
		}
        else if((next_module_count > 20  && next_module_count < 44) ||
                (next_module_count > 68  && next_module_count < 96) ||
                (next_module_count > 124 && next_module_count < 156))
		{
			x -= 1;
		}
	}
    if(next_module_count == 44 || next_module_count == 96 || next_module_count == 156)
    {
        int tmp = x;
        x = y;
        y = tmp;
    }
}

/**
 * @brief Decode slave symbol metadata
 * @param host_symbol the host symbol
 * @param docked_position the docked position
 * @param data the data stream of the host symbol
 * @param offset the metadata start offset in the data stream
 * @return the read metadata bit length | DECODE_METADATA_FAILED
*/
int decodeSlaveMetadata(jab_decoded_symbol host_symbol, int docked_position, jab_data data, int offset)
{
	//set metadata from host symbol
	host_symbol.slave_metadata[docked_position].Nc = host_symbol.metadata.Nc;
	host_symbol.slave_metadata[docked_position].mask_type = host_symbol.metadata.mask_type;
	host_symbol.slave_metadata[docked_position].docked_position = 0;

	//decode metadata
	int index = offset;
	int SS, SE, V, E;

	//parse part1
	if(index < 0) return DECODE_METADATA_FAILED;
	SS = data.data[index--];//SS
	if(SS == 0)
	{
		host_symbol.slave_metadata[docked_position].side_version = host_symbol.metadata.side_version;
	}
	if(index < 0) return DECODE_METADATA_FAILED;
	SE = data.data[index--];//SE
	if(SE == 0)
	{
		host_symbol.slave_metadata[docked_position].ecl = host_symbol.metadata.ecl;
	}
	//decode part2 if it exists
	if(SS == 1)
	{
		if((index-4) < 0) return DECODE_METADATA_FAILED;
		V = 0;
		for(int i=0; i<5; i++)
		{
			V += data.data[index--] << (4 - i);
		}
		int side_version = V + 1;
		if(docked_position == 2 || docked_position == 3)
		{
			host_symbol.slave_metadata[docked_position].side_version.y = host_symbol.metadata.side_version.y;
			host_symbol.slave_metadata[docked_position].side_version.x = side_version;
		}
		else
		{
			host_symbol.slave_metadata[docked_position].side_version.x = host_symbol.metadata.side_version.x;
			host_symbol.slave_metadata[docked_position].side_version.y = side_version;
		}
	}
	if(SE == 1)
	{
		if((index-5) < 0) return DECODE_METADATA_FAILED;
		//get wc (the first half of E)
		E = 0;
		for(int i=0; i<3; i++)
		{
			E += data.data[index--] << (2 - i);
		}
		host_symbol.slave_metadata[docked_position].ecl.x = E + 3;	//wc = E_part1 + 3
		//get wr (the second half of E)
		E = 0;
		for(int i=0; i<3; i++)
		{
			E += data.data[index--] << (2 - i);
		}
		host_symbol.slave_metadata[docked_position].ecl.y = E + 4;	//wr = E_part2 + 4

		//check wc and wr
		int wc = host_symbol.slave_metadata[docked_position].ecl.x;
		int wr = host_symbol.slave_metadata[docked_position].ecl.y;
		// if(wc >= wr)
		// {
		// 	reportError("Incorrect error correction parameter in slave metadata");
		// 	return DECODE_METADATA_FAILED;
		// }
	}
	return (offset - index);
}

/**
 * @brief Decode the encoded bits of Nc from the module color
 * @param module1_color the color of the first module
 * @param module2_color the color of the second module
 * @return the decoded bits
*/
int decodeNcModuleColor(Int8 module1_color, Int8 module2_color)
{
	for(int i=0; i<8; i++)
	{
		if(module1_color == nc_color_encode_table[i][0] && module2_color == nc_color_encode_table[i][1])
			return i;
	}
	return 8; //if no match, return an invalid value
}

/**
 * @brief Decode the PartI of master symbol metadata
 * @param matrix the symbol matrix
 * @param symbol the master symbol
 * @param data_map the data module positions
 * @param module_count the index number of the next module
 * @param x the x coordinate of the current and the next module
 * @param y the y coordinate of the current and the next module
 * @return JAB_SUCCESS | JAB_FAILURE | DECODE_METADATA_FAILED
*/
int decodeMasterMetadataPartI(jab_bitmap matrix, jab_decoded_symbol symbol, Int8List data_map, int module_count, int x, int y) //ToDo module_count, x und y als Referenz/ Rückgabewert
{
	//decode Nc module color
	var module_color = Int8List(MASTER_METADATA_PART1_MODULE_NUMBER);
	int mtx_bytes_per_pixel = (matrix.bits_per_pixel / 8).toInt();
	int mtx_bytes_per_row = matrix.width * mtx_bytes_per_pixel;
	int mtx_offset;
	while(module_count < MASTER_METADATA_PART1_MODULE_NUMBER)
	{
		//decode bit out of the module at (x,y)
		mtx_offset = y * mtx_bytes_per_row + y * mtx_bytes_per_pixel;
		int rgb =  decodeModuleNc(matrix.pixel[mtx_offset]);
		if(rgb != 0 && rgb != 3 && rgb != 6)
		{
// #if TEST_MODE
// 		reportError("Invalid module color in primary metadata part 1 found");
// #endif
			return DECODE_METADATA_FAILED;
		}
		module_color[module_count] = rgb;
		//set data map
		data_map[y * matrix.width + x] = 1;
		//go to the next module
		module_count++;
		getNextMetadataModuleInMaster(matrix.height, matrix.width, module_count, x, y);
	}

	//decode encoded Nc
	var bits = List<int>.filled(2, null);
	bits[0] = decodeNcModuleColor(module_color[0] as Int8, module_color[1] as Int8);	//the first 3 bits
	bits[1] = decodeNcModuleColor(module_color[2] as Int8, module_color[3] as Int8);	//the last 3 bits
	if(bits[0] > 7 || bits[1] > 7)
	{
// #if TEST_MODE
// 		reportError("Invalid color combination in primary metadata part 1 found");
// #endif
		return DECODE_METADATA_FAILED;
	}
	//set bits in part1
	var part1 = Uint8List(MASTER_METADATA_PART1_LENGTH);			//6 encoded bits
	int bit_count = 0;
	for(int n=0; n<2; n++)
	{
		for(int i=0; i<3; i++)
		{
			int bit = (bits[n] >> (2 - i)) & 0x01;
			part1[bit_count] = bit;
			bit_count++;
		}
	}

	//decode ldpc for part1
	if( decodeLDPChd(part1, MASTER_METADATA_PART1_LENGTH, MASTER_METADATA_PART1_LENGTH > 36 ? 4 : 3, 0) == 0)
	{
// #if TEST_MODE
// 		reportError("LDPC decoding for master metadata part 1 failed");
// #endif
		return JAB_FAILURE;
	}
	//parse part1
	symbol.metadata.Nc = (part1[0] << 2) + (part1[1] << 1) + part1[2];

	return JAB_SUCCESS;
}

/**
 * @brief Decode the PartII of master symbol metadata
 * @param matrix the symbol matrix
 * @param symbol the master symbol
 * @param data_map the data module positions
 * @param norm_palette the normalized color palettes
 * @param pal_ths the palette RGB value thresholds
 * @param module_count the index number of the next module
 * @param x the x coordinate of the current and the next module
 * @param y the y coordinate of the current and the next module
 * @return JAB_SUCCESS | JAB_FAILURE | DECODE_METADATA_FAILED | FATAL_ERROR
*/
int decodeMasterMetadataPartII(jab_bitmap matrix, jab_decoded_symbol symbol, Int8List data_map, List<double> norm_palette, List<double> pal_ths, int module_count, int x, int y)
{
	var part2 = List<int>.filled(MASTER_METADATA_PART2_LENGTH, 0);			//38 encoded bits
	int part2_bit_count = 0;
	int V, E;
	int V_length = 10, E_length = 6;

	int color_number = pow(2, symbol.metadata.Nc + 1);
	int bits_per_module = (log(color_number) / log(2)).toInt();

    //read part2
    while(part2_bit_count < MASTER_METADATA_PART2_LENGTH)
    {
		//decode bits out of the module at (x,y)
		var bits = decodeModuleHD(matrix, symbol.palette, color_number, norm_palette, pal_ths, x, y);
		//write the bits into part2
		for(int i=0; i<bits_per_module; i++)
		{
			var bit = (bits >> (bits_per_module - 1 - i)) & 0x01;
			if(part2_bit_count < MASTER_METADATA_PART2_LENGTH)
			{
				part2[part2_bit_count] = bit;
				part2_bit_count++;
			}
			else	//if part2 is full, stop
			{
				break;
			}
		}
		//set data map
		data_map[y * matrix.width + (*x)] = 1;
		//go to the next module
		module_count++;
		getNextMetadataModuleInMaster(matrix.height, matrix.width, (*module_count), x, y);
    }

	//decode ldpc for part2
	if( !decodeLDPChd(part2, MASTER_METADATA_PART2_LENGTH, MASTER_METADATA_PART2_LENGTH > 36 ? 4 : 3, 0) )
	{
// #if TEST_MODE
// 		reportError("LDPC decoding for master metadata part 2 failed");
// #endif
		return DECODE_METADATA_FAILED;
	}

    //parse part2
	//read V
	//get horizontal side version
	V = 0;
	for(int i=0; i<V_length/2; i++)
	{
		V += part2[i] << (V_length/2 - 1 - i).toInt();
	}
	symbol.metadata.side_version.x = V + 1;
	//get vertical side version
	V = 0;
	for(int i=0; i<V_length/2; i++)
	{
		V += part2[(i+V_length/2).toInt()] << (V_length/2 - 1 - i).toInt();
	}
	symbol.metadata.side_version.y = V + 1;

	//read E
	int bit_index = V_length;
	//get wc (the first half of E)
	E = 0;
	for(int i=bit_index; i<(bit_index+E_length/2); i++)
	{
		E += part2[i] << (E_length/2 - 1 - (i - bit_index)).toInt();
	}
	symbol.metadata.ecl.x = E + 3;		//wc = E_part1 + 3
	//get wr (the second half of E)
	E = 0;
	for(int i=bit_index; i<(bit_index+E_length/2); i++)
	{
		E += part2[(i+E_length/2).toInt()] << (E_length/2 - 1 - (i - bit_index)).toInt();
	}
	symbol.metadata.ecl.y = E + 4;		//wr = E_part2 + 4

	//read MSK
	bit_index = V_length + E_length;
	symbol.metadata.mask_type = (part2[bit_index+0] << 2) + (part2[bit_index+1] << 1) + part2[bit_index+2];

	symbol.metadata.docked_position = 0;

	//check side version
	symbol.side_size.x = VERSION2SIZE(symbol.metadata.side_version.x);
	symbol.side_size.y = VERSION2SIZE(symbol.metadata.side_version.y);
	// if(matrix.width != symbol.side_size.x || matrix.height != symbol.side_size.y)
	// {
	// 	reportError("Primary symbol matrix size does not match the metadata");
	// 	return JAB_FAILURE;
	// }
	//check wc and wr
	int wc = symbol.metadata.ecl.x;
	int wr = symbol.metadata.ecl.y;
	// if(wc >= wr)
	// {
	// 	reportError("Incorrect error correction parameter in primary symbol metadata");
	// 	return DECODE_METADATA_FAILED;
	// }
	return JAB_SUCCESS;
}

/**
 * @brief Decode data modules
 * @param matrix the symbol matrix
 * @param symbol the symbol to be decoded
 * @param data_map the data module positions
 * @param norm_palette the normalized color palettes
 * @param pal_ths the palette RGB value thresholds
 * @return the decoded data | NULL if failed
*/
jab_data readRawModuleData(jab_bitmap matrix, jab_decoded_symbol symbol, Int8List data_map, List<double> norm_palette, List<double> pal_ths)
{
    int color_number = pow(2, symbol.metadata.Nc + 1);
	int module_count = 0;
    var data = jab_data() ;//(jab_data*)malloc(sizeof(jab_data) + matrix.width * matrix.height * sizeof(jab_char));
  //   if(data == null)
	// {
	// 	reportError("Memory allocation for raw module data failed");
	// 	return NULL;
	// }

// #if TEST_MODE
// 	Int8 decoded_module_color_index[matrix.height * matrix.width];
// #endif

	for(int j=0; j<matrix.width; j++)
	{
		for(int i=0; i<matrix.height; i++)
		{
			if(data_map[i*matrix.width + j] == 0)
			{
				//decode bits out of the module at (x,y)
				var bits = decodeModuleHD(matrix, symbol.palette, color_number, norm_palette, pal_ths, j, i);
				//write the bits into data
				data.data[module_count] = bits; //(jab_char)))
				module_count++;
// #if TEST_MODE
// 				decoded_module_color_index[i*matrix.width + j] = bits;
// #endif
			}
			else
			{
// #if TEST_MODE
// 				decoded_module_color_index[i*matrix.width + j] = 255;
// #endif
			}
		}
	}
	data.length = module_count;

// #if TEST_MODE
// 	FILE* fp1 = fopen("jab_dec_module_sampled_rgb.raw", "wb");
// 	FILE* fp2 = fopen("jab_dec_module_decoded_rgb.raw", "wb");
// 	for(int i=0; i<matrix.height; i++)
// 	{
// 		for(int j=0; j<matrix.width; j++)
// 		{
// 			Int8 rgb1[3], rgb2[3];
// 			int mtx_bytes_per_pixel = matrix.bits_per_pixel / 8;
// 			int mtx_bytes_per_row = matrix.width * mtx_bytes_per_pixel;
// 			int mtx_offset = i * mtx_bytes_per_row + j * mtx_bytes_per_pixel;
// 			rgb1[0] = matrix.pixel[mtx_offset + 0];
// 			rgb1[1] = matrix.pixel[mtx_offset + 1];
// 			rgb1[2] = matrix.pixel[mtx_offset + 2];
//
// 			if(data_map[i*matrix.width + j] == 0)
// 			{
// 				int index = decoded_module_color_index[i*matrix.width + j];
// 				rgb2[0] = jab_default_palette[index*3 + 0];
// 				rgb2[1] = jab_default_palette[index*3 + 1];
// 				rgb2[2] = jab_default_palette[index*3 + 2];
// 			}
// 			else
// 			{
// 				rgb2[0] = rgb1[0];
// 				rgb2[1] = rgb1[1];
// 				rgb2[2] = rgb1[2];
// 				//rgb1[0] = rgb2[0] = 128;
// 				//rgb1[1] = rgb2[1] = 128;
// 				//rgb1[2] = rgb2[2] = 128;
// 			}
// 			fwrite(rgb1, 3, 1, fp1);
// 			fwrite(rgb2, 3, 1, fp2);
// 		}
// 	}
// 	fclose(fp1);
// 	fclose(fp2);
// #endif // TEST_MODE

	return data;
}

/**
 * @brief Convert multi-bit-per-byte raw module data to one-bit-per-byte raw data
 * @param raw_module_data the input raw module data
 * @param bits_per_module the number of bits per module
 * @return the converted data | NULL if failed
*/
jab_data rawModuleData2RawData(jab_data raw_module_data, int bits_per_module)
{
	//
	var raw_data = jab_data(); //)(jab_data *)malloc(sizeof(jab_data) + raw_module_data.length * bits_per_module * sizeof(jab_char));
  //   if(raw_data == NULL)
	// {
	// 	reportError("Memory allocation for raw data failed");
	// 	return NULL;
	// }
	for(int i=0; i<raw_module_data.length; i++)
	{
		for(int j=0; j<bits_per_module; j++)
		{
			raw_data.data[i * bits_per_module + j] = (raw_module_data.data[i] >> (bits_per_module - 1 - j)) & 0x01;
		}
	}
	raw_data.length = raw_module_data.length * bits_per_module;
	return raw_data;
}

/**
 * @brief Mark the positions of finder patterns and alignment patterns in the data map
 * @param data_map the data module positions
 * @param width the width of the data map
 * @param height the height of the data map
 * @param type the symbol type, 0: master, 1: slave
*/
void fillDataMap(Int8List data_map, int width, int height, int type)
{
	int side_ver_x_index = SIZE2VERSION(width) - 1;
	int side_ver_y_index = SIZE2VERSION(height) - 1;
    int number_of_ap_x = jab_ap_num[side_ver_x_index];
    int number_of_ap_y = jab_ap_num[side_ver_y_index];
    for(int i=0; i<number_of_ap_y; i++)
    {
		for(int j=0; j<number_of_ap_x; j++)
		{
			//the center coordinate
			int x_offset = jab_ap_pos[side_ver_x_index][j] - 1;
            int y_offset = jab_ap_pos[side_ver_y_index][i] - 1;
			//the cross
			data_map[y_offset 	* width + x_offset]		  	= 1;
			data_map[y_offset		* width + (x_offset - 1)] = 1;
			data_map[y_offset		* width + (x_offset + 1)] = 1;
			data_map[(y_offset - 1) * width + x_offset] 	= 1;
			data_map[(y_offset + 1) * width + x_offset] 	= 1;

			//the diagonal modules
			if(i == 0 && (j == 0 || j == number_of_ap_x - 1))	//at finder pattern 0 and 1 positions
			{
				data_map[(y_offset - 1) * width + (x_offset - 1)] = 1;
				data_map[(y_offset + 1) * width + (x_offset + 1)] = 1;
				if(type == 0)	//master symbol
				{
					data_map[(y_offset - 2) * width + (x_offset - 2)] = 1;
					data_map[(y_offset - 2) * width + (x_offset - 1)] = 1;
					data_map[(y_offset - 2) * width +  x_offset] 	    = 1;
					data_map[(y_offset - 1) * width + (x_offset - 2)] = 1;
					data_map[ y_offset		  * width + (x_offset - 2)] = 1;

					data_map[(y_offset + 2) * width + (x_offset + 2)] = 1;
					data_map[(y_offset + 2) * width + (x_offset + 1)] = 1;
					data_map[(y_offset + 2) * width +  x_offset] 	    = 1;
					data_map[(y_offset + 1) * width + (x_offset + 2)] = 1;
					data_map[ y_offset		* width + (x_offset + 2)]   =  1;
				}
			}
			else if(i == number_of_ap_y - 1 && (j == 0 || j == number_of_ap_x - 1))	//at finder pattern 2 and 3 positions
			{
				data_map[(y_offset - 1) * width + (x_offset + 1)] = 1;
				data_map[(y_offset + 1) * width + (x_offset - 1)] =  1;
				if(type == 0) 	//master symbol
				{
					data_map[(y_offset - 2) * width + (x_offset + 2)] = 1;
					data_map[(y_offset - 2) * width + (x_offset + 1)] = 1;
					data_map[(y_offset - 2) * width +  x_offset] 	    = 1;
					data_map[(y_offset - 1) * width + (x_offset + 2)] = 1;
					data_map[ y_offset		* width + (x_offset + 2)]   =  1;

					data_map[(y_offset + 2) * width + (x_offset - 2)] = 1;
					data_map[(y_offset + 2) * width + (x_offset - 1)] = 1;
					data_map[(y_offset + 2) * width +  x_offset] 	    = 1;
					data_map[(y_offset + 1) * width + (x_offset - 2)] = 1;
					data_map[ y_offset		* width + (x_offset - 2)]   = 1;
				}
			}
			else	//at other positions
			{
				//even row, even column / odd row, odd column
				if( (i % 2 == 0 && j % 2 == 0) || (i % 2 == 1 && j % 2 == 1))
				{
					data_map[(y_offset - 1) * width + (x_offset - 1)] = 1;
					data_map[(y_offset + 1) * width + (x_offset + 1)] = 1;
				}
				//odd row, even column / even row, old column
				else
				{
					data_map[(y_offset - 1) * width + (x_offset + 1)] = 1 ;
					data_map[(y_offset + 1) * width + (x_offset - 1)] = 1;
				}
			}
		}
    }
}

/**
 * @brief Load default metadata values and color palettes for master symbol
 * @param matrix the symbol matrix
 * @param symbol the master symbol
*/
void loadDefaultMasterMetadata(jab_bitmap matrix, jab_decoded_symbol symbol)
{
// #if TEST_MODE
// 	JAB_REPORT_INFO(("Loading default master metadata"))
// #endif
	//set default metadata values
	symbol.metadata.default_mode = true;
	symbol.metadata.Nc = DEFAULT_MODULE_COLOR_MODE;
	symbol.metadata.ecl.x = ecclevel2wcwr[DEFAULT_ECC_LEVEL][0];
	symbol.metadata.ecl.y = ecclevel2wcwr[DEFAULT_ECC_LEVEL][1];
	symbol.metadata.mask_type = DEFAULT_MASKING_REFERENCE;
	symbol.metadata.docked_position = 0;							//no default value
	symbol.metadata.side_version.x = SIZE2VERSION(matrix.width);	//no default value
	symbol.metadata.side_version.y = SIZE2VERSION(matrix.height);	//no default value
}

/**
 * @brief Decode symbol
 * @param matrix the symbol matrix
 * @param symbol the symbol to be decoded
 * @param data_map the data module positions
 * @param norm_palette the normalized color palettes
 * @param pal_ths the palette RGB value thresholds
 * @param type the symbol type, 0: master, 1: slave
 * @return JAB_SUCCESS | JAB_FAILURE | DECODE_METADATA_FAILED | FATAL_ERROR
*/
int decodeSymbol(jab_bitmap matrix, jab_decoded_symbol symbol, Int8List data_map, List<double> norm_palette, List<double> pal_ths, int type)
{
// #if TEST_MODE
// 	int color_number = (int)pow(2, symbol.metadata.Nc + 1);
// 	printf("p1:\n");
// 	for(int i=0;i<color_number;i++)
// 	{
// 		printf("%d\t%d\t%d\n", symbol.palette[i*3], symbol.palette[i*3+1], symbol.palette[i*3+2]);
// 	}
// 	printf("p2:\n");
// 	for(int i=0;i<color_number;i++)
// 	{
// 		printf("%d\t%d\t%d\n", symbol.palette[3*color_number+i*3], symbol.palette[3*color_number+i*3+1], symbol.palette[3*color_number+i*3+2]);
// 	}
// 	printf("p3:\n");
// 	for(int i=0;i<color_number;i++)
// 	{
// 		printf("%d\t%d\t%d\n", symbol.palette[3*color_number*2+i*3], symbol.palette[3*color_number*2+i*3+1], symbol.palette[3*color_number*2+i*3+2]);
// 	}
// 	printf("p4:\n");
// 	for(int i=0;i<color_number;i++)
// 	{
// 		printf("%d\t%d\t%d\n", symbol.palette[3*color_number*3+i*3], symbol.palette[3*color_number*3+i*3+1], symbol.palette[3*color_number*3+i*3+2]);
// 	}
// #endif // TEST_MODE

	//fill data map
	fillDataMap(data_map, matrix.width, matrix.height, type);

	//read raw data
	var raw_module_data = readRawModuleData(matrix, symbol, data_map, norm_palette, pal_ths);
	if(raw_module_data == null)
	{
		// JAB_REPORT_ERROR(("Reading raw module data in symbol %d failed", symbol.index))
		// free(data_map);
		return FATAL_ERROR;
	}
// #if TEST_MODE
// 	FILE* fp = fopen("jab_dec_module_data.bin", "wb");
// 	fwrite(raw_module_data.data, raw_module_data.length, 1, fp);
// 	fclose(fp);
// #endif // TEST_MODE

	//demask
	demaskSymbol(raw_module_data, data_map, symbol.side_size, symbol.metadata.mask_type, pow(2, symbol.metadata.Nc + 1));
	// free(data_map);
// #if TEST_MODE
// 	fp = fopen("jab_demasked_module_data.bin", "wb");
// 	fwrite(raw_module_data.data, raw_module_data.length, 1, fp);
// 	fclose(fp);
// #endif // TEST_MODE

	//change to one-bit-per-byte representation
	var raw_data = rawModuleData2RawData(raw_module_data, symbol.metadata.Nc + 1);
	// free(raw_module_data);
	if(raw_data == null)
	{
		JAB_REPORT_ERROR(("Reading raw data in symbol %d failed", symbol.index))
		return FATAL_ERROR;
	}

	//calculate Pn and Pg
	int wc = symbol.metadata.ecl.x;
	int wr = symbol.metadata.ecl.y;
	int Pg = ((raw_data.length / wr) * wr).toInt();	//max_gross_payload = floor(capacity / wr) * wr
	int Pn = (Pg * (wr - wc) / wr).toInt();				//code_rate = 1 - wc/wr = (wr - wc)/wr, max_net_payload = max_gross_payload * code_rate

	//deinterleave data
	raw_data.length = Pg;	//drop the padding bits
    deinterleaveData(raw_data);

// #if TEST_MODE
// 	JAB_REPORT_INFO(("wc:%d, wr:%d, Pg:%d, Pn: %d", wc, wr, Pg, Pn))
// 	fp = fopen("jab_dec_bit_data.bin", "wb");
// 	fwrite(raw_data.data, raw_data.length, 1, fp);
// 	fclose(fp);
// #endif // TEST_MODE

	//decode ldpc
    if(decodeLDPChd(raw_data.data, Pg, symbol.metadata.ecl.x, symbol.metadata.ecl.y) != Pn)
    {
		// JAB_REPORT_ERROR(("LDPC decoding for data in symbol %d failed", symbol.index))
		// free(raw_data);
		return JAB_FAILURE;
	}

	//find the start flag of metadata
	int metadata_offset = Pn - 1;
	while(raw_data.data[metadata_offset] == 0)
	{
		metadata_offset--;
	}
	//skip the flag bit
	metadata_offset--;
	//set docked positions in host metadata
	symbol.metadata.docked_position = 0;
	for(int i=0; i<4; i++)
	{
		if(type == 1)	//if host is a slave symbol
		{
			if(i == symbol.host_position) continue; //skip host position
		}
		symbol.metadata.docked_position += raw_data.data[metadata_offset--] << (3 - i);
	}
	//decode metadata for docked slave symbols
	for(int i=0; i<4; i++)
	{
		if((symbol.metadata.docked_position & (0x08 >> i)) != 0)
		{
			int read_bit_length = decodeSlaveMetadata(symbol, i, raw_data, metadata_offset);
			if(read_bit_length == DECODE_METADATA_FAILED)
			{
				// free(raw_data);
				return DECODE_METADATA_FAILED;
			}
			metadata_offset -= read_bit_length;
		}
	}

	//copy the decoded data to symbol
	int net_data_length = metadata_offset + 1;
	symbol.data = jab_data(); // (jab_data *)malloc(sizeof(jab_data) + net_data_length * sizeof(jab_char));
	if(symbol.data == null)
	{
		// reportError("Memory allocation for symbol data failed");
		// free(raw_data);
		return FATAL_ERROR;
	}
	// symbol.data.length = net_data_length;
	// memcpy(symbol.data.data, raw_data.data, net_data_length);
	symbol.data.data.insertAll(0, raw_data.data);

	//clean memory
	// free(raw_data);
	return JAB_SUCCESS;
}

void normalizeColorPalette(jab_decoded_symbol symbol, List<double> norm_palette, int color_number)
{
	for(int i=0; i<(color_number * COLOR_PALETTE_NUMBER); i++)
	{
		double rgb_max = (max(symbol.palette[i*3 + 0], max(symbol.palette[i*3 + 1], symbol.palette[i*3 + 2]))).toDouble();
		norm_palette[i*4 + 0] = symbol.palette[i*3 + 0] / rgb_max;
		norm_palette[i*4 + 1] = symbol.palette[i*3 + 1] / rgb_max;
		norm_palette[i*4 + 2] = symbol.palette[i*3 + 2] / rgb_max;
		norm_palette[i*4 + 3] = ((symbol.palette[i*3 + 0] + symbol.palette[i*3 + 1] + symbol.palette[i*3 + 2]) / 3.0) / 255.0;
	}
}

/**
 * @brief Decode master symbol
 * @param matrix the symbol matrix
 * @param symbol the master symbol
 * @return JAB_SUCCESS | JAB_FAILURE | FATAL_ERROR
*/
int decodeMaster(jab_bitmap matrix, jab_decoded_symbol symbol)
{
	if(matrix == null)
	{
		// reportError("Invalid master symbol matrix");
		return FATAL_ERROR;
	}

	//create data map
	var data_map = Int8List(matrix.width*matrix.height);// (Int8*)calloc(1, matrix.width*matrix.height*sizeof(Int8));
	if(data_map == null)
	{
		// reportError("Memory allocation for data map in master failed");
		return FATAL_ERROR;
	}

	//decode metadata and color palette
	int x = MASTER_METADATA_X;
	int y = MASTER_METADATA_Y;
	int module_count = 0;

	//decode metadata PartI (Nc)
	int decode_partI_ret = decodeMasterMetadataPartI(matrix, symbol, data_map, module_count, x, y);
	if(decode_partI_ret == JAB_FAILURE)
	{
		return JAB_FAILURE;
	}
	if(decode_partI_ret == DECODE_METADATA_FAILED)
	{
		//reset variables
		x = MASTER_METADATA_X;
		y = MASTER_METADATA_Y;
		module_count = 0;
		//clear data_map
		data_map = Int8List(matrix.width*matrix.height); //memset(data_map, 0, matrix.width*matrix.height*sizeof(Int8));
		//load default metadata and color palette
		loadDefaultMasterMetadata(matrix, symbol);
	}

	//read color palettes
    if(readColorPaletteInMaster(matrix, symbol, data_map, module_count, x, y) < 0)
	{
		// reportError("Reading color palettes in master symbol failed");
		return JAB_FAILURE;
	}

	//normalize the RGB values in color palettes
	int color_number = pow(2, symbol.metadata.Nc + 1);
	var norm_palette = List<double>.filled(color_number * 4 * COLOR_PALETTE_NUMBER, 0);	//each color contains 4 normalized values, i.e. R, G, B and Luminance
	normalizeColorPalette(symbol, norm_palette, color_number);

	//get the palette RGB thresholds
	var pal_ths = List<double>.filled(3 * COLOR_PALETTE_NUMBER, 0);
	for(int i=0; i<COLOR_PALETTE_NUMBER; i++)
	{
		getPaletteThreshold(symbol.palette + (color_number*3)*i, color_number, pal_ths[i*3]);
	}

	//decode metadata PartII
	if(decode_partI_ret == JAB_SUCCESS)
	{
		if(decodeMasterMetadataPartII(matrix, symbol, data_map, norm_palette, pal_ths, module_count, x, y) <= 0) //ToDo &module_count, &x, &y
		{
			return JAB_FAILURE;
		}
	}

	//decode master symbol
	return decodeSymbol(matrix, symbol, data_map, norm_palette, pal_ths, 0);
}

/**
 * @brief Decode slave symbol
 * @param matrix the symbol matrix
 * @param symbol the slave symbol
 * @return JAB_SUCCESS | JAB_FAILURE | FATAL_ERROR
*/
int decodeSlave(jab_bitmap matrix, jab_decoded_symbol symbol)
{
	if(matrix == null)
	{
		// reportError("Invalid slave symbol matrix");
		return FATAL_ERROR;
	}

	//create data map
	var data_map = Int8List(matrix.width*matrix.height); // (Int8*)calloc(1, matrix.width*matrix.height*sizeof(Int8));
	if(data_map == null)
	{
		// reportError("Memory allocation for data map in slave failed");
		return FATAL_ERROR;
	}

	//read color palettes
	if(readColorPaletteInSlave(matrix, symbol, data_map) < 0)
	{
		// reportError("Reading color palettes in slave symbol failed");
		data_map = null; //free(data_map);
		return FATAL_ERROR;
	}

	//normalize the RGB values in color palettes
	int color_number = pow(2, symbol.metadata.Nc + 1);
	var norm_palette = List<double>.filled(color_number * 4 * COLOR_PALETTE_NUMBER, 0);	//each color contains 4 normalized values, i.e. R, G, B and Luminance
	normalizeColorPalette(symbol, norm_palette, color_number);

	//get the palette RGB thresholds
	var pal_ths = List<double>.filled(3 * COLOR_PALETTE_NUMBER, 0);
	for(int i=0; i<COLOR_PALETTE_NUMBER; i++)
	{
		getPaletteThreshold(symbol.palette + i*3, color_number, pal_ths[i*3]); //&pal_ths[i*3]
	}

	//decode slave symbol
	return decodeSymbol(matrix, symbol, data_map, norm_palette, pal_ths, 1);
}

/**
 * @brief Read bit data
 * @param data the data buffer
 * @param start the start reading offset
 * @param length the length of the data to be read
 * @param value the read data
 * @return the length of the read data
*/
Tuple2<int,int> readData(jab_data data, int start, int length) //int* value
{
	int i;
	int val = 0;
	for(i=start; i<(start + length) && i<data.length; i++)
	{
		val += data.data[i] << (length - 1 - (i - start));
	}
	// value = val;
	return Tuple2<int,int>((i - start), val);
}

/**
 * @brief Interpret decoded bits
 * @param bits the input bits
 * @return the data message
*/
jab_data decodeData(jab_data bits)
{
	var decoded_bytes = Int8List(bits.length); //Int8 *)malloc(bits.length * sizeof(Int8));
	// if(decoded_bytes == NULL)
	// {
	// 	reportError("Memory allocation for decoded bytes failed");
	// 	return NULL;
	// }

	var mode = jab_encode_mode.Upper;
	var pre_mode = jab_encode_mode.None;
	int index = 0;	//index of input bits
	int count = 0;	//index of decoded bytes

	while(index < bits.length)
	{
		//read the encoded value
		bool flag = false;
		int value = 0;
        int n;
        if(mode != jab_encode_mode.Byte)
        {
						var result = readData(bits, index, character_size[mode]);
						n = result.item1;
						value = result.item2;
						if(n < character_size[mode])	//did not read enough bits
                break;
            //update index
            index += character_size[mode];
        }

		//decode value
		switch(mode)
		{
			case jab_encode_mode.Upper:
				if(value <= 26)
				{
					decoded_bytes[count++] = jab_decoding_table_upper[value];
					if(pre_mode != jab_encode_mode.None)
						mode = pre_mode;
				}
				else
				{
					switch(value as int)
					{
						case 27:
							mode = jab_encode_mode.Punct;
							pre_mode = jab_encode_mode.Upper;
							break;
						case 28:
							mode = jab_encode_mode.Lower;
							pre_mode = jab_encode_mode.None;
							break;
						case 29:
							mode = jab_encode_mode.Numeric;
							pre_mode = jab_encode_mode.None;
							break;
						case 30:
							mode = jab_encode_mode.Alphanumeric;
							pre_mode = jab_encode_mode.None;
							break;
						case 31:
							//read 2 bits more
							var result = readData(bits, index, 2);
							n = result.item1;
							value = result.item2;
							if(n < 2)	//did not read enough bits
							{
								flag = true;
								break;
							}
							//update index
							index += 2;
							switch(value)
							{
								case 0:
									mode = jab_encode_mode.Byte;
									pre_mode = jab_encode_mode.Upper;
									break;
								case 1:
									mode = jab_encode_mode.Mixed;
									pre_mode = jab_encode_mode.Upper;
									break;
								case 2:
									mode = jab_encode_mode.ECI;
									pre_mode = jab_encode_mode.None;
									break;
								case 3:
									flag = true;		//end of message (EOM)
									break;
							}
							break;
						default:
							// reportError("Invalid value decoded");
							decoded_bytes = null ;//free(decoded_bytes);
							return null;
					}
				}
				break;
			case jab_encode_mode.Lower:
				if(value <= 26)
				{
					decoded_bytes[count++] = jab_decoding_table_lower[value];
					if(pre_mode != jab_encode_mode.None)
						mode = pre_mode;
				}
				else
				{
					switch(value)
					{
						case 27:
							mode = jab_encode_mode.Punct;
							pre_mode = jab_encode_mode.Lower;
							break;
						case 28:
							mode = jab_encode_mode.Upper;
							pre_mode = jab_encode_mode.Lower;
							break;
						case 29:
							mode = jab_encode_mode.Numeric;
							pre_mode = jab_encode_mode.None;
							break;
						case 30:
							mode = jab_encode_mode.Alphanumeric;
							pre_mode = jab_encode_mode.None;
							break;
						case 31:
							//read 2 bits more
							var result = readData(bits, index, 2);
							n = result.item1;
							value = result.item2;
							if(n < 2)	//did not read enough bits
							{
								flag = true;
								break;
							}
							//update index
							index += 2;
							switch(value)
							{
								case 0:
									mode = jab_encode_mode.Byte;
									pre_mode = jab_encode_mode.Lower;
									break;
								case 1:
									mode = jab_encode_mode.Mixed;
									pre_mode = jab_encode_mode.Lower;
									break;
								case 2:
									mode = jab_encode_mode.Upper;
									pre_mode = jab_encode_mode.None;
									break;
								case 3:
									mode = jab_encode_mode.FNC1;
									pre_mode = jab_encode_mode.None;
									break;
							}
							break;
						default:
							// reportError("Invalid value decoded");
							decoded_bytes = null ; //free(decoded_bytes);
							return null;
					}
				}
				break;
			case jab_encode_mode.Numeric:
				if(value <= 12)
				{
					decoded_bytes[count++] = jab_decoding_table_numeric[value];
					if(pre_mode != jab_encode_mode.None)
						mode = pre_mode;
				}
				else
				{
					switch(value)
					{
						case 13:
							mode = jab_encode_mode.Punct;
							pre_mode = jab_encode_mode.Numeric;
							break;
						case 14:
							mode = jab_encode_mode.Upper;
							pre_mode = jab_encode_mode.None;
							break;
						case 15:
							//read 2 bits more
							var result = readData(bits, index, 2);
							n = result.item1;
							value = result.item2;
							if(n < 2)	//did not read enough bits
							{
								flag = true;
								break;
							}
							//update index
							index += 2;
							switch(value)
							{
								case 0:
									mode = jab_encode_mode.Byte;
									pre_mode = jab_encode_mode.Numeric;
									break;
								case 1:
									mode = jab_encode_mode.Mixed;
									pre_mode = jab_encode_mode.Numeric;
									break;
								case 2:
									mode = jab_encode_mode.Upper;
									pre_mode = jab_encode_mode.Numeric;
									break;
								case 3:
									mode = jab_encode_mode.Lower;
									pre_mode = jab_encode_mode.None;
									break;
							}
							break;
						default:
						// reportError("Invalid value decoded");
							decoded_bytes = null ; //free(decoded_bytes);
							return null;
					}
				}
				break;
			case jab_encode_mode.Punct:
				if(value >=0 && value <= 15)
				{
					decoded_bytes[count++] = jab_decoding_table_punct[value];
					mode = pre_mode;
				}
				else
				{
					// reportError("Invalid value decoded");
					decoded_bytes = null ; //free(decoded_bytes);
					return null;
				}
				break;
			case jab_encode_mode.Mixed:
				if(value >=0 && value <= 31)
				{
					if(value == 19)
					{
						decoded_bytes[count++] = 10;
						decoded_bytes[count++] = 13;
					}
					else if(value == 20)
					{
						decoded_bytes[count++] = 44;
						decoded_bytes[count++] = 32;
					}
					else if(value == 21)
					{
						decoded_bytes[count++] = 46;
						decoded_bytes[count++] = 32;
					}
					else if(value == 22)
					{
						decoded_bytes[count++] = 58;
						decoded_bytes[count++] = 32;
					}
					else
					{
						decoded_bytes[count++] = jab_decoding_table_mixed[value];
					}
					mode = pre_mode;
				}
				else
				{
					// reportError("Invalid value decoded");
					decoded_bytes = null ; //free(decoded_bytes);
					return null;
				}
				break;
			case jab_encode_mode.Alphanumeric:
				if(value <= 62)
				{
					decoded_bytes[count++] = jab_decoding_table_alphanumeric[value];
					if(pre_mode != jab_encode_mode.None)
						mode = pre_mode;
				}
				else if(value == 63)
				{
					//read 2 bits more
					var result = readData(bits, index, 2);
					n = result.item1;
					value = result.item2;
					if(n < 2)	//did not read enough bits
					{
						flag = true;
						break;
					}
					//update index
					index += 2;
					switch(value)
					{
						case 0:
							mode = jab_encode_mode.Byte;
							pre_mode = jab_encode_mode.Alphanumeric;
							break;
						case 1:
							mode = jab_encode_mode.Mixed;
							pre_mode = jab_encode_mode.Alphanumeric;
							break;
						case 2:
							mode = jab_encode_mode.Punct;
							pre_mode = jab_encode_mode.Alphanumeric;
							break;
						case 3:
							mode = jab_encode_mode.Upper;
							pre_mode = jab_encode_mode.None;
							break;
					}
				}
				else
				{
					// reportError("Invalid value decoded");
					decoded_bytes = null; // free(decoded_bytes);
					return null;
				}
				break;
			case jab_encode_mode.Byte:
			{
				//read 4 bits more
				var result = readData(bits, index, 4);
				n = result.item1;
				value = result.item2;
				if(n < 4)	//did not read enough bits
				{
          // reportError("Not enough bits to decode");
					decoded_bytes = null; // free(decoded_bytes);
					return null;
				}
				//update index
				index += 4;
				if(value == 0)		//read the next 13 bits
				{
					//read 13 bits more
					var result = readData(bits, index, 13);
					n = result.item1;
					value = result.item2;
					if(n < 13)	//did not read enough bits
					{
						// reportError("Not enough bits to decode");
						decoded_bytes = null; // free(decoded_bytes);
						return null;
					}
                    value += 15+1;	//the number of encoded bytes = value + 15
					//update index
					index += 13;
				}
				int byte_length = value;
				//read the next (byte_length * 8) bits
				for(int i=0; i<byte_length; i++)
				{
					var result = readData(bits, index, 8);
					n = result.item1;
					value = result.item2;
					if(n < 8)	//did not read enough bits
					{
            // reportError("Not enough bits to decode");
						decoded_bytes = null; // free(decoded_bytes);
						return null;
					}
					//update index
					index += 8;
					decoded_bytes[count++] = value;
				}
				mode = pre_mode;
				break;
			}
			case jab_encode_mode.ECI:
				//TODO: not implemented
				index += bits.length;
				break;
			case jab_encode_mode.FNC1:
				//TODO: not implemented
				index += bits.length;
				break;
			case jab_encode_mode.None:
				// reportError("Decoding mode is None.");
				index += bits.length;
				break;
		}
		if(flag) break;
	}

	//copy decoded data
	var decoded_data = jab_data(); //(jab_data *)malloc(sizeof(jab_data) + count * sizeof(Int8));
	// if(decoded_data == null){
  //       reportError("Memory allocation for decoded data failed");
  //       return null;
  //   }
  //   decoded_data.length = count;
  //   memcpy(decoded_data.data, decoded_bytes, count);
	//
	// free(decoded_bytes);
decoded_data.data = decoded_bytes;
	return decoded_data;
}
