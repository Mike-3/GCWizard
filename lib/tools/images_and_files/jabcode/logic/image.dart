/*
 libjabcode - JABCode Encoding/Decoding Library
 Copyright 2016 by Fraunhofer SIT. All rights reserved.
 See LICENSE file for full terms of use and distribution.
 Contact: Huajian Liu <liu@sit.fraunhofer.de>Waldemar Berchtold <waldemar.berchtold@sit.fraunhofer.de

 Read and save png image
*/

import 'dart:typed_data';

import 'package:gc_wizard/logic/tools/images_and_files/qr_code.dart';
import 'package:gc_wizard/widgets/utils/file_utils.dart';
import 'package:image/image.dart' as Image;

import 'package:gc_wizard/tools/images_and_files/jabcode/logic/jabcode_h.dart';

/*
 Read image into code bitmap
 @param filename the image filename
 @return Pointer to the code bitmap read from image | NULL
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

	return bitmap;
}

/*
 create image date
 @param bitmap the image data
 @return image | NULL
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
