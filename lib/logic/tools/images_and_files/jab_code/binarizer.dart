import 'dart:core';
import 'dart:ffi';
import 'dart:math';
import 'dart:typed_data';

import 'package:tuple/tuple.dart';

import 'jabcode_h.dart';

/**
 * libjabcode - JABCode Encoding/Decoding Library
 *
 * Copyright 2016 by Fraunhofer SIT. All rights reserved.
 * See LICENSE file for full terms of use and distribution.
 *
 * Contact: Huajian Liu <liu@sit.fraunhofer.de>
 *			Waldemar Berchtold <waldemar.berchtold@sit.fraunhofer.de>
 *
 * @file binarizer.c
 * @brief Binarize the image
 */

// #include <stdlib.h>
// #include <stdio.h>
// #include <string.h>
// #include "jabcode.h"
// #include <math.h>

const BLOCK_SIZE_POWER = 5;
const BLOCK_SIZE =			(1 << BLOCK_SIZE_POWER);
const BLOCK_SIZE_MASK =	(BLOCK_SIZE - 1);
const MINIMUM_DIMENSION = 	(BLOCK_SIZE * 5);
int CAP(int val,int min,int max)	{return (val < min ? min : (val > max ? max : val));}

// /**
//  * @brief Check bimodal/trimodal distribution
//  * @param hist the histogram
//  * @param channel the color channel
//  * @return JAB_SUCCESS | JAB_FAILURE
// */
// jab_boolean isBiTrimodal(double hist[], int channel)
// {
// 	int modal_number;
// 	if(channel == 1)
// 		modal_number = 3;
// 	else
// 		modal_number = 2;
//
//     int count = 0;
//     for(int i=1; i<255; i++)
//     {
//         if(hist[i-1]<hist[i] && hist[i+1]<hist[i])
//         {
//             count++;
//             if(count > modal_number) return JAB_FAILURE;
//         }
//     }
//     if (count == modal_number)
//         return JAB_SUCCESS;
//     else
//         return JAB_FAILURE;
// }

// /**
//  * @brief Get the minimal value in a histogram with bimodal distribution
//  * @param hist the histogram
//  * @param channel the color channel
//  * @return minimum threshold | -1 if failed
// */
// int getMinimumThreshold(int hist[], int channel)
// {
//     double hist_c[256], hist_s[256];
//     for (int i=0; i<256; i++)
//     {
//         hist_c[i] = (double)hist[i];
//         hist_s[i] = (double)hist[i];
//     }
//
//     //smooth histogram
//     int iter = 0;
//     while(!isBiTrimodal(hist_s, channel))
//     {
//         hist_s[0] = (hist_c[0] + hist_c[0] + hist_c[1]) / 3;
//         for (int i=1; i<255; i++)
//             hist_s[i] = (hist_c[i - 1] + hist_c[i] + hist_c[i + 1]) / 3;
//         hist_s[255] = (hist_c[254] + hist_c[255] + hist_c[255]) / 3;
//         memcpy(hist_c, hist_s, 256*sizeof(double));
//         iter++;
//         if (iter >= 1000) return -1;
//     }
//
//     //get the minimum between two peaks as threshold
//     int peak_number;
//     if(channel == 1)
// 		peak_number = 2;
// 	else
// 		peak_number = 1;
//
//     jab_boolean peak_found = 0;
// 	for (int i=1; i<255; i++)
// 	{
// 		if (hist_s[i-1]<hist_s[i] && hist_s[i+1]<hist_s[i]) peak_found++;
// 		if (peak_found==peak_number && hist_s[i-1]>=hist_s[i] && hist_s[i+1]>=hist_s[i])
// 			return i-1;
// 	}
//     return -1;
// }

// /**
//  * @brief Binarize a color channel of a bitmap using histogram binarization algorithm
//  * @param bitmap the input bitmap
//  * @param channel the color channel
//  * @return binarized bitmap | NULL if failed
// */
// jab_bitmap* binarizerHist(jab_bitmap* bitmap, int channel)
// {
// 	jab_bitmap* binary = (jab_bitmap*)malloc(sizeof(jab_bitmap) + bitmap.width*bitmap.height*sizeof(jab_byte));
// 	if(binary == NULL)
// 	{
// 		reportError("Memory allocation for binary bitmap failed");
// 		return NULL;
// 	}
// 	binary.width = bitmap.width;
// 	binary.height= bitmap.height;
// 	binary.bits_per_channel = 8;
// 	binary.bits_per_pixel = 8;
// 	binary.channel_count = 1;
// 	int bytes_per_pixel = bitmap.bits_per_pixel / 8;
//
// 	//get histogram
// 	int hist[256];
// 	memset(hist, 0, 256*sizeof(int));
// 	for(int i=0; i<bitmap.width*bitmap.height; i++)
// 	{
// 		if(channel>0)
// 		{
// 			jab_byte r, g, b;
// 			r = bitmap.pixel[i*bytes_per_pixel];
// 			g = bitmap.pixel[i*bytes_per_pixel + 1];
// 			b = bitmap.pixel[i*bytes_per_pixel + 2];
//
// 			float mean = (float)(r + g + b)/(float)3.0;
// 			float pr = (float)r/mean;
// 			float pg = (float)g/mean;
// 			float pb = (float)b/mean;
//
// 			//green channel
// 			if(channel == 1)
// 			{
// 				//skip white, black, yellow
// 				if( (r>200 && g>200 && b>200) || (r<50 && g<50 && b<50) || (r>200 && g>200))
// 					continue;
// 				//skip white and black: r, g, b values are very close
// 				if( (pr<1.25 && pr>0.8) && (pg<1.25 && pg>0.8) && (pb<1.25 && pb>0.8) )
// 					continue;
// 				//skip yellow: blue is small, red and green are very close
// 				if( pb<0.5 && (pr/pg<1.25 && pr/pg>0.8) )
// 					continue;
// 			}
// 			//blue channel
// 			else if(channel == 2)
// 			{
// 				//skip white,black
// 				if( (r>200 && g>200 && b>200) || (r<50 && g<50 && b<50) )
// 					continue;
// 				//skip white and black: r, g, b values are very close
// 				if( (pr<1.25 && pr>0.8) && (pg<1.25 && pg>0.8) && (pb<1.25 && pb>0.8) )
// 					continue;
// 			}
// 		}
// 		hist[bitmap.pixel[i*bytes_per_pixel + channel]]++;
// 	}
//
// 	//get threshold
// 	int ths = getMinimumThreshold(hist, channel);
//
// 	//binarize bitmap
// 	for(int i=0; i<bitmap.width*bitmap.height; i++)
// 	{
// 		binary.pixel[i] = bitmap.pixel[i*bytes_per_pixel + channel] > ths ? 255 : 0;
// 	}
//
// 	return binary;
// }

// /**
//  * @brief Binarize a color channel of a bitmap using a given threshold
//  * @param bitmap the input bitmap
//  * @param channel the color channel
//  * @param threshold the threshold
//  * @return binarized bitmap | NULL if failed
// */
// jab_bitmap* binarizerHard(jab_bitmap* bitmap, int channel, int threshold)
// {
// 	jab_bitmap* binary = (jab_bitmap*)malloc(sizeof(jab_bitmap) + bitmap.width*bitmap.height*sizeof(jab_byte));
// 	if(binary == NULL)
// 	{
// 		reportError("Memory allocation for binary bitmap failed");
// 		return NULL;
// 	}
// 	binary.width = bitmap.width;
// 	binary.height= bitmap.height;
// 	binary.bits_per_channel = 8;
// 	binary.bits_per_pixel = 8;
// 	binary.channel_count = 1;
// 	int bytes_per_pixel = bitmap.bits_per_pixel / 8;
// 	//binarize bitmap
// 	for(int i=0; i<bitmap.width*bitmap.height; i++)
// 	{
// 		binary.pixel[i] = bitmap.pixel[i*bytes_per_pixel + channel] > threshold ? 255 : 0;
// 	}
// 	return binary;
// }

// /**
//  * @brief Do local binarization based on the black points
//  * @param bitmap the input bitmap
//  * @param channel the color channel
//  * @param sub_width the number of blocks in x direction
//  * @param sub_height the number of blocks in y direction
//  * @param black_points the black points
//  * @param binary the binarized bitmap
// */
// void getBinaryBitmap(jab_bitmap* bitmap, int channel, int sub_width, int sub_height, jab_byte* black_points, jab_bitmap* binary)
// {
//     int bytes_per_pixel = bitmap.bits_per_pixel / 8;
//     int bytes_per_row = bitmap.width * bytes_per_pixel;
//
//     for (int y=0; y<sub_height; y++)
//     {
//         int yoffset = y << BLOCK_SIZE_POWER;
//         int max_yoffset = bitmap.height - BLOCK_SIZE;
//         if (yoffset > max_yoffset)
//         {
//             yoffset = max_yoffset;
//         }
//         for (int x=0; x<sub_width; x++)
//         {
//             int xoffset = x << BLOCK_SIZE_POWER;
//             int max_xoffset = bitmap.width - BLOCK_SIZE;
//             if (xoffset > max_xoffset)
//             {
//                 xoffset = max_xoffset;
//             }
//             int left = CAP(x, 2, sub_width - 3);
//             int top = CAP(y, 2, sub_height - 3);
//             int sum = 0;
//             for (int z = -2; z <= 2; z++)
//             {
//                 jab_byte* black_row = &black_points[(top + z) * sub_width];
//                 sum += black_row[left - 2] + black_row[left - 1] + black_row[left] + black_row[left + 1] + black_row[left + 2];
//             }
//             int average = sum / 25;
//
//             //threshold block
//             for (int yy = 0; yy < BLOCK_SIZE; yy++)
//             {
//                 for (int xx = 0; xx < BLOCK_SIZE; xx++)
//                 {
//                     int offset = (yoffset + yy) * bytes_per_row + (xoffset + xx) * bytes_per_pixel;
//                     if (bitmap.pixel[offset + channel] > average)
//                     {
//                         binary.pixel[(yoffset + yy) * binary.width + (xoffset + xx)] = 255;
//                     }
//                 }
//             }
//         }
//     }
// }

// /**
//  * @brief Calculate the black point of each block
//  * @param bitmap the input bitmap
//  * @param channel the color channel
//  * @param sub_width the number of blocks in x direction
//  * @param sub_height the number of blocks in y direction
//  * @param black_points the black points
// */
// void calculateBlackPoints(jab_bitmap* bitmap, int channel, int sub_width, int sub_height, jab_byte* black_points)
// {
//     int min_dynamic_range = 24;
//
//     int bytes_per_pixel = bitmap.bits_per_pixel / 8;
//     int bytes_per_row = bitmap.width * bytes_per_pixel;
//
//     for(int y=0; y<sub_height; y++)
//     {
//         int yoffset = y << BLOCK_SIZE_POWER;
//         int max_yoffset = bitmap.height - BLOCK_SIZE;
//         if (yoffset > max_yoffset)
//         {
//             yoffset = max_yoffset;
//         }
//         for (int x=0; x<sub_width; x++)
//         {
//             int xoffset = x << BLOCK_SIZE_POWER;
//             int max_xoffset = bitmap.width - BLOCK_SIZE;
//             if (xoffset > max_xoffset)
//             {
//                 xoffset = max_xoffset;
//             }
//             int sum = 0;
//             int min = 0xFF;
//             int max = 0;
//             for (int yy=0; yy<BLOCK_SIZE; yy++)
//             {
//                 for (int xx=0; xx<BLOCK_SIZE; xx++)
//                 {
//                     int offset = (yoffset + yy) * bytes_per_row + (xoffset + xx) * bytes_per_pixel;
//                     jab_byte pixel = bitmap.pixel[offset + channel];
//                     sum += pixel;
//                     //check contrast
//                     if (pixel < min)
//                     {
//                         min = pixel;
//                     }
//                     if (pixel > max)
//                     {
//                         max = pixel;
//                     }
//                 }
//                 //bypass contrast check once the dynamic range is met
//                 if (max-min > min_dynamic_range)
//                 {
//                     //finish the rest of the rows quickly
//                     for (yy++; yy < BLOCK_SIZE; yy++)
//                     {
//                         for (int xx = 0; xx < BLOCK_SIZE; xx++)
//                         {
//                             int offset = (yoffset + yy) * bytes_per_row + (xoffset + xx) * bytes_per_pixel;
//                             sum += bitmap.pixel[offset + channel];
//                         }
//                     }
//                 }
//             }
//
//             int average = sum >> (BLOCK_SIZE_POWER * 2);
//             if (max-min <= min_dynamic_range)	//smooth block
//             {
//                 average = min / 2;
//                 if (y > 0 && x > 0)
//                 {
//                     int average_neighbor_blackpoint = (black_points[(y-1) * sub_width + x] +
//                                                             (2 * black_points[y * sub_width + x-1]) +
//                                                             black_points[(y-1) * sub_width + x-1]) / 4;
//                     if (min < average_neighbor_blackpoint)
//                     {
//                         average = average_neighbor_blackpoint;
//                     }
//                 }
//             }
//             black_points[y*sub_width + x] = (jab_byte)average;
//         }
//     }
// }

/**
 * @brief Filter out noises in binary bitmap
 * @param binary the binarized bitmap
*/
void _filterBinary(jab_bitmap binary)
{
	int width = binary.width;
	int height= binary.height;

	int filter_size = 5;
	int half_size = ((filter_size - 1)/2).toInt();

	// var tmp = jab_bitmap(); //(jab_bitmap*)malloc(sizeof(jab_bitmap) + width*height*sizeof(jab_byte));
	// tmp.pixel = Uint32List(width*height);
	// if(tmp == null)
	// {
	// 	// reportError("Memory allocation for temporary binary bitmap failed");
	// 	return;
	// }

	//horizontal filtering
	var tmp = binary.clone(); // memcpy(tmp, binary, sizeof(jab_bitmap) + width*height*sizeof(jab_byte));
	for(int i=half_size; i<height-half_size; i++)
	{
		for(int j=half_size; j<width-half_size; j++)
		{
			int sum = 0;
			sum += tmp.pixel[i*width + j] > 0 ? 1 : 0;
			for(int k=1; k<=half_size; k++)
			{
				sum += tmp.pixel[i*width + (j - k)] > 0 ? 1 : 0;
				sum += tmp.pixel[i*width + (j + k)] > 0 ? 1 : 0;
			}
			binary.pixel[i*width + j] = sum > half_size ? 255 : 0;
		}
	}
	//vertical filtering
	tmp = binary.clone(); //memcpy(tmp, binary, sizeof(jab_bitmap) + width*height*sizeof(jab_byte));
	for(int i=half_size; i<height-half_size; i++)
	{
		for(int j=half_size; j<width-half_size; j++)
		{
			int sum = 0;
			sum += tmp.pixel[i*width + j] > 0 ? 1 : 0;
			for(int k=1; k<=half_size; k++)
			{
				sum += tmp.pixel[(i - k)*width + j] > 0 ? 1 : 0;
				sum += tmp.pixel[(i + k)*width + j] > 0 ? 1 : 0;
			}
			binary.pixel[i*width + j] = sum > half_size ? 255 : 0;
		}
	}
	// free(tmp);
}
//
// /**
//  * @brief Binarize a color channel of a bitmap using local binarization algorithm
//  * @param bitmap the input bitmap
//  * @param channel the color channel
//  * @return binarized bitmap | NULL if failed
// */
// jab_bitmap* binarizer(jab_bitmap* bitmap, int channel)
// {
// 	if(bitmap.width >= MINIMUM_DIMENSION && bitmap.height >= MINIMUM_DIMENSION)
// 	{
// 		int sub_width = bitmap.width >> BLOCK_SIZE_POWER;
// 		if((sub_width & BLOCK_SIZE_MASK) != 0 )	sub_width++;
// 		int sub_height= bitmap.height>> BLOCK_SIZE_POWER;
// 		if((sub_height & BLOCK_SIZE_MASK) != 0 )	sub_height++;
//
// 		jab_byte* black_points = (jab_byte*)malloc(sub_width * sub_height * sizeof(jab_byte));
// 		if(black_points == NULL)
// 		{
// 			reportError("Memory allocation for black points failed");
// 			return NULL;
// 		}
// 		calculateBlackPoints(bitmap, channel, sub_width, sub_height, black_points);
//
// 		jab_bitmap* binary = (jab_bitmap*)calloc(1, sizeof(jab_bitmap) + bitmap.width*bitmap.height*sizeof(jab_byte));
// 		if(binary == NULL)
// 		{
// 			reportError("Memory allocation for binary bitmap failed");
// 			return NULL;
// 		}
// 		binary.width = bitmap.width;
// 		binary.height= bitmap.height;
// 		binary.bits_per_channel = 8;
// 		binary.bits_per_pixel = 8;
// 		binary.channel_count = 1;
// 		getBinaryBitmap(bitmap, channel, sub_width, sub_height, black_points, binary);
//
// 		filterBinary(binary);
//
// 		free(black_points);
// 		return binary;
// 	}
// 	else
// 	{
// 		//if the bitmap is too small, use the global histogram-based method
// 		return binarizerHist(bitmap, channel);
// 	}
// }

/**
 * @brief Get the histogram of a color channel
 * @param bitmap the image
 * @param channel the channel
 * @param hist the histogram
*/
void _getHistogram(jab_bitmap bitmap, int channel, List<int> hist)
{
	//get histogram
	// memset(hist, 0, 256*sizeof(int));
	int bytes_per_pixel = (bitmap.bits_per_pixel / 8).toInt();
	for(int i=0; i<bitmap.width*bitmap.height; i++)
	{
		hist[bitmap.pixel[i*bytes_per_pixel + channel]]++;
	}
}

/**
 * @brief Get the min and max index in the histogram whose value is larger than the threshold
 * @param hist the histogram
 * @param ths the threshold
 * @result item1 the min index
 * @result item2 the max index
*/
Tuple2<int, int> _getHistMaxMin(List<int> hist, int ths)
{
	//get min
	var min = 0;
	for(int i=0; i<256; i++)
	{
		if(hist[i] > ths)
		{
			min = i;
			break;
		}
	}
	//get max
	var max = 255;
	for(int i=255; i>=0; i--)
	{
		if(hist[i] > ths)
		{
			max = i;
			break;
		}
	}
	return Tuple2<int, int>(min, max);
}

/**
 * @brief Stretch the histograms of R, G and B channels
 * @param bitmap the image
*/
void balanceRGB(jab_bitmap bitmap)
{
	int bytes_per_pixel = (bitmap.bits_per_pixel / 8).toInt();
    int bytes_per_row = bitmap.width * bytes_per_pixel;

	// int max_r, max_g, max_b;
	//   int min_r, min_g, min_b;
    var hist_r = List<int>.filled(256, 0);
	var hist_g = List<int>.filled(256, 0);
	var hist_b = List<int>.filled(256, 0);

    _getHistogram(bitmap, 0, hist_r);
    _getHistogram(bitmap, 1, hist_g);
    _getHistogram(bitmap, 2, hist_b);

	//calculate max and min for each channel
    //threshold for the number of pixels having the max or min values
	int count_ths = 20;
	var r = _getHistMaxMin(hist_r, count_ths);
	var g = _getHistMaxMin(hist_g, count_ths);
	var b = _getHistMaxMin(hist_b, count_ths);

	//normalize each channel
	for(int i=0; i<bitmap.height; i++)
	{
		for(int j=0; j<bitmap.width; j++)
		{
			int offset = i * bytes_per_row + j * bytes_per_pixel;
			//R channel
			if		(bitmap.pixel[offset + 0] < r.item1)	bitmap.pixel[offset + 0] = 0;
			else if (bitmap.pixel[offset + 0] > r.item2)	bitmap.pixel[offset + 0] = 255;
			else 	 bitmap.pixel[offset + 0] = ((bitmap.pixel[offset + 0] - r.item1) / (r.item2 - r.item1) * 255.0).toInt();
			//G channel
			if		(bitmap.pixel[offset + 1] < g.item1)	bitmap.pixel[offset + 1] = 0;
			else if (bitmap.pixel[offset + 1] > g.item2)	bitmap.pixel[offset + 1] = 255;
			else 	 bitmap.pixel[offset + 1] = ((bitmap.pixel[offset + 1] - g.item1) / (g.item2 - g.item1) * 255.0).toInt();
			//B channel
			if		(bitmap.pixel[offset + 2] < b.item1) bitmap.pixel[offset + 2] = 0;
			else if	(bitmap.pixel[offset + 2] > b.item2)	bitmap.pixel[offset + 2] = 255;
			else 	 bitmap.pixel[offset + 2] = ((bitmap.pixel[offset + 2] - b.item1) / (b.item2 - b.item1) * 255.0).toInt();
		}
	}
}

/**
 * @brief Get the average and variance of RGB values
 * @param rgb the pixel with RGB values
 * @result item1 the average value
 * @result item2 the variance value
 */
Tuple2<double, double> getAveVar(Uint8List rgb)
{
	//calculate mean
	var ave = (rgb[0] + rgb[1] + rgb[2]) / 3;
	//calculate variance
	var sum = 0.0;
	for(var i=0; i<3; i++)
	{
		sum += (rgb[i] - ave) * (rgb[i] - ave);
	}
	return Tuple2<double, double>(ave, sum / 3);
}

/**
 * @brief Swap two variables
*/
void _swap(int a, int b, List<int> list)
{
	int tmp;
	tmp = list[a];
	list[a] = list[b];
	list[b] = tmp;
}

/**
 * @brief Get the min, middle and max value of three values and the corresponding indexes
 * @param rgb the pixel with RGB values
 * @result item1 index min value
 * @result item2 index middle value
 * @result item3 index max value
 */
Tuple3<int, int, int> getMinMax(Uint8List rgb)
{
	const index_min = 0;
	const index_mid = 1;
	const index_max = 2;
	var index = [index_min, index_mid, index_max];
	if(rgb[index_min] > rgb[index_max])
		_swap(index_min, index_max, index);
	if(rgb[index_min] > rgb[index_mid])
		_swap(index_min, index_mid, index);
	if(rgb[index_mid] > rgb[index_max])
		_swap(index_mid, index_max, index);
	// *min = rgb[*index_min];
	// *mid = rgb[*index_mid];
	// *max = rgb[*index_max];
	return Tuple3<int, int, int>(index[index_min], index[index_mid], index[index_max]);
}

/**
 * @brief Binarize a color channel of a bitmap using local binarization algorithm
 * @param bitmap the input bitmap
 * @param rgb the binarized RGB channels
 * @param blk_ths the black color thresholds for RGB channels
 * @return JAB_SUCCESS | JAB_FAILURE
*/
int binarizerRGB(jab_bitmap bitmap, List<jab_bitmap> rgb, List<double> blk_ths)
{
	for(int i=0; i<3; i++)
	{
		rgb[i] = jab_bitmap(); //(jab_bitmap*)calloc(1, sizeof(jab_bitmap) + bitmap.width*bitmap.height*sizeof(jab_byte));
		rgb[i].pixel= Uint8List(bitmap.width*bitmap.height);
		if(rgb[i] == null)
		{
			// JAB_REPORT_ERROR(("Memory allocation for binary bitmap %d failed", i))
			return JAB_FAILURE;
		}
		rgb[i].width = bitmap.width;
		rgb[i].height= bitmap.height;
		rgb[i].bits_per_channel = 8;
		rgb[i].bits_per_pixel = 8;
		rgb[i].channel_count = 1;
	}

	int bytes_per_pixel = (bitmap.bits_per_pixel / 8).toInt();
	int bytes_per_row = bitmap.width * bytes_per_pixel;

	//calculate the average pixel value, block-wise
	int max_block_size = (max(bitmap.width, bitmap.height) / 2).toInt();
	int block_num_x = ((bitmap.width % max_block_size) != 0 ? (bitmap.width / max_block_size) + 1 : (bitmap.width / max_block_size)).toInt();
	int block_num_y = ((bitmap.height% max_block_size) != 0 ? (bitmap.height/ max_block_size) + 1 : (bitmap.height/ max_block_size)).toInt();
	int block_size_x = (bitmap.width / block_num_x).toInt();
	int block_size_y = (bitmap.height/ block_num_y).toInt();
	var pixel_ave = <List<double>>[]; //.filled(3, 0)>.filled(block_num_x*block_num_y, 0); //double pixel_ave[block_num_x*block_num_y][3];
	// memset(pixel_ave, 0, sizeof(double)*block_num_x*block_num_y*3);
	for(int i=0; i<block_num_x*block_num_y; i++)
	{
		pixel_ave.add(List<double>.filled(3, 0));
	}
	
		if(blk_ths == null)
    {
		for(int i=0; i<block_num_y; i++)
		{
			for(int j=0; j<block_num_x; j++)
			{
				int block_index = i*block_num_x + j;

				int sx = j * block_size_x;
				int ex = (j == block_num_x-1) ? bitmap.width : (sx + block_size_x);
				int sy = i * block_size_y;
				int ey = (i == block_num_y-1) ? bitmap.height: (sy + block_size_y);
				double counter = 0;
				for(int y=sy; y<ey; y++)
				{
						for(int x=sx; x<ex; x++)
						{
								int offset = y * bytes_per_row + x * bytes_per_pixel;
								pixel_ave[block_index][0] += bitmap.pixel[offset + 0];
								pixel_ave[block_index][1] += bitmap.pixel[offset + 1];
								pixel_ave[block_index][2] += bitmap.pixel[offset + 2];
								counter++;
						}
				}
				pixel_ave[block_index][0] /= counter;
				pixel_ave[block_index][1] /= counter;
				pixel_ave[block_index][2] /= counter;
			}
		}
    }

	//binarize each pixel in each channel
	double ths_std = 0.08;
	var rgb_ths = List<double>.filled(3, 0); //[3] = {0, 0, 0};
	for(int i=0; i<bitmap.height; i++)
	{
		for(int j=0; j<bitmap.width; j++)
		{
			int offset = i * bytes_per_row + j * bytes_per_pixel;
			//check black pixel
			if(blk_ths == null)
            {
                int block_index = (min(i/block_size_y, block_num_y-1) * block_num_x + min(j/block_size_x, block_num_x-1)).toInt();
                rgb_ths[0] = pixel_ave[block_index][0];
                rgb_ths[1] = pixel_ave[block_index][1];
                rgb_ths[2] = pixel_ave[block_index][2];
            }
            else
            {
                rgb_ths[0] = blk_ths[0];
                rgb_ths[1] = blk_ths[1];
                rgb_ths[2] = blk_ths[2];
            }
			if(bitmap.pixel[offset + 0] < rgb_ths[0] && bitmap.pixel[offset + 1] < rgb_ths[1] && bitmap.pixel[offset + 2] < rgb_ths[2])
            {
                rgb[0].pixel[i*bitmap.width + j] = 0;
                rgb[1].pixel[i*bitmap.width + j] = 0;
                rgb[2].pixel[i*bitmap.width + j] = 0;
                continue;
            }

			// double ave, vari;
			var result = getAveVar(bitmap.pixel.sublist(offset, offset + 4));
			double std = sqrt(result.item2);	//standard deviation
			// int min, mid, max;
			// int index_min, index_mid, index_max;
			var result1 = getMinMax(bitmap.pixel.sublist(offset, offset + 4));
			std /= bitmap.pixel[offset + result1.item3].toDouble();	//normalize std

			if(std < ths_std && (bitmap.pixel[offset + 0] > rgb_ths[0] && bitmap.pixel[offset + 1] > rgb_ths[1] && bitmap.pixel[offset + 2] > rgb_ths[2]))
			{
				rgb[0].pixel[i*bitmap.width + j] = 255;
				rgb[1].pixel[i*bitmap.width + j] = 255;
				rgb[2].pixel[i*bitmap.width + j] = 255;
			}
			else
			{
				rgb[result1.item3].pixel[i*bitmap.width + j] = 255; //index_max
				rgb[result1.item1].pixel[i*bitmap.width + j] = 0; //index_min
				double r1 = bitmap.pixel[offset + result1.item2] / bitmap.pixel[offset + result1.item1];
				double r2 = bitmap.pixel[offset + result1.item3] / bitmap.pixel[offset + result1.item2];
				if(r1 > r2)
					rgb[result1.item2].pixel[i*bitmap.width + j] = 255; //index_mid
				else
					rgb[result1.item2].pixel[i*bitmap.width + j] = 0; //index_mid
			}
		}
	}
	_filterBinary(rgb[0]);
	_filterBinary(rgb[1]);
	_filterBinary(rgb[2]);
	return JAB_SUCCESS;
}
