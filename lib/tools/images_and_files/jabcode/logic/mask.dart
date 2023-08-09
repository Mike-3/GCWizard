/*
 libjabcode - JABCode Encoding/Decoding Library

 Copyright 2016 by Fraunhofer SIT. All rights reserved.
 See LICENSE file for full terms of use and distribution.

 Contact: Huajian Liu <liu@sit.fraunhofer.de>
			Waldemar Berchtold <waldemar.berchtold@sit.fraunhofer.de>

 Data module masking
*/

import 'package:gc_wizard/tools/images_and_files/jabcode/logic/encoder_h.dart';
import 'package:gc_wizard/tools/images_and_files/jabcode/logic/jabcode_h.dart';

const _w1 = 100;
const _w2 = 3;
const _w3 = 3;

/*
 Apply mask penalty rule 1
 @param matrix the symbol matrix
 @param width the symbol matrix width
 @param height the symbol matrix height
 @param color_number the number of module colors
 @return the penalty score
*/
int applyRule1(List<int> matrix, int width, int height, int color_number) {
	int fp0_c1, fp0_c2;
	int fp1_c1, fp1_c2;
	int fp2_c1, fp2_c2;
	int fp3_c1, fp3_c2;
	if(color_number == 2) {  //two colors: black(000) white(111)
		fp0_c1 = 0;	fp0_c2 = 1;
		fp1_c1 = 1;	fp1_c2 = 0;
		fp2_c1 = 1;	fp2_c2 = 0;
		fp3_c1 = 1;	fp3_c2 = 0;
	}else if(color_number == 4) {
		fp0_c1 = 0;	fp0_c2 = 3;
		fp1_c1 = 1;	fp1_c2 = 2;
		fp2_c1 = 2;	fp2_c2 = 1;
		fp3_c1 = 3;	fp3_c2 = 0;
	}else {
		fp0_c1 = FP0_CORE_COLOR;	fp0_c2 = 7 - FP0_CORE_COLOR;
		fp1_c1 = FP1_CORE_COLOR;	fp1_c2 = 7 - FP1_CORE_COLOR;
		fp2_c1 = FP2_CORE_COLOR;	fp2_c2 = 7 - FP2_CORE_COLOR;
		fp3_c1 = FP3_CORE_COLOR;	fp3_c2 = 7 - FP3_CORE_COLOR;
	}

	int score = 0;
	for(int i=0; i<height; i++) {
		for(int j=0; j<width; j++) {
			if(j >= 2 && j <= width - 3 && i >= 2 && i <= height - 3) {
				if(matrix[i * width + j - 2] == fp0_c1 &&	//finder pattern 0
					 matrix[i * width + j - 1] == fp0_c2 &&
					 matrix[i * width + j    ] == fp0_c1 &&
					 matrix[i * width + j + 1] == fp0_c2 &&
					 matrix[i * width + j + 2] == fp0_c1 &&
					 matrix[(i - 2) * width + j] == fp0_c1 &&
					 matrix[(i - 1) * width + j] == fp0_c2 &&
					 matrix[(i    ) * width + j] == fp0_c1 &&
					 matrix[(i + 1) * width + j] == fp0_c2 &&
					 matrix[(i + 2) * width + j] == fp0_c1)
				   score++;
				else if(
				   matrix[i * width + j - 2] == fp1_c1 &&	//finder pattern 1
				   matrix[i * width + j - 1] == fp1_c2 &&
				   matrix[i * width + j    ] == fp1_c1 &&
				   matrix[i * width + j + 1] == fp1_c2 &&
				   matrix[i * width + j + 2] == fp1_c1 &&
				   matrix[(i - 2) * width + j] == fp1_c1 &&
				   matrix[(i - 1) * width + j] == fp1_c2 &&
				   matrix[(i    ) * width + j] == fp1_c1 &&
				   matrix[(i + 1) * width + j] == fp1_c2 &&
				   matrix[(i + 2) * width + j] == fp1_c1)
				   score++;
				else if(
					 matrix[i * width + j - 2] == fp2_c1 &&	//finder pattern 2
					 matrix[i * width + j - 1] == fp2_c2 &&
					 matrix[i * width + j    ] == fp2_c1 &&
					 matrix[i * width + j + 1] == fp2_c2 &&
					 matrix[i * width + j + 2] == fp2_c1 &&
					 matrix[(i - 2) * width + j] == fp2_c1 &&
					 matrix[(i - 1) * width + j] == fp2_c2 &&
					 matrix[(i    ) * width + j] == fp2_c1 &&
					 matrix[(i + 1) * width + j] == fp2_c2 &&
					 matrix[(i + 2) * width + j] == fp2_c1)
				   score++;
				else if(
				   matrix[i * width + j - 2] == fp3_c1 &&	//finder pattern 3
				   matrix[i * width + j - 1] == fp3_c2 &&
				   matrix[i * width + j    ] == fp3_c1 &&
				   matrix[i * width + j + 1] == fp3_c2 &&
				   matrix[i * width + j + 2] == fp3_c1 &&
				   matrix[(i - 2) * width + j] == fp3_c1 &&
				   matrix[(i - 1) * width + j] == fp3_c2 &&
				   matrix[(i    ) * width + j] == fp3_c1 &&
				   matrix[(i + 1) * width + j] == fp3_c2 &&
				   matrix[(i + 2) * width + j] == fp3_c1)
				   score++;
			}
		}
	}
	return _w1 * score;
}

/*
 Apply mask penalty rule 2
 @param matrix the symbol matrix
 @param width the symbol matrix width
 @param height the symbol matrix height
 @return the penalty score
*/
int applyRule2(List<int> matrix, int width, int height) {
	int score = 0;
	for(int i=0; i<height-1; i++) {
		for(int j=0; j<width-1; j++) {
			if(matrix[i * width + j] != -1 && matrix[i * width + (j + 1)] != -1 &&
			   matrix[(i + 1) * width + j] != -1 && matrix[(i + 1) * width + (j + 1)] != -1)
			{
				if(matrix[i * width + j] == matrix[i * width + (j + 1)] &&
				   matrix[i * width + j] == matrix[(i + 1) * width + j] &&
				   matrix[i * width + j] == matrix[(i + 1) * width + (j + 1)])
				   	score++;
			}
		}
	}
	return _w2 * score;
}

/*
 Apply mask penalty rule 3
 @param matrix the symbol matrix
 @param width the symbol matrix width
 @param height the symbol matrix height
 @return the penalty score
*/
int applyRule3(List<int> matrix, int width, int height) {
	int score = 0;
	for(int k=0; k<2; k++) {
		int maxi, maxj;
		if(k == 0) {	//horizontal scan
			maxi = height;
			maxj = width;
		} else {		//vertical scan
			maxi = width;
			maxj = height;
		}
		for(int i=0; i<maxi; i++) {
			int same_color_count = 0;
			int pre_color = -1;
			for(int j=0; j<maxj; j++) {
				int cur_color = ( k == 0 ? matrix[i * width + j] : matrix[j * width + i] );
				if(cur_color != -1) {
					if(cur_color == pre_color)
						same_color_count++;
					else {
						if(same_color_count >= 5)
							score += _w3 + (same_color_count - 5);
						same_color_count = 1;
						pre_color = cur_color;
					}
				} else {
					if(same_color_count >= 5)
						score += _w3 + (same_color_count - 5);
					same_color_count = 0;
					pre_color = -1;
				}
			}
			if(same_color_count >= 5)
				score += _w3 + (same_color_count - 5);
		}
	}
	return score;
}

/*
 Evaluate masking results
 @param matrix the symbol matrix
 @param width the symbol matrix width
 @param height the symbol matrix height
 @param color_number the number of module colors
 @return the penalty score
*/
int evaluateMask(List<int> matrix, int width, int height, int color_number) {
	return applyRule1(matrix, width, height, color_number) + applyRule2(matrix, width, height) + applyRule3(matrix, width, height);
}

/*
 Mask the data modules in symbols
 @param enc the encode parameters
 @param mask_type the mask pattern reference
 @param masked the masked symbol matrix
 @param cp the code parameters
*/
void maskSymbols(jab_encode enc, int mask_type, List<int> masked, jab_code cp){
	for(int k=0; k<enc.symbol_number; k++) {
		int startx = 0, starty = 0;
		if(masked != null && cp != null) {
			//calculate the starting coordinates of the symbol matrix
			int col = jab_symbol_pos[enc.symbol_positions[k]].x - cp.min_x;
			int row = jab_symbol_pos[enc.symbol_positions[k]].y - cp.min_y;
			for(int c=0; c<col; c++)
				startx += cp.col_width[c];
			for(int r=0; r<row; r++)
				starty += cp.row_height[r];
		}
		int symbol_width = enc.symbols[k].side_size.x;
		int symbol_height= enc.symbols[k].side_size.y;

        //apply mask on the symbol
		for(int y=0; y<symbol_height; y++) {
			for(int x=0; x<symbol_width; x++) {
				int index = enc.symbols[k].matrix[y * symbol_width + x];
				if(enc.symbols[k].data_map[(y * symbol_width + x).toInt()] != 0) {
					switch(mask_type) {
						case 0:
							index ^= (x + y) % enc.color_number;
							break;
						case 1:
							index ^= x % enc.color_number;
							break;
						case 2:
							index ^= y % enc.color_number;
							break;
						case 3:
							index ^= ((x / 2 + y / 3) % enc.color_number).toInt();
							break;
						case 4:
							index ^= ((x / 3 + y / 2) % enc.color_number).toInt();
							break;
						case 5:
							index ^= (((x + y) / 2 + (x + y) / 3) % enc.color_number).toInt();
							break;
						case 6:
							index ^= ((x*x * y) % 7 + (2*x*x + 2*y) % 19) % enc.color_number;
							break;
						case 7:
							index ^= ((x * y*y) % 5 + (2*x + y*y) % 13) % enc.color_number;
							break;
					}
					if(masked != null && cp != null)
						masked[((y + starty) * cp.code_size.x + (x + startx)).toInt()] = index;
					else
						enc.symbols[k].matrix[y * symbol_width + x] = index;
				}
				else {
					if(masked != null && cp != null)
						masked[(y + starty) * cp.code_size.x + (x + startx)] = index; //copy non-data module
				}
			}
		}
	}
}

/*
 Mask modules
 @param enc the encode parameters
 @param cp the code parameters
 @return the mask pattern reference | -1 if fails
*/
int maskCode(jab_encode enc, jab_code cp) {
	int mask_type = 0;
	int min_penalty_score = 10000;

	//allocate memory for masked code
	var masked = List<int>.filled(cp.code_size.x * cp.code_size.y, -1); //set all bytes in masked as 0xFF //int *)malloc(cp.code_size.x * cp.code_size.y * sizeof(int));

	// memset(masked, -1, cp.code_size.x * cp.code_size.y * sizeof(int)); //set all bytes in masked as 0xFF

	//evaluate each mask pattern
	for(int t=0; t<NUMBER_OF_MASK_PATTERNS; t++) {
		int penalty_score = 0;
		maskSymbols(enc, t, masked, cp);
		//calculate the penalty score
		penalty_score = evaluateMask(masked, cp.code_size.x, cp.code_size.y, enc.color_number);

		if(penalty_score < min_penalty_score) {
			mask_type = t;
			min_penalty_score = penalty_score;
		}
	}

	//mask all symbols with the selected mask pattern
	maskSymbols(enc, mask_type, null, null);

	return mask_type;
}

/*
 Demask modules
 @param data the decoded data module values
 @param data_map the data module positions
 @param symbol_size the symbol size in module
 @param mask_type the mask pattern reference
 @param color_number the number of module colors
*/
void demaskSymbol(jab_data data, List<int> data_map, jab_vector2d symbol_size, int mask_type, int color_number) {
	int symbol_width = symbol_size.x;
	int symbol_height= symbol_size.y;
	int count = 0;
	for(int x=0; x<symbol_width; x++) {
		for(int y=0; y<symbol_height; y++) {
			if(data_map[y * symbol_width + x] == 0) {
				if(count > data.length -1) return;
				int index = data.data[count];
				switch(mask_type) {
					case 0:
						index ^= (x + y) % color_number;
						break;
					case 1:
						index ^= x % color_number;
						break;
					case 2:
						index ^= y % color_number;
						break;
					case 3:
						index ^= ((x / 2 + y / 3) % color_number).toInt();
						break;
					case 4:
						index ^= ((x / 3 + y / 2) % color_number).toInt();
						break;
					case 5:
						index ^= (((x + y) / 2 + (x + y) / 3) % color_number).toInt();
						break;
					case 6:
						index ^= ((x*x * y) % 7 + (2*x*x + 2*y) % 19) % color_number;
						break;
					case 7:
						index ^= ((x * y*y) % 5 + (2*x + y*y) % 13) % color_number;
						break;
				}
				data.data[count] = index;
				count++;
			}
		}
	}
}
