/*
 libjabcode - JABCode Encoding/Decoding Library

 Copyright 2016 by Fraunhofer SIT. All rights reserved.
 See LICENSE file for full terms of use and distribution.

 Contact: Huajian Liu <liu@sit.fraunhofer.de>
			Waldemar Berchtold <waldemar.berchtold@sit.fraunhofer.de>


 Symbol sampling
*/

import 'transform.dart';
import 'package:gc_wizard/tools/images_and_files/jabcode/logic/detector_h.dart';
import 'package:gc_wizard/tools/images_and_files/jabcode/logic/jabcode_h.dart';


final SAMPLE_AREA_WIDTH	= (CROSS_AREA_WIDTH / 2 - 2).toInt(); //width of the columns where the metadata and palette in slave symbol are located
const SAMPLE_AREA_HEIGHT =	20;	//height of the metadata rows including the first row, though it does not contain metadata

/*
 Sample a symbol
 @param bitmap the image bitmap
 @param pt the transformation matrix
 @param side_size the symbol size in module
 @return the sampled symbol matrix
*/
jab_bitmap? sampleSymbol(jab_bitmap bitmap, jab_perspective_transform pt, jab_vector2d side_size) {
	int mtx_bytes_per_pixel = bitmap.bits_per_pixel ~/ 8;
	int mtx_bytes_per_row = side_size.x * mtx_bytes_per_pixel;
	var matrix = jab_bitmap(); //(jab_bitmap*)malloc(sizeof(jab_bitmap) + side_size.x*side_size.y*mtx_bytes_per_pixel*sizeof(jab_byte));

	matrix.channel_count = bitmap.channel_count;
	matrix.bits_per_channel = bitmap.bits_per_channel;
	matrix.bits_per_pixel = matrix.bits_per_channel * matrix.channel_count;
	matrix.width = side_size.x;
	matrix.height= side_size.y;

	int bmp_bytes_per_pixel = bitmap.bits_per_pixel ~/ 8;
	int bmp_bytes_per_row = bitmap.width * bmp_bytes_per_pixel;

	var points = List<jab_point>.filled(side_size.x, null);
	for(int i=0; i<side_size.y; i++) {
		for(int j=0; j<side_size.x; j++) {
			points[j].x = j + 0.5;
			points[j].y = i + 0.5;
		}
		warpPoints(pt, points, side_size.x);
		for(int j=0; j<side_size.x; j++) {
			int mapped_x = points[j].x.toInt();
			int mapped_y = points[j].y.toInt();
			if(mapped_x < 0 || mapped_x > bitmap.width-1) {
				if(mapped_x == -1) {
				  mapped_x = 0;
				} else if(mapped_x ==  bitmap.width) {
				  mapped_x = bitmap.width - 1;
				} else {
				  return null;
				}
			}
			if(mapped_y < 0 || mapped_y > bitmap.height-1) {
				if(mapped_y == -1) {
				  mapped_y = 0;
				} else if(mapped_y ==  bitmap.height) {
				  mapped_y = bitmap.height - 1;
				} else {
				  return null;
				}
			}
			for(int c=0; c<matrix.channel_count; c++) {
				//get the average of pixel values in 3x3 neighborhood as the sampled value
				double sum = 0;
				for(int dx=-1; dx<=1; dx++) {
					for(int dy=-1; dy<=1; dy++) {
						int px = mapped_x + dx;
						int py = mapped_y + dy;
						if(px < 0 || px > bitmap.width - 1)  px = mapped_x;
						if(py < 0 || py > bitmap.height - 1) py = mapped_y;
						sum += bitmap.pixel[py*bmp_bytes_per_row + px*bmp_bytes_per_pixel + c];
					}
				}
				int ave = (sum / 9.0 + 0.5).toInt();
				matrix.pixel[i*mtx_bytes_per_row + j*mtx_bytes_per_pixel + c] = ave;
				//matrix.pixel[i*mtx_bytes_per_row + j*mtx_bytes_per_pixel + c] = bitmap.pixel[mapped_y*bmp_bytes_per_row + mapped_x*bmp_bytes_per_pixel + c];
			}
		}
	}
	return matrix;
}

