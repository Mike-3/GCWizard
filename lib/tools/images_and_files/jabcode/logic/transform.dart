/*
 libjabcode - JABCode Encoding/Decoding Library

 Copyright 2016 by Fraunhofer SIT. All rights reserved.
 See LICENSE file for full terms of use and distribution.

 Contact: Huajian Liu <liu@sit.fraunhofer.de>
			Waldemar Berchtold <waldemar.berchtold@sit.fraunhofer.de>

 Matrix transform
*/

import 'package:gc_wizard/tools/images_and_files/jabcode/logic/detector_h.dart';
import 'package:gc_wizard/tools/images_and_files/jabcode/logic/jabcode_h.dart';

/*
 Calculate transformation matrix of square to quadrilateral
 @param x0 the x coordinate of the 1st destination point
 @param y0 the y coordinate of the 1st destination point
 @param x1 the x coordinate of the 2nd destination point
 @param y1 the y coordinate of the 2nd destination point
 @param x2 the x coordinate of the 3rd destination point
 @param y2 the y coordinate of the 3rd destination point
 @param x3 the x coordinate of the 4th destination point
 @param y3 the y coordinate of the 4th destination point
 @return the transformation matrix
*/
jab_perspective_transform _square2Quad( double x0, double y0,
										double x1, double y1,
										double x2, double y2,
										double x3, double y3) {
	var pt = jab_perspective_transform(); //(jab_perspective_transform*)malloc(sizeof(jab_perspective_transform));

	double dx3 = x0 - x1 + x2 - x3;
	double dy3 = y0 - y1 + y2 - y3;
	if (dx3 == 0 && dy3 == 0) {
		pt.a11 = x1 - x0;
		pt.a21 = x2 - x1;
		pt.a31 = x0;
		pt.a12 = y1 - y0;
		pt.a22 = y2 - y1;
		pt.a32 = y0;
		pt.a13 = 0;
		pt.a23 = 0;
		pt.a33 = 1;
		return pt;
	} else {
		double dx1 = x1 - x2;
		double dx2 = x3 - x2;
		double dy1 = y1 - y2;
		double dy2 = y3 - y2;
		double denominator = dx1 * dy2 - dx2 * dy1;
		double a13 = (dx3 * dy2 - dx2 * dy3) / denominator;
		double a23 = (dx1 * dy3 - dx3 * dy1) / denominator;
		pt.a11 = x1 - x0 + a13 * x1;
		pt.a21 = x3 - x0 + a23 * x3;
		pt.a31 = x0;
		pt.a12 = y1 - y0 + a13 * y1;
		pt.a22 = y3 - y0 + a23 * y3;
		pt.a32 = y0;
		pt.a13 = a13;
		pt.a23 = a23;
		pt.a33 = 1;
		return pt;
	}
}

/*
 Calculate transformation matrix of quadrilateral to square
 @param x0 the x coordinate of the 1st source point
 @param y0 the y coordinate of the 1st source point
 @param x1 the x coordinate of the 2nd source point
 @param y1 the y coordinate of the 2nd source point
 @param x2 the x coordinate of the 3rd source point
 @param y2 the y coordinate of the 3rd source point
 @param x3 the x coordinate of the 4th source point
 @param y3 the y coordinate of the 4th source point
 @return the transformation matrix
*/
jab_perspective_transform _quad2Square( double x0, double y0,
										double x1, double y1,
										double x2, double y2,
										double x3, double y3)
{
	var pt = jab_perspective_transform(); //(jab_perspective_transform*)malloc(sizeof(jab_perspective_transform));

	var s2q = _square2Quad(x0, y0, x1, y1, x2, y2, x3, y3);
	//calculate the adjugate matrix of s2q
	pt.a11 = s2q.a22 * s2q.a33 - s2q.a23 * s2q.a32;
	pt.a21 = s2q.a23 * s2q.a31 - s2q.a21 * s2q.a33;
	pt.a31 = s2q.a21 * s2q.a32 - s2q.a22 * s2q.a31;
	pt.a12 = s2q.a13 * s2q.a32 - s2q.a12 * s2q.a33;
	pt.a22 = s2q.a11 * s2q.a33 - s2q.a13 * s2q.a31;
	pt.a32 = s2q.a12 * s2q.a31 - s2q.a11 * s2q.a32;
	pt.a13 = s2q.a12 * s2q.a23 - s2q.a13 * s2q.a22;
	pt.a23 = s2q.a13 * s2q.a21 - s2q.a11 * s2q.a23;
	pt.a33 = s2q.a11 * s2q.a22 - s2q.a12 * s2q.a21;

	return pt;
}

/*
 Calculate matrix multiplication
 @param m1 the multiplicand
 @param m2 the multiplier
 @return m1 x m2
*/
jab_perspective_transform _multiply(jab_perspective_transform m1, jab_perspective_transform m2) {
	var product = jab_perspective_transform(); // (jab_perspective_transform*)malloc(sizeof(jab_perspective_transform));

	product.a11 = m1.a11 * m2.a11 + m1.a12 * m2.a21 + m1.a13 * m2.a31;
	product.a21 = m1.a21 * m2.a11 + m1.a22 * m2.a21 + m1.a23 * m2.a31;
	product.a31 = m1.a31 * m2.a11 + m1.a32 * m2.a21 + m1.a33 * m2.a31;
	product.a12 = m1.a11 * m2.a12 + m1.a12 * m2.a22 + m1.a13 * m2.a32;
	product.a22 = m1.a21 * m2.a12 + m1.a22 * m2.a22 + m1.a23 * m2.a32;
	product.a32 = m1.a31 * m2.a12 + m1.a32 * m2.a22 + m1.a33 * m2.a32;
	product.a13 = m1.a11 * m2.a13 + m1.a12 * m2.a23 + m1.a13 * m2.a33;
	product.a23 = m1.a21 * m2.a13 + m1.a22 * m2.a23 + m1.a23 * m2.a33;
	product.a33 = m1.a31 * m2.a13 + m1.a32 * m2.a23 + m1.a33 * m2.a33;
	return product;
}

/*
 Calculate transformation matrix of quadrilateral to quadrilateral
 @param x0 the x coordinate of the 1st source point
 @param y0 the y coordinate of the 1st source point
 @param x1 the x coordinate of the 2nd source point
 @param y1 the y coordinate of the 2nd source point
 @param x2 the x coordinate of the 3rd source point
 @param y2 the y coordinate of the 3rd source point
 @param x3 the x coordinate of the 4th source point
 @param y3 the y coordinate of the 4th source point
 @param x0p the x coordinate of the 1st destination point
 @param y0p the y coordinate of the 1st destination point
 @param x1p the x coordinate of the 2nd destination point
 @param y1p the y coordinate of the 2nd destination point
 @param x2p the x coordinate of the 3rd destination point
 @param y2p the y coordinate of the 3rd destination point
 @param x3p the x coordinate of the 4th destination point
 @param y3p the y coordinate of the 4th destination point
 @return the transformation matrix
*/
jab_perspective_transform perspectiveTransform(double x0, double y0,
												double x1, double y1,
												double x2, double y2,
												double x3, double y3,
												double x0p, double y0p,
												double x1p, double y1p,
												double x2p, double y2p,
												double x3p, double y3p) {
	var q2s = _quad2Square(x0, y0, x1, y1, x2, y2, x3, y3);
	// if(q2s == null) {
	// 	return null;
	// }
	var s2q = _square2Quad(x0p, y0p, x1p, y1p, x2p, y2p, x3p, y3p);
	// if(s2q == null) {
	// 	return null;
	// }
	var pt = _multiply(q2s, s2q);
	// if(pt == null) {
	// 	return null;
	// }

	return pt;
}

/*
 Get perspetive transformation matrix
 @param p0 the coordinate of the 1st finder/alignment pattern
 @param p1 the coordinate of the 2nd finder/alignment pattern
 @param p2 the coordinate of the 3rd finder/alignment pattern
 @param p3 the coordinate of the 4th finder/alignment pattern
 @param side_size the side size of the symbol
 @return the transformation matrix
*/
jab_perspective_transform getPerspectiveTransform(jab_point p0,
												   jab_point p1,
												   jab_point p2,
												   jab_point p3,
												   jab_vector2d side_size) {
	return perspectiveTransform(3.5, 3.5,
								side_size.x - 3.5, 3.5,
								side_size.x - 3.5, side_size.y - 3.5,
								3.5, side_size.y - 3.5,
								p0.x, p0.y,
								p1.x, p1.y,
								p2.x, p2.y,
								p3.x, p3.y
							   );
}

/*
 Warp points from source image to destination image in place
 @param pt the transformation matrix
 @param points the source points
 @param length the number of source points
*/
void warpPoints(jab_perspective_transform pt, List<jab_point> points, int length) {
	for (int i=0; i<length; i++) {
		double x = points[i].x;
		double y = points[i].y;
		double denominator = pt.a13 * x + pt.a23 * y + pt.a33;
		points[i].x = (pt.a11 * x + pt.a21 * y + pt.a31) / denominator;
		points[i].y = (pt.a12 * x + pt.a22 * y + pt.a32) / denominator;
	}
}
