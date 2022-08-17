import 'dart:math';

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
 * @file detector.h
 * @brief Detector header
 */

// #ifndef JABCODE_DETECTOR_H
// #define JABCODE_DETECTOR_H

// #define TEST_MODE			0
// #if TEST_MODE
// jab_bitmap* test_mode_bitmap;
// jab_int32	test_mode_color;
// #endif

const MAX_MODULES 		= 145;	//the number of modules in side-version 32
const MAX_SYMBOL_ROWS		= 3;
const MAX_SYMBOL_COLUMNS	= 3;
const MAX_FINDER_PATTERNS = 500;
const PI =					3.14159265;
const CROSS_AREA_WIDTH	= 14;	//the width of the area across the host and slave symbols

double DIST(x1, y1, x2, y2) {
	return (sqrt((x1-x2)*(x1-x2) + (y1-y2)*(y1-y2)));
}

/**
 * @brief Detection modes
*/
enum jab_detect_mode {
	QUICK_DETECT,
	NORMAL_DETECT,
	INTENSIVE_DETECT
}

/**
 * @brief Finder pattern
*/
class jab_finder_pattern {
	int		type = 0;
	double		module_size = 0.0;
	var		center = jab_point(0.0,0.0);			//coordinates of the center
	int		found_count = 0;
	int 	direction = 0;

	import(jab_alignment_pattern alignment_pattern) {
		type= alignment_pattern.type;
		module_size= alignment_pattern.module_size;
		center= alignment_pattern.center;
		found_count= alignment_pattern.found_count;
		direction= alignment_pattern.direction;
	}
}

/**
 * @brief Alignment pattern
 */
class jab_alignment_pattern {
	int		type = 0;
	double		module_size = 0.0;
	var		center = jab_point(0.0,0.0);			//coordinates of the center
	int		found_count = 0;
	int 	direction = 0;

	import(jab_finder_pattern finder_pattern) {
		type= finder_pattern.type;
		module_size= finder_pattern.module_size;
		center= finder_pattern.center;
		found_count= finder_pattern.found_count;
		direction= finder_pattern.direction;
	}
}

/**
 * @brief Perspective transform
*/
class jab_perspective_transform  {
	double a11;
	double a12;
	double a13;
	double a21;
	double a22;
	double a23;
	double a31;
	double a32;
	double a33;
}

// extern void getAveVar(jab_byte* rgb, jab_double* ave, jab_double* var);
// extern void getMinMax(jab_byte* rgb, jab_byte* min, jab_byte* mid, jab_byte* max, jab_int32* index_min, jab_int32* index_mid, jab_int32* index_max);
// extern void balanceRGB(jab_bitmap* bitmap);
// extern jab_boolean binarizerRGB(jab_bitmap* bitmap, jab_bitmap* rgb[3], jab_float* blk_ths);
// extern jab_bitmap* binarizer(jab_bitmap* bitmap, jab_int32 channel);
// extern jab_bitmap* binarizerHist(jab_bitmap* bitmap, jab_int32 channel);
// extern jab_bitmap* binarizerHard(jab_bitmap* bitmap, jab_int32 channel, jab_int32 threshold);
// extern jab_perspective_transform* getPerspectiveTransform(jab_point p0, jab_point p1,
// 														  jab_point p2, jab_point p3,
// 														  jab_vector2d side_size);
// extern jab_perspective_transform* perspectiveTransform( jab_float x0, jab_float y0,
// 														jab_float x1, jab_float y1,
// 														jab_float x2, jab_float y2,
// 														jab_float x3, jab_float y3,
// 														jab_float x0p, jab_float y0p,
// 														jab_float x1p, jab_float y1p,
// 														jab_float x2p, jab_float y2p,
// 														jab_float x3p, jab_float y3p);
// extern void warpPoints(jab_perspective_transform* pt, jab_point* points, jab_int32 length);
// extern jab_bitmap* sampleSymbol(jab_bitmap* bitmap, jab_perspective_transform* pt, jab_vector2d side_size);
// extern jab_bitmap* sampleCrossArea(jab_bitmap* bitmap, jab_perspective_transform* pt);
//
// #endif
