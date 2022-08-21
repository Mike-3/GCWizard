/**
 * libjabcode - JABCode Encoding/Decoding Library
 *
 * Copyright 2016 by Fraunhofer SIT. All rights reserved.
 * See LICENSE file for full terms of use and distribution.
 *
 * Contact: Huajian Liu <liu@sit.fraunhofer.de>
 *			Waldemar Berchtold <waldemar.berchtold@sit.fraunhofer.de>
 *
 * @file image.c
 * @brief Read and save png image
 */

// #include <stddef.h>
// #include <stdlib.h>
// #include <string.h>
// #include "jabcode.h"
// #include "png.h"
// #include "tiffio.h"

// /**
//  * @brief Save code bitmap in RGB as png image
//  * @param bitmap the code bitmap
//  * @param filename the image filename
//  * @return JAB_SUCCESS | JAB_FAILURE
// */
// bool saveImage(jab_bitmap bitmap, String filename)
// {
// 	png_image image;
//     memset(&image, 0, sizeof(image));
//     image.version = PNG_IMAGE_VERSION;
//
//     if(bitmap.channel_count == 4)
//     {
// 		image.format = PNG_FORMAT_RGBA;
// 		image.flags  = PNG_FORMAT_FLAG_ALPHA | PNG_FORMAT_FLAG_COLOR;
//     }
//     else
//     {
// 		image.format = PNG_FORMAT_GRAY;
//     }
//
//     image.width  = bitmap.width;
//     image.height = bitmap.height;
//
//     if (png_image_write_to_file(&image,
// 								filename,
// 								0/*convert_to_8bit*/,
// 								bitmap.pixel,
// 								0/*row_stride*/,
// 								NULL/*colormap*/) == 0)
// 	{
// 		reportError(image.message);
// 		reportError("Saving png image failed");
// 		return JAB_FAILURE;
// 	}
// 	return JAB_SUCCESS;
// }

import 'dart:math';
import 'dart:typed_data';

import 'package:gc_wizard/logic/tools/images_and_files/qr_code.dart';
import 'package:gc_wizard/widgets/utils/file_utils.dart';
import 'package:image/image.dart' as Image;

import 'jabcode_h.dart';


// /**
//  * @brief Convert a bitmap from RGB to CMYK color space
//  * @param bitmap the bitmap in RGB
//  * @return the bitmap in CMYK | JAB_FAILURE
// */
// jab_bitmap convertRGB2CMYK(jab_bitmap rgb)
// {
// 	if(rgb.channel_count < 3)
// 	{
// 		// JAB_REPORT_ERROR(("Not true color RGB bitmap"))
//         return JAB_FAILURE;
// 	}
// 	int w = rgb.width;
// 	int h = rgb.height;
// 	jab_bitmap cmyk = (jab_bitmap *)malloc(sizeof(jab_bitmap) + w*h*BITMAP_CHANNEL_COUNT*sizeof(jab_byte));
// 	if(cmyk == null)
//     {
//         // JAB_REPORT_ERROR(("Memory allocation for CMYK bitmap failed"))
//         return JAB_FAILURE;
//     }
//     cmyk.width = w;
//     cmyk.height= h;
//     cmyk.bits_per_pixel = BITMAP_BITS_PER_PIXEL;
//     cmyk.bits_per_channel = BITMAP_BITS_PER_CHANNEL;
//     cmyk.channel_count = BITMAP_CHANNEL_COUNT;
//
// 	int rgb_bytes_per_pixel = (rgb.bits_per_pixel / 8).toInt();
//     int rgb_bytes_per_row = rgb.width * rgb_bytes_per_pixel;
//     int cmyk_bytes_per_pixel = (rgb.bits_per_pixel / 8).toInt();
//     int cmyk_bytes_per_row = rgb.width * cmyk_bytes_per_pixel;
//
//
//     for(int i=0; i<h; i++)
// 	{
// 		for(int j=0; j<w; j++)
// 		{
// 			double r1 = rgb.pixel[i*rgb_bytes_per_row + j*rgb_bytes_per_pixel + 0] / 255.0;
// 			double g1 = rgb.pixel[i*rgb_bytes_per_row + j*rgb_bytes_per_pixel + 1] / 255.0;
// 			double b1 = rgb.pixel[i*rgb_bytes_per_row + j*rgb_bytes_per_pixel + 2] / 255.0;
//
// 			double k = 1 - max(r1, max(g1, b1));
//
// 			if(k == 1)
// 			{
// 				cmyk.pixel[i*cmyk_bytes_per_row + j*cmyk_bytes_per_pixel + 0] = 0;	//C
// 				cmyk.pixel[i*cmyk_bytes_per_row + j*cmyk_bytes_per_pixel + 1] = 0;	//M
// 				cmyk.pixel[i*cmyk_bytes_per_row + j*cmyk_bytes_per_pixel + 2] = 0;	//Y
// 				cmyk.pixel[i*cmyk_bytes_per_row + j*cmyk_bytes_per_pixel + 3] = 255;	//K
// 			}
// 			else
// 			{
// 				cmyk.pixel[i*cmyk_bytes_per_row + j*cmyk_bytes_per_pixel + 0] = ((1.0 - r1 - k) / (1.0 - k) * 255).toInt();	//C
// 				cmyk.pixel[i*cmyk_bytes_per_row + j*cmyk_bytes_per_pixel + 1] = ((1.0 - g1 - k) / (1.0 - k) * 255).toInt();	//M
// 				cmyk.pixel[i*cmyk_bytes_per_row + j*cmyk_bytes_per_pixel + 2] = ((1.0 - b1 - k) / (1.0 - k) * 255).toInt();	//Y
// 				cmyk.pixel[i*cmyk_bytes_per_row + j*cmyk_bytes_per_pixel + 3] = (k * 255).toInt();								//K
// 			}
// 		}
// 	}
//     return cmyk;
// }

// /**
//  * @brief Save code bitmap in CMYK as TIFF image
//  * @param bitmap the code bitmap
//  * @param isCMYK set TRUE if the code bitmap is already in CMYK
//  * @param filename the image filename
//  * @return JAB_SUCCESS | JAB_FAILURE
// */
// jab_boolean saveImageCMYK(jab_bitmap* bitmap, jab_boolean isCMYK, jab_char* filename)
// {
// 	jab_bitmap* cmyk = 0;
//
// 	if(isCMYK)
// 	{
// 		cmyk = bitmap;
// 	}
// 	else
// 	{
// 		cmyk = convertRGB2CMYK(bitmap);
// 		if(cmyk == NULL)
// 		{
// 			JAB_REPORT_ERROR(("Converting RGB to CMYK failed"))
// 			return JAB_FAILURE;
// 		}
// 	}
//
// 	//save CMYK image as TIFF
// 	TIFF *out= TIFFOpen(filename, "w");
// 	if(out == NULL)
// 	{
// 		JAB_REPORT_ERROR(("Cannot open %s for writing", filename))
// 		if(!isCMYK)	free(cmyk);
// 		return JAB_FAILURE;
// 	}
//
// 	TIFFSetField(out, TIFFTAG_IMAGEWIDTH, cmyk.width);
// 	TIFFSetField(out, TIFFTAG_IMAGELENGTH, cmyk.height);
// 	TIFFSetField(out, TIFFTAG_SAMPLESPERPIXEL, cmyk.channel_count);
// 	TIFFSetField(out, TIFFTAG_BITSPERSAMPLE, cmyk.bits_per_channel);
// 	TIFFSetField(out, TIFFTAG_ORIENTATION, ORIENTATION_TOPLEFT);
// 	TIFFSetField(out, TIFFTAG_PLANARCONFIG, PLANARCONFIG_CONTIG);
// 	TIFFSetField(out, TIFFTAG_PHOTOMETRIC, PHOTOMETRIC_SEPARATED);
// 	int rows_per_strip = TIFFDefaultStripSize(out, -1);
// 	TIFFSetField(out, TIFFTAG_ROWSPERSTRIP, rows_per_strip);
//
// 	//write image to the file one scanline at a time
// 	int row_size = cmyk.width * cmyk.channel_count;
// 	jab_boolean status = JAB_SUCCESS;
// 	for(int row=0; row<cmyk.height; row++)
// 	{
// 		if(TIFFWriteScanline(out, &cmyk.pixel[row * row_size], row, 0) < 0)
// 		{
// 			status = JAB_FAILURE;
// 			break;
// 		}
// 	}
//
// 	TIFFClose(out);
// 	if(!isCMYK)	free(cmyk);
// 	return status;
// }

/**
 * @brief Read image into code bitmap
 * @param filename the image filename
 * @return Pointer to the code bitmap read from image | NULL
*/
jab_bitmap readImage(Uint8List image) {
	var bitmap = jab_bitmap();
	var _image = Image.decodeImage(image);

	bitmap.pixel = _image.getBytes();
	bitmap.width = _image.width;
	bitmap.height = _image.height;
	bitmap.bits_per_channel = BITMAP_BITS_PER_CHANNEL;
	bitmap.channel_count = _image.numberOfChannels; //BITMAP_CHANNEL_COUNT;
	bitmap.bits_per_pixel = bitmap.bits_per_channel * bitmap.channel_count;

	// int bytes_per_pixel = (bitmap.bits_per_pixel / 8).toInt();
	// int bytes_per_row = bitmap.width * bytes_per_pixel;

	// bitmap.pixel = Uint8List(bitmap.width * bitmap.height * bitmap.channel_count);
	// for (int y=0; y<bitmap.height;y++) {
	// 	for (int x=0; x<bitmap.width;x++) {
	// 		var pixel = _image.getPixel(x, y);
	// 		var offset = y*bytes_per_row + x*bytes_per_pixel;
	// 		bitmap.pixel[offset+0]=Image.getRed(pixel);
	// 		bitmap.pixel[offset+1]=Image.getGreen(pixel);
	// 		bitmap.pixel[offset+2]=Image.getBlue(pixel);
	// 	}
	// }

	return bitmap;
}

/**
 * @brief create image date
 * @param bitmap the image data
 * @return image | NULL
 */
Future<Uint8List> saveImage(jab_bitmap bitmap, double border) async {
	if (bitmap == null) return null;

	var _image = Image.Image(bitmap.width, bitmap.height);
	int bytes_per_pixel = (bitmap.bits_per_pixel / 8).toInt();
	int bytes_per_row = bitmap.width * bytes_per_pixel;

	for (int y=0; y<bitmap.height;y++) {
		for (int x=0; x<bitmap.width;x++) {
			var offset = y*bytes_per_row + x*bytes_per_pixel;
			var pixel = Image.Color.fromRgb(bitmap.pixel[offset+0],
																			bitmap.pixel[offset+1],
																			bitmap.pixel[offset+2]);

			_image.setPixel(x, y, pixel);
		}
	}

	var data = encodeTrimmedPng(_image);
	if (border > 0)
		data = await addBorder(data, border: border);

	return Future.value(data);
}
