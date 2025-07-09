/*
 libjabcode - JABCode Encoding/Decoding Library

 Copyright 2016 by Fraunhofer SIT. All rights reserved.
 See LICENSE file for full terms of use and distribution.

 Contact: Huajian Liu <liu@sit.fraunhofer.de>
			Waldemar Berchtold <waldemar.berchtold@sit.fraunhofer.de>

 Binarize the image
*/

import 'dart:core';
import 'dart:math';
import 'dart:typed_data';
import 'package:gc_wizard/tools/images_and_files/jabcode/logic/jabcode_h.dart';


const BLOCK_SIZE_POWER = 5;
const BLOCK_SIZE = (1 << BLOCK_SIZE_POWER);
const BLOCK_SIZE_MASK =	(BLOCK_SIZE - 1);
const MINIMUM_DIMENSION = (BLOCK_SIZE * 5);
int CAP(int val, int min, int max)	{return (val < min ? min : (val > max ? max : val));}


/*
 Filter out noises in binary bitmap
 @param binary the binarized bitmap
*/
void _filterBinary(jab_bitmap binary) {
	int width = binary.width;
	int height= binary.height;

	int filter_size = 5;
	int half_size = (filter_size - 1)~/2;

	//horizontal filtering
	var tmp = binary.clone(); // memcpy(tmp, binary, sizeof(jab_bitmap) + width*height*sizeof(jab_byte));
	for(int i=half_size; i<height-half_size; i++) {
		for(int j=half_size; j<width-half_size; j++) {
			int sum = 0;
			sum += tmp.pixel[i*width + j] > 0 ? 1 : 0;
			for(int k=1; k<=half_size; k++) {
				sum += tmp.pixel[i*width + (j - k)] > 0 ? 1 : 0;
				sum += tmp.pixel[i*width + (j + k)] > 0 ? 1 : 0;
			}
			binary.pixel[i*width + j] = sum > half_size ? 255 : 0;
		}
	}
	//vertical filtering
	tmp = binary.clone(); //memcpy(tmp, binary, sizeof(jab_bitmap) + width*height*sizeof(jab_byte));
	for(int i=half_size; i<height-half_size; i++) {
		for(int j=half_size; j<width-half_size; j++) {
			int sum = 0;
			sum += tmp.pixel[i*width + j] > 0 ? 1 : 0;
			for(int k=1; k<=half_size; k++) {
				sum += tmp.pixel[(i - k)*width + j] > 0 ? 1 : 0;
				sum += tmp.pixel[(i + k)*width + j] > 0 ? 1 : 0;
			}
			binary.pixel[i*width + j] = sum > half_size ? 255 : 0;
		}
	}

}

/*
 Get the histogram of a color channel
 @param bitmap the image
 @param channel the channel
 @param hist the histogram
*/
void _getHistogram(jab_bitmap bitmap, int channel, List<int> hist) {
	// memset(hist, 0, 256*sizeof(int));
	int bytes_per_pixel = bitmap.bits_per_pixel ~/ 8;
	for(int i=0; i<bitmap.width*bitmap.height; i++) {
		hist[bitmap.pixel[i*bytes_per_pixel + channel]]++;
	}
}

/*
 Get the min and max index in the histogram whose value is larger than the threshold
 @param hist the histogram
 @param ths the threshold
 @return item1 the min index
 @return item2 the max index
*/
({int min, int max}) _getHistMaxMin(List<int> hist, int ths) {
	//get min
	var min = 0;
	for(int i=0; i<256; i++) {
		if(hist[i] > ths) {
			min = i;
			break;
		}
	}
	//get max
	var max = 255;
	for(int i=255; i>=0; i--) {
		if(hist[i] > ths) {
			max = i;
			break;
		}
	}
	return (min: min, max: max);
}

/*
 Stretch the histograms of R, G and B channels
 @param bitmap the image
*/
void balanceRGB(jab_bitmap bitmap) {
	int bytes_per_pixel = bitmap.bits_per_pixel ~/ 8;
	int bytes_per_row = bitmap.width * bytes_per_pixel;

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
	for(int i=0; i<bitmap.height; i++) {
		for(int j=0; j<bitmap.width; j++) {
			int offset = i * bytes_per_row + j * bytes_per_pixel;
			//R channel
			if		(bitmap.pixel[offset + 0] < r.min) {
			  bitmap.pixel[offset + 0] = 0;
			} else if (bitmap.pixel[offset + 0] > r.max) {
			  bitmap.pixel[offset + 0] = 255;
			} else {
			  bitmap.pixel[offset + 0] = ((bitmap.pixel[offset + 0] - r.min) / (r.max - r.min) * 255.0).toInt();
			}
			//G channel
			if		(bitmap.pixel[offset + 1] < g.min) {
			  bitmap.pixel[offset + 1] = 0;
			} else if (bitmap.pixel[offset + 1] > g.max) {
			  bitmap.pixel[offset + 1] = 255;
			} else {
			  bitmap.pixel[offset + 1] = ((bitmap.pixel[offset + 1] - g.min) / (g.max - g.min) * 255.0).toInt();
			}
			//B channel
			if		(bitmap.pixel[offset + 2] < b.max) {
			  bitmap.pixel[offset + 2] = 0;
			} else if	(bitmap.pixel[offset + 2] > b.max) {
			  bitmap.pixel[offset + 2] = 255;
			} else {
			  bitmap.pixel[offset + 2] = ((bitmap.pixel[offset + 2] - b.min) / (b.max - b.min) * 255.0).toInt();
			}
		}
	}
}

/*
 Get the average and variance of RGB values
 @param rgb the pixel with RGB values
 @return item1 the average value
 @return item2 the variance value
*/

({double ave, double vari}) getAveVar(Uint8List rgb) {
	//calculate mean
	var ave = (rgb[0] + rgb[1] + rgb[2]) / 3;
	//calculate variance
	var sum = 0.0;
	for(var i=0; i<3; i++) {
		sum += (rgb[i] - ave) * (rgb[i] - ave);
	}
	return (ave: ave, vari: sum / 3);
}

/*
 @ Swap two variables
*/
void _swap(int index1, int index2, List<int> list) {
	int tmp = list[index1];
	list[index1] = list[index2];
	list[index2] = tmp;
}

/*
 Get the min, middle and max value of three values and the corresponding indexes
 @param rgb the pixel with RGB values
 @return item1 index min value
 @return item2 index middle value
 @return item3 index max value
*/
({int min, int middle, int max}) getMinMax(Uint8List rgb) {
	const index_min = 0;
	const index_mid = 1;
	const index_max = 2;
	var index = [index_min, index_mid, index_max];
	if(rgb[index_min] > rgb[index_max]) {
	  _swap(index_min, index_max, index);
	}
	if(rgb[index_min] > rgb[index_mid]) {
	  _swap(index_min, index_mid, index);
	}
	if(rgb[index_mid] > rgb[index_max]) {
	  _swap(index_mid, index_max, index);
	}

	return (min: index[index_min], middle: index[index_mid], max: index[index_max]);
}

/*
 Binarize a color channel of a bitmap using local binarization algorithm
 @param bitmap the input bitmap
 @param rgb the binarized RGB channels
 @param blk_ths the black color thresholds for RGB channels
 @return JAB_SUCCESS | JAB_FAILURE
*/
int binarizerRGB(jab_bitmap bitmap, List<jab_bitmap> rgb, List<double>? blk_ths) {
	for(int i=0; i<3; i++) {
		// rgb[i] = jab_bitmap(); //(jab_bitmap*)calloc(1, sizeof(jab_bitmap) + bitmap.width*bitmap.height*sizeof(jab_byte));
		rgb[i].pixel= Uint8List(bitmap.width*bitmap.height);

		rgb[i].width = bitmap.width;
		rgb[i].height= bitmap.height;
		rgb[i].bits_per_channel = 8;
		rgb[i].bits_per_pixel = 8;
		rgb[i].channel_count = 1;
	}

	int bytes_per_pixel = (bitmap.bits_per_pixel / 8).toInt();
	int bytes_per_row = bitmap.width * bytes_per_pixel;

	//calculate the average pixel value, block-wise
	int max_block_size = max(bitmap.width, bitmap.height) ~/ 2;
	int block_num_x = ((bitmap.width % max_block_size) != 0 ? (bitmap.width / max_block_size) + 1 : (bitmap.width / max_block_size)).toInt();
	int block_num_y = ((bitmap.height% max_block_size) != 0 ? (bitmap.height/ max_block_size) + 1 : (bitmap.height/ max_block_size)).toInt();
	int block_size_x = bitmap.width ~/ block_num_x;
	int block_size_y = bitmap.height~/ block_num_y;
	var pixel_ave = <List<double>>[]; //.filled(3, 0)>.filled(block_num_x*block_num_y, 0); //double pixel_ave[block_num_x*block_num_y][3];

	for(int i=0; i<block_num_x*block_num_y; i++) {
		pixel_ave.add(List<double>.filled(3, 0));
	}
	
	if(blk_ths == null) {
		for(int i=0; i<block_num_y; i++) {
			for(int j=0; j<block_num_x; j++) {
				int block_index = i*block_num_x + j;

				int sx = j * block_size_x;
				int ex = (j == block_num_x-1) ? bitmap.width : (sx + block_size_x);
				int sy = i * block_size_y;
				int ey = (i == block_num_y-1) ? bitmap.height: (sy + block_size_y);
				double counter = 0;
				for(int y=sy; y<ey; y++) {
					for(int x=sx; x<ex; x++) {
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
	for(int i=0; i<bitmap.height; i++) {
		for(int j=0; j<bitmap.width; j++) {
			int offset = i * bytes_per_row + j * bytes_per_pixel;
			//check black pixel
			if(blk_ths == null) {
				int block_index = (min(i/block_size_y, block_num_y-1) * block_num_x + min(j/block_size_x, block_num_x-1)).toInt();
				rgb_ths[0] = pixel_ave[block_index][0];
				rgb_ths[1] = pixel_ave[block_index][1];
				rgb_ths[2] = pixel_ave[block_index][2];
			} else {
				rgb_ths[0] = blk_ths[0];
				rgb_ths[1] = blk_ths[1];
				rgb_ths[2] = blk_ths[2];
			}
			if(bitmap.pixel[offset + 0] < rgb_ths[0] && bitmap.pixel[offset + 1] < rgb_ths[1] && bitmap.pixel[offset + 2] < rgb_ths[2]) {
				rgb[0].pixel[i*bitmap.width + j] = 0;
				rgb[1].pixel[i*bitmap.width + j] = 0;
				rgb[2].pixel[i*bitmap.width + j] = 0;
				continue;
			}

			// double ave, vari;
			var result = getAveVar(bitmap.pixel.sublist(offset, offset + 4));
			double std = sqrt(result.vari);	//standard deviation
			var result1 = getMinMax(bitmap.pixel.sublist(offset, offset + 4));
			std /= bitmap.pixel[offset + result1.max].toDouble();	//normalize std

			if(std < ths_std && (bitmap.pixel[offset + 0] > rgb_ths[0] && bitmap.pixel[offset + 1] > rgb_ths[1] && bitmap.pixel[offset + 2] > rgb_ths[2])) {
				rgb[0].pixel[i*bitmap.width + j] = 255;
				rgb[1].pixel[i*bitmap.width + j] = 255;
				rgb[2].pixel[i*bitmap.width + j] = 255;
			} else {
				rgb[result1.max].pixel[i*bitmap.width + j] = 255; //index_max
				rgb[result1.min].pixel[i*bitmap.width + j] = 0; //index_min
				double r1 = bitmap.pixel[offset + result1.middle] / bitmap.pixel[offset + result1.min];
				double r2 = bitmap.pixel[offset + result1.max] / bitmap.pixel[offset + result1.middle];
				if(r1 > r2) {
				  rgb[result1.middle].pixel[i*bitmap.width + j] = 255; //index_mid
				} else {
				  rgb[result1.middle].pixel[i*bitmap.width + j] = 0; //index_mid
				}
			}
		}
	}
	_filterBinary(rgb[0]);
	_filterBinary(rgb[1]);
	_filterBinary(rgb[2]);
	return JAB_SUCCESS;
}
