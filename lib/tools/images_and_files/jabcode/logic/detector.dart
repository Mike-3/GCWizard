/*
libjabcode - JABCode Encoding/Decoding Library

Copyright 2016 by Fraunhofer SIT. All rights reserved.
See LICENSE file for full terms of use and distribution.

Contact: Huajian Liu <liu@sit.fraunhofer.de>
			Waldemar Berchtold <waldemar.berchtold@sit.fraunhofer.de>

JABCode detector
 */

import 'dart:core';
import 'dart:math';
import 'dart:typed_data';
import 'package:tuple/tuple.dart';
import 'package:gc_wizard/tools/images_and_files/jabcode/logic/jabcode_h.dart';
import 'package:gc_wizard/tools/images_and_files/jabcode/logic/sample.dart';
import 'package:gc_wizard/tools/images_and_files/jabcode/logic/transform.dart';
import 'package:gc_wizard/tools/images_and_files/jabcode/logic/binarizer.dart';
import 'package:gc_wizard/tools/images_and_files/jabcode/logic/decoder.dart';
import 'package:gc_wizard/tools/images_and_files/jabcode/logic/encoder_h.dart';
import 'package:gc_wizard/tools/images_and_files/jabcode/logic/decoder_h.dart';
import 'package:gc_wizard/tools/images_and_files/jabcode/logic/detector_h.dart';

/*
 Check the proportion of layer sizes in finder pattern
 @param state_count the layer sizes in pixel
 @return item1 JAB_SUCCESS | JAB_FAILURE
 @return item2 module_size the module size
 */
Tuple2<int, double> _checkPatternCross(List<int> state_count) {
  int layer_number = 3;
  int inside_layer_size = 0;
  double module_size = 0.0;
  for(int i=1; i<layer_number+1; i++) {
    if(state_count[i] == 0) {
      return Tuple2<int, double>(JAB_FAILURE, module_size);
    }
    inside_layer_size += state_count[i];
  }

  double layer_size = inside_layer_size / 3.0;
  module_size = layer_size;
  double layer_tolerance = layer_size / 2.0;

	//layer size proportion must be n-1-1-1-m where n>1, m>1
	bool size_condition = (layer_size - state_count[1]).abs() < layer_tolerance &&
					 (layer_size - state_count[2]).abs() < layer_tolerance &&
					 (layer_size - state_count[3]).abs() < layer_tolerance &&
					 state_count[0] > 0.5 * layer_tolerance && //the two outside layers can be larger than layer_size
					 state_count[4] > 0.5 * layer_tolerance &&
					 (state_count[1] - state_count[3]).abs() < layer_tolerance; //layer 1 and layer 3 shall be of the same size

  return Tuple2<int, double>(size_condition ? JAB_SUCCESS : JAB_FAILURE, module_size);
}

/*
 Check if the input module sizes are the same
 @param size1 the first module size
 @param size2 the second module size
 @return JAB_SUCCESS | JAB_FAILURE
*/
bool _checkModuleSize2(double size1, double size2) {
	double mean= (size1 + size2) / 2.0;
	double tolerance = mean / 2.5;

  return (mean - size1).abs() < tolerance && (mean - size2).abs() < tolerance;
}

/*
 Find a candidate scanline of finder pattern
 @param ch the image channel
 @param row the row to be scanned
 @param col the column to be scanned
 @param start the start position
 @param end the end position
 @param center the center of the candidate scanline
 @param module_size the module size
 @param skip the number of pixels to be skipped in the next scan
 @return item1 JAB_SUCCESS | JAB_FAILURE
 @return item2 start the start position
 @return item3 end the end position
 @return item4 center the center of the candidate scanline
 @return item5 module_size the module size
 @return item6 skip the number of pixels to be skipped in the next scan
*/
Tuple6<int, int, int, double, double, int> _seekPattern(jab_bitmap ch, int row, int col, int start, int end, double center, double module_size, int skip) {
  int state_number = 5;
  int cur_state = 0;
  var state_count = List<int>.filled(5, 0);

  int min = start;
  int max = end;
  for(int p=min; p<max; p++) {
    //first pixel in a scanline
    if(p == min) {
        state_count[cur_state]++;
        start = p;
    } else {
      //previous pixel and current pixel
      int prev;
      int curr;
    if(row >= 0) {		//horizontal scan
      prev = ch.pixel[row*ch.width + (p-1)];
      curr = ch.pixel[row*ch.width + p];
    } else if(col >= 0)	{ //vertical scan
      prev = ch.pixel[(p-1)*ch.width + col];
      curr = ch.pixel[p*ch.width + col];
    } else {
      return Tuple6<int, int, int, double, double, int>(JAB_FAILURE, start, end, center, module_size, skip);
    }

        //the pixel has the same color as the preceding pixel
        if(curr == prev) {
            state_count[cur_state]++;
        }
        //the pixel has different color from the preceding pixel
        if(curr != prev || p == max-1) {
          //change state
          if(cur_state < state_number-1) {
            //check if the current state is valid
            if(state_count[cur_state] < 3) {
              if(cur_state == 0) {
                  state_count[cur_state]=1;
                  start = p;
              } else {
                //combine the current state to the previous one and continue the previous state
                state_count[cur_state-1] += state_count[cur_state];
                state_count[cur_state] = 0;
                cur_state--;
                state_count[cur_state]++;
              }
            } else {
              //enter the next state
              cur_state++;
              state_count[cur_state]++;
            }

          //find a candidate
          } else {
            if(state_count[cur_state] < 3) {
              //combine the current state to the previous one and continue the previous state
              state_count[cur_state-1] += state_count[cur_state];
              state_count[cur_state] = 0;
              cur_state--;
              state_count[cur_state]++;
              continue;
            }
            //check if it is a valid finder pattern
            var result = _checkPatternCross(state_count);
            if(result.item1 == JAB_SUCCESS) {
                module_size = result.item2;
                end = p+1;
                if(skip!=0)  skip = state_count[0];
                int end_pos;
                if(p == (max - 1) && curr == prev) {
                  end_pos = p + 1;
                } else {
                  end_pos = p;
                }
                center = (end_pos - state_count[4] - state_count[3]) - state_count[2] / 2.0;
                return Tuple6<int, int, int, double, double, int>(JAB_SUCCESS, start, end, center, module_size, skip);
            } else { //check failed, update state_count

              start += state_count[0];
              for(int k=0; k<state_number-1; k++) {
                  state_count[k] = state_count[k+1];
              }
              state_count[state_number-1] = 1;
              cur_state = state_number-1;
            }
          }
        }
      }
  }
  end = max;
  return Tuple6<int, int, int, double, double, int>(JAB_FAILURE, start, end, center, module_size, skip);
}

/*
 Find a candidate horizontal scanline of finder pattern
 @param row the bitmap row
 @param startx the start position
 @param endx the end position
 @param centerx the center of the candidate scanline
 @param module_size the module size
 @param skip the number of pixels to be skipped in the next scan
 @return item1 JAB_SUCCESS | JAB_FAILURE
 @return item2 startx the start position
 @return item3 endx the end position
 @return item4 centerx the center of the candidate scanline
 @return item5 module_size the module size
 @return item6 skip the number of pixels to be skipped in the next scan
*/
Tuple6<int, int, int, double, double, int> _seekPatternHorizontal(Uint8List row, int startx, int endx, double centerx, double module_size, int skip) {
  int state_number = 5;
  int cur_state = 0;
  var state_count = List<int>.filled(5, 0);

  int min = startx;
  int max = endx;
  for(int j=min; j<max; j++) {
    //first pixel in a scanline
    if(j == min) {
      state_count[cur_state]++;
      startx = j;
    } else {
      //the pixel has the same color as the preceding pixel
      if(row[j] == row[j-1]) {
        state_count[cur_state]++;
      }

      //the pixel has different color from the preceding pixel
      if(row[j] != row[j-1] || j == max-1) {
        //change state
        if(cur_state < state_number-1) {
          //check if the current state is valid
          if(state_count[cur_state] < 3) {
            if(cur_state == 0) {
              state_count[cur_state]=1;
              startx = j;
            } else {
              //combine the current state to the previous one and continue the previous state
              state_count[cur_state-1] += state_count[cur_state];
              state_count[cur_state] = 0;
              cur_state--;
              state_count[cur_state]++;
            }
          } else {
            //enter the next state
            cur_state++;
            state_count[cur_state]++;
          }

        //find a candidate
        } else {
          if(state_count[cur_state] < 3) {
            //combine the current state to the previous one and continue the previous state
            state_count[cur_state-1] += state_count[cur_state];
            state_count[cur_state] = 0;
            cur_state--;
            state_count[cur_state]++;
            continue;
          }
          //check if it is a valid finder pattern
          var result = _checkPatternCross(state_count);
          if(result.item1 == JAB_SUCCESS) {
            module_size = result.item2;
            endx = j+1;
            skip = state_count[0]; //if(skip != 0)
            int end;
            if(j == (max - 1) && row[j] == row[j-1]) {
              end = j + 1;
            } else {
              end = j;
            }
            centerx = (end - state_count[4] - state_count[3]) - state_count[2] / 2.0;
            return Tuple6<int, int, int, double, double, int>(JAB_SUCCESS, startx, endx, centerx, module_size, skip);

          } else { //check failed, update state_count
            startx += state_count[0];
            for(int k=0; k<state_number-1; k++) {
              state_count[k] = state_count[k+1];
            }

            state_count[state_number-1] = 1;
            cur_state = state_number-1;
          }
        }
      }
    }
  }
  endx = max;
  return Tuple6<int, int, int, double, double, int>(JAB_FAILURE, startx, endx, centerx, module_size, skip);
}

/*
 Crosscheck the finder pattern candidate in diagonal direction
 @param image the image bitmap
 @param type the finder pattern type
 @param module_size_max the maximal allowed module size
 @param module_size the module size in diagonal direction
 @param dir the finder pattern direction
 @param both_dir scan both diagonal scanlines
 @return item1 the number of confirmed diagonal scanlines
 @return item2 centerx the x coordinate of the finder pattern center
 @return item3 centery the y coordinate of the finder pattern center
*/
Tuple3<int, double, double> _crossCheckPatternDiagonal(jab_bitmap image, int type, double module_size_max, double centerx, double centery, double module_size, int dir, bool both_dir) {
  int state_number = 5;
  int state_middle = (state_number - 1) ~/ 2;

  int offset_x, offset_y;
  bool fix_dir = false;
  //if the direction is given, ONLY check the given direction
  if((dir) != 0) {
    if((dir) > 0) {
      offset_x = -1;
      offset_y = -1;
      dir = 1;
    } else {
      offset_x = 1;
      offset_y = -1;
      dir = -1;
    }
    fix_dir = true;
  } else {
    //for fp0 (and fp1 in 4 color mode), first check the diagonal at +45 degree
    if(type == FP0 || type == FP1) {
      offset_x = -1;
      offset_y = -1;
      dir = 1;

    //for fp2, fp3, (and fp1 in 2 color mode) first check the diagonal at -45 degree
    } else {
      offset_x = 1;
      offset_y = -1;
      dir = -1;
    }
  }

  int confirmed = 0;
  bool flag = false;
  int try_count = 0;
  double tmp_module_size = 0.0;
  do {
    flag = false;
    try_count++;

    int i = 0, j = 0, state_index = 0;
    var state_count = List<int>.filled(5, 0);
    int startx = centerx.toInt();
    int starty = centery.toInt();

    state_count[state_middle]++;
    state_index=0;
    for(j=1; (starty+j*offset_y)>=0 && (starty+j*offset_y)<image.height && (startx+j*offset_x)>=0 && (startx+j*offset_x)<image.width && state_index<=state_middle; j++) {
      if( image.pixel[(starty + j*offset_y)*image.width + (startx + j*offset_x)] == image.pixel[(starty + (j-1)*offset_y)*image.width + (startx + (j-1)*offset_x)] ) {
          state_count[state_middle - state_index]++;
      } else {
        if(state_index >0 && state_count[state_middle - state_index] < 3) {
          state_count[state_middle - (state_index-1)] += state_count[state_middle - state_index];
          state_count[state_middle - state_index] = 0;
          state_index--;
          state_count[state_middle - state_index]++;
        } else {
          state_index++;
          if(state_index > state_middle) {
            break;
          } else {
            state_count[state_middle - state_index]++;
          }
        }
      }
    }
    if(state_index < state_middle) {
      if(try_count == 1) {
        flag = true;
        offset_x = -offset_x;
        dir = -dir;
      } else {
        return Tuple3<int, double, double>(confirmed, centerx, centery);
      }
    }

    if(!flag) {
      state_index=0;
      for(i=1; (starty-i*offset_y)>=0 && (starty-i*offset_y)<image.height && (startx-i*offset_x)>=0 && (startx-i*offset_x)<image.width && state_index<=state_middle; i++) {
        if( image.pixel[(starty - i*offset_y)*image.width + (startx - i*offset_x)] == image.pixel[(starty - (i-1)*offset_y)*image.width + (startx - (i-1)*offset_x)] ) {
          state_count[state_middle + state_index]++;
        } else {
          if(state_index >0 && state_count[state_middle + state_index] < 3) {
            state_count[state_middle + (state_index-1)] += state_count[state_middle + state_index];
            state_count[state_middle + state_index] = 0;
            state_index--;
            state_count[state_middle + state_index]++;
          } else {
            state_index++;
            if(state_index > state_middle) {
              break;
            } else {
              state_count[state_middle + state_index]++;
            }
          }
        }
      }
      if(state_index < state_middle) {
        if(try_count == 1) {
          flag = true;
          offset_x = -offset_x;
          dir = -dir;
        } else {
          return Tuple3<int, double, double>(confirmed, centerx, centery);
        }
      }
    }

    if(!flag) {
    //check module size, if it is too big, assume it is a false positive
    var ret = _checkPatternCross(state_count);
    if((ret.item1 == JAB_SUCCESS) && (ret.item2 <= module_size_max)) {
      module_size = ret.item2;
      if(tmp_module_size > 0) {
        module_size = (module_size + tmp_module_size) / 2.0;
      } else {
        tmp_module_size = module_size;
      }

      //calculate the center x
      centerx = (startx+i - state_count[4] - state_count[3]) - state_count[2] / 2.0;
      //calculate the center y
      centery = (starty+i - state_count[4] - state_count[3]) - state_count[2] / 2.0;
      confirmed++;
      if( !both_dir || try_count == 2 || fix_dir) {
        if(confirmed == 2) {
          dir = 2;
        }
        return Tuple3<int, double, double>(confirmed, centerx, centery);
      }
    } else {
      offset_x = -offset_x;
      dir = -dir;
    }
  }
  }while(try_count < 2 && !fix_dir);

  return Tuple3<int, double, double>(confirmed, centerx, centery);
}

/*
 Crosscheck the finder pattern candidate in vertical direction
 @param image the image bitmap
 @param module_size_max the maximal allowed module size
 @param centerx the x coordinate of the finder pattern center
 @param centery the y coordinate of the finder pattern center
 @return item1 JAB_SUCCESS | JAB_FAILURE
 @return item2 centery the y coordinate of the finder pattern center
 @return item3 module_size the module size in vertical direction
*/
Tuple3<int, double, double> _crossCheckPatternVertical(jab_bitmap image, double module_size_max, double centerx, double centery) {
	int state_number = 5;
	int state_middle = (state_number - 1) ~/ 2;
  var state_count = List<int>.filled(5, 0);

  int centerx_int = centerx.toInt();
  int centery_int = centery.toInt();
  int i, state_index;
  double module_size = 0.0;

  state_count[1]++;
  state_index=0;
  for(i=1; i<=centery_int && state_index<=state_middle; i++) {
    if( image.pixel[(centery_int-i)*image.width + centerx_int] == image.pixel[(centery_int-(i-1))*image.width + centerx_int] ) {
      state_count[state_middle - state_index]++;
    } else {
      if(state_index > 0 && state_count[state_middle - state_index] < 3) {
        state_count[state_middle - (state_index-1)] += state_count[state_middle - state_index];
        state_count[state_middle - state_index] = 0;
        state_index--;
        state_count[state_middle - state_index]++;
      } else {
        state_index++;
        if(state_index > state_middle) {
          break;
        } else {
          state_count[state_middle - state_index]++;
        }
      }
    }
  }
  if(state_index < state_middle) {
    return Tuple3<int, double, double>(JAB_FAILURE, centery, module_size);
  }

  state_index=0;
  for(i=1; (centery_int+i)<image.height && state_index<=state_middle; i++) {
    if( image.pixel[(centery_int+i)*image.width + centerx_int] == image.pixel[(centery_int+(i-1))*image.width + centerx_int] ) {
      state_count[state_middle + state_index]++;
    } else {
      if(state_index > 0 && state_count[state_middle + state_index] < 3) {
        state_count[state_middle + (state_index-1)] += state_count[state_middle + state_index];
        state_count[state_middle + state_index] = 0;
        state_index--;
        state_count[state_middle + state_index]++;
      } else {
        state_index++;
        if(state_index > state_middle) {
          break;
        } else {
          state_count[state_middle + state_index]++;
        }
      }
    }
  }
  if(state_index < state_middle) {
    return Tuple3<int, double, double>(JAB_FAILURE, centery, module_size);
  }

  //check module size, if it is too big, assume it is a false positive
	var ret = _checkPatternCross(state_count);
  if((ret.item1 == JAB_SUCCESS) && (ret.item2  <= module_size_max)) { //module_size
    module_size = ret.item2;
    //calculate the center y
    centery = (centery_int + i - state_count[4] - state_count[3]) - state_count[2] / 2.0;
    return Tuple3<int, double, double>(JAB_SUCCESS, centery, module_size);
  }
  return Tuple3<int, double, double>(JAB_FAILURE, centery, module_size);
}

/*
 Crosscheck the finder pattern candidate in horizontal direction
 @param image the image bitmap
 @param module_size_max the maximal allowed module size
 @param centerx the x coordinate of the finder pattern center
 @param centery the y coordinate of the finder pattern center
 @return item1 JAB_SUCCESS | JAB_FAILURE
 @return item2 centerx the x coordinate of the finder pattern center
 @return item3 module_size the module size in horizontal direction
*/
Tuple3<int, double, double> _crossCheckPatternHorizontal(jab_bitmap image, double module_size_max, double centerx, double centery) {
  int state_number = 5;
  int state_middle = (state_number - 1) ~/ 2;
  var state_count = List<int>.filled(5, 0);

  int startx = centerx.toInt();
  int offset = centery.toInt() * image.width;
  int i, state_index;
	double module_size = 0.0;

  state_count[state_middle]++;
	state_index=0;
  for(i=1; i<=startx && state_index<=state_middle; i++) {
    if( image.pixel[offset + (startx - i)] == image.pixel[offset + (startx - (i-1))] ) {
        state_count[state_middle - state_index]++;
    } else {
      if(state_index > 0 && state_count[state_middle - state_index] < 3) {
        state_count[state_middle - (state_index-1)] += state_count[state_middle - state_index];
        state_count[state_middle - state_index] = 0;
        state_index--;
        state_count[state_middle - state_index]++;
      } else {
        state_index++;
        if(state_index > state_middle) {
          break;
        } else {
          state_count[state_middle - state_index]++;
        }
      }
    }
  }
  if(state_index < state_middle) {
    return Tuple3<int, double, double>(JAB_FAILURE, centerx, module_size);
  }

  state_index=0;
  for(i=1; (startx+i)<image.width && state_index<=state_middle; i++) {
    if( image.pixel[offset + (startx + i)] == image.pixel[offset + (startx + (i-1))] ) {
      state_count[state_middle + state_index]++;
    } else {
      if(state_index > 0 && state_count[state_middle + state_index] < 3) {
        state_count[state_middle + (state_index-1)] += state_count[state_middle + state_index];
        state_count[state_middle + state_index] = 0;
        state_index--;
        state_count[state_middle + state_index]++;
      } else {
        state_index++;
        if(state_index > state_middle) {
          break;
        } else {
          state_count[state_middle + state_index]++;
        }
      }
    }
  }
  if(state_index < state_middle) {
    return Tuple3<int, double, double>(JAB_FAILURE, centerx, module_size);
  }

  //check module size, if it is too big, assume it is a false positive
  var ret = _checkPatternCross(state_count);
  if((ret.item1 == JAB_SUCCESS) && (ret.item2 <= module_size_max)) { //module_size
		module_size = ret.item2;
    //calculate the center x
    centerx = (startx+i - state_count[4] - state_count[3]) - state_count[2] / 2.0;
    return Tuple3<int, double, double>(JAB_SUCCESS, centerx, module_size);
  }
  return Tuple3<int, double, double>(JAB_FAILURE, centerx, module_size);
}

/*
 Crosscheck the finder pattern color
 @param image the image bitmap
 @param color the expected module color
 @param module_size the module size
 @param module_number the number of modules that should be checked
 @param centerx the x coordinate of the finder pattern center
 @param centery the y coordinate of the finder pattern center
 @param dir the check direction
 @return JAB_SUCCESS | JAB_FAILURE
*/
int _crossCheckColor(jab_bitmap image, int color, int module_size, int module_number, int centerx, int centery, int dir) {
	int tolerance = 3;
	//horizontal
	if(dir == 0) {
		int length = module_size * (module_number - 1); //module number minus one for better tolerance
		int startx = ((centerx - length/2) < 0 ? 0 : (centerx - length/2)).toInt();
		int unmatch = 0;
		for(int j=startx; j<(startx+length) && j<image.width; j++) {
			if(image.pixel[centery * image.width + j] != color) {
			  unmatch++;
			} else {
				if(unmatch <= tolerance) unmatch = 0;
			}
			if(unmatch > tolerance)	return JAB_FAILURE;
		}
		return JAB_SUCCESS;
	}
	//vertical
	else if(dir == 1) {
		int length = module_size * (module_number - 1);
		int starty = ((centery - length/2) < 0 ? 0 : (centery - length/2)).toInt();
		int unmatch = 0;
		for(int i=starty; i<(starty+length) && i<image.height; i++) {
			if(image.pixel[image.width * i + centerx] != color) {
			  unmatch++;
			} else {
				if(unmatch <= tolerance) unmatch = 0;
			}
			if(unmatch > tolerance)	return JAB_FAILURE;
		}
		return JAB_SUCCESS;
	}
	//diagonal
	else if(dir == 2) {
		int offset = module_size * module_number ~/ (2.0 * 1.41421); // e.g. for FP, module_size * (5/(2*sqrt(2));
		int length = offset * 2;

		//one direction
		int unmatch = 0;
		int startx = (centerx - offset) < 0 ? 0 : (centerx - offset);
		int starty = (centery - offset) < 0 ? 0 : (centery - offset);
		for(int i=0; i<length && (starty+i)<image.height; i++) {
			if(image.pixel[image.width * (starty+i) + (startx+i)] != color) {
			  unmatch++;
			} else {
				if(unmatch <= tolerance) unmatch = 0;
			}
			if(unmatch > tolerance) break;
		}
		if(unmatch < tolerance) return JAB_SUCCESS;

		//the other direction
		unmatch = 0;
		startx = (centerx - offset) < 0 ? 0 : (centerx - offset);
		starty = (centery + offset) > (image.height - 1) ? (image.height - 1) : (centery + offset);
		for(int i=0; i<length && (starty-i)>=0; i++) {
			if(image.pixel[image.width * (starty-i) + (startx+i)] != color) {
			  unmatch++;
			} else {
				if(unmatch <= tolerance) unmatch = 0;
			}
			if(unmatch > tolerance) return JAB_FAILURE;
		}
		return JAB_SUCCESS;
	} else {
		// JAB_REPORT_ERROR(("Invalid direction"))
		return JAB_FAILURE;
	}
}

/*
 Crosscheck the finder pattern candidate in one channel
 @param ch the binarized color channel
 @param type the finder pattern type
 @param h_v the direction of the candidate scanline, 0:horizontal 1:vertical
 @param module_size_max the maximal allowed module size
 @param module_size the module size in all directions
 @param centerx the x coordinate of the finder pattern center
 @param centery the y coordinate of the finder pattern center
 @param dir the finder pattern direction
 @param dcc the diagonal crosscheck result
 @return item1 JAB_SUCCESS | JAB_FAILURE
 @return item2 module_size the module size in all directions
 @return item3 center  coordinate of the finder pattern center
 @return item4 dir the finder pattern direction
 @return item5 dcc the diagonal crosscheck result
*/
Tuple5<int, double, jab_point, int, int> _crossCheckPatternCh(jab_bitmap ch, int type, int h_v, double module_size_max, double module_size, double centerx, double centery, int dir, int dcc) {
	double module_size_v = 0.0;
	double module_size_h = 0.0;
	double module_size_d = 0.0;

	if(h_v == 0) {
		int vcc = JAB_FAILURE;
		var result = _crossCheckPatternVertical(ch, module_size_max, centerx, centery);
		centery = result.item2;
		var module_size_v = result.item3;
		if(result.item1 == JAB_SUCCESS) {
			vcc = JAB_SUCCESS;
			result = _crossCheckPatternHorizontal(ch, module_size_max, centerx, centery);
			centerx = result.item2;
			module_size_h = result.item3;
			if(result.item1 == JAB_FAILURE) {
			  return Tuple5<int, double, jab_point, int, int>(JAB_FAILURE, module_size, jab_point(centerx, centery), dir, dcc);
			}
		}
    result = _crossCheckPatternDiagonal(ch, type, module_size_max, centerx, centery, module_size_d, dir, vcc == JAB_SUCCESS ? false:true);
    dcc = result.item1;
    centerx = result.item2;
    centery = result.item3;
		if(vcc == JAB_SUCCESS && dcc == JAB_SUCCESS) {
			module_size = (module_size_v + module_size_h + module_size_d) / 3.0;
      return Tuple5<int, double, jab_point, int, int>(JAB_SUCCESS, module_size, jab_point(centerx, centery), dir, dcc);
		} else if(dcc == 2) {
      var result = _crossCheckPatternHorizontal(ch, module_size_max, centerx, centery);
      centerx = result.item2;
      module_size_h=result.item3;
			if(result.item1 == JAB_FAILURE) {
			  return Tuple5<int, double, jab_point, int, int>(JAB_FAILURE, module_size, jab_point(centerx, centery), dir, dcc);
			}
			module_size = (module_size_h + module_size_d * 2.0) / 3.0;
			return Tuple5<int, double, jab_point, int, int>(JAB_SUCCESS, module_size, jab_point(centerx, centery), dir, dcc);
		}
	} else {
		int hcc = JAB_FAILURE;
    var result = _crossCheckPatternHorizontal(ch, module_size_max, centerx, centery);
    centerx = result.item2;
    module_size_h=result.item3;
		if(result.item1 == JAB_SUCCESS) {
			hcc = JAB_SUCCESS;
      var result = _crossCheckPatternVertical(ch, module_size_max, centerx, centery);
      centery = result.item2;
      module_size_v=result.item3;
      if(result.item1 == JAB_FAILURE) {
        return Tuple5<int, double, jab_point, int, int>(JAB_FAILURE, module_size, jab_point(centerx, centery), dir, dcc);
      }
		}
    result = _crossCheckPatternDiagonal(ch, type, module_size_max, centerx, centery, module_size_d, dir, hcc == JAB_SUCCESS ? false:true);
    dcc = result.item1;
    centerx = result.item2;
    centery = result.item3;
    if(hcc == JAB_SUCCESS && dcc == JAB_SUCCESS) {
      module_size = (module_size_v + module_size_h + module_size_d) / 3.0;
      return Tuple5<int, double, jab_point, int, int>(JAB_SUCCESS, module_size, jab_point(centerx, centery), dir, dcc);
    } else if(dcc == 2) {
      var result = _crossCheckPatternVertical(ch, module_size_max, centerx, centery);
      centery = result.item2;
      module_size_v=result.item3;
      if(result.item1 == JAB_FAILURE) {
        return Tuple5<int, double, jab_point, int, int>(JAB_FAILURE, module_size, jab_point(centerx, centery), dir, dcc);
      }
      module_size = (module_size_v + module_size_d * 2.0) / 3.0;
      return Tuple5<int, double, jab_point, int, int>(JAB_SUCCESS, module_size, jab_point(centerx, centery), dir, dcc);
    }
	}
	return Tuple5<int, double, jab_point, int, int>(JAB_FAILURE, module_size, jab_point(centerx, centery), dir, dcc);
}

/*
 Crosscheck the finder pattern candidate
 @param ch the binarized color channels of the image
 @param fp the finder pattern
 @param h_v the direction of the candidate scanline, 0:horizontal 1:vertical
 @return JAB_SUCCESS | JAB_FAILURE
*/
int _crossCheckPattern(List<jab_bitmap> ch, jab_finder_pattern fp, int h_v) {
  double module_size_max = fp.module_size * 2.0;

  //check g channel
	double module_size_g = 0.0;
  double centerx_g = fp.center.x;
  double centery_g = fp.center.y;
  int dir_g = 0;
  int dcc_g = 0;
  var result = _crossCheckPatternCh(ch[1], fp.type, h_v, module_size_max, module_size_g, centerx_g, centery_g, dir_g, dcc_g);
  module_size_g = result.item2;
  centerx_g = result.item3.x;
  centery_g = result.item3.y;
  dir_g = result.item4;
  dcc_g = result.item5;
  if(result.item1 == JAB_FAILURE) {
    return JAB_FAILURE;
  }

	//Finder Pattern FP1 and FP2
  if(fp.type == FP1 || fp.type == FP2) {
		//check r channel
		double module_size_r = 0.0;
		double centerx_r = fp.center.x;
		double centery_r = fp.center.y;
		int dir_r = 0;
		int dcc_r = 0;

    var result = _crossCheckPatternCh(ch[0], fp.type, h_v, module_size_max, module_size_r, centerx_r, centery_r, dir_r, dcc_r);
    module_size_r = result.item2;
    centerx_r = result.item3.x;
    centery_r = result.item3.y;
    dir_r = result.item4;
    dcc_r = result.item5;
		if(result.item1 == JAB_FAILURE) {
		  return JAB_FAILURE;
		}

		//module size must be consistent
		if(!_checkModuleSize2(module_size_r, module_size_g)) {
		  return JAB_FAILURE;
		}
		fp.module_size = (module_size_r + module_size_g) / 2.0;
		fp.center = jab_point((centerx_r + centerx_g) / 2.0,(centery_r + centery_g) / 2.0);

		//check b channel
		int core_color_in_blue_channel = jab_default_palette[FP2_CORE_COLOR * 3 + 2];
		if(_crossCheckColor(ch[2], core_color_in_blue_channel, fp.module_size.toInt(), 5, fp.center.x.toInt(), fp.center.y.toInt(), 0)== JAB_FAILURE) {
		  return JAB_FAILURE;
		}
		if(_crossCheckColor(ch[2], core_color_in_blue_channel, fp.module_size.toInt(), 5, fp.center.x.toInt(), fp.center.y.toInt(), 1)== JAB_FAILURE) {
		  return JAB_FAILURE;
		}
		if(_crossCheckColor(ch[2], core_color_in_blue_channel, fp.module_size.toInt(), 5, fp.center.x.toInt(), fp.center.y.toInt(), 2)== JAB_FAILURE) {
		  return JAB_FAILURE;
		}

		if(dcc_r == 2 || dcc_g == 2) {
		  fp.direction = 2;
		} else {
		  fp.direction = (dir_r + dir_g) > 0 ? 1 : -1;
		}
	}

	//Finder Pattern FP0 and FP3
	if(fp.type == FP0 || fp.type == FP3) {
		//check b channel
		double module_size_b = 0.0;
		double centerx_b = fp.center.x;
		double centery_b = fp.center.y;
		int dir_b = 0;
		int dcc_b = 0;
    var result = _crossCheckPatternCh(ch[2], fp.type, h_v, module_size_max, module_size_b, centerx_b, centery_b, dir_b, dcc_b);
    module_size_b = result.item2;
    centerx_b = result.item3.x;
    centery_b = result.item3.y;
    dir_b = result.item4;
    dcc_b = result.item5;
		if(result.item1 == JAB_FAILURE) {
		  return JAB_FAILURE;
		}

		//module size must be consistent
		if(!_checkModuleSize2(module_size_g, module_size_b)) {
		  return JAB_FAILURE;
		}
		fp.module_size = (module_size_g + module_size_b) / 2.0;
		fp.center = jab_point((centerx_g + centerx_b) / 2.0, (centery_g + centery_b) / 2.0);

		//check r channel
		int core_color_in_red_channel = jab_default_palette[FP3_CORE_COLOR * 3 + 0];
		if(_crossCheckColor(ch[0], core_color_in_red_channel, fp.module_size.toInt(), 5, fp.center.x.toInt(), fp.center.y.toInt().toInt(), 0)== JAB_FAILURE) {
		  return JAB_FAILURE;
		}
		if(_crossCheckColor(ch[0], core_color_in_red_channel, fp.module_size.toInt(), 5, fp.center.x.toInt(), fp.center.y.toInt().toInt(), 1)== JAB_FAILURE) {
		  return JAB_FAILURE;
		}
		if(_crossCheckColor(ch[0], core_color_in_red_channel, fp.module_size.toInt(), 5, fp.center.x.toInt(), fp.center.y.toInt().toInt(), 2)== JAB_FAILURE) {
		  return JAB_FAILURE;
		}

		if(dcc_g == 2 || dcc_b == 2) {
		  fp.direction = 2;
		} else {
		  fp.direction = (dir_g + dir_b) > 0 ? 1 : -1;
		}
	}

	return JAB_SUCCESS;
}

/*
 Save a found alignment pattern into the alignment pattern list
 @param ap the alignment pattern
 @param aps the alignment pattern list
 @param counter the number of alignment patterns in the list
 @return item1 -1 if added as a new alignment pattern | the alignment pattern index if combined with an existing pattern
 @return item2 counter the number of alignment patterns in the list
*/
Tuple2<int, int> _saveAlignmentPattern(jab_alignment_pattern ap, List<jab_alignment_pattern> aps, int counter) {
  //combine the alignment patterns at the same position with the same size
  for(int i=0; i<counter; i++) {
    if(aps[i].found_count > 0) {
      if( (ap.center.x - aps[i].center.x).abs() <= ap.module_size && (ap.center.y - aps[i].center.y).abs() <= ap.module_size &&
          ((ap.module_size - aps[i].module_size).abs() <= aps[i].module_size || (ap.module_size - aps[i].module_size).abs() <= 1.0) &&
          ap.type == aps[i].type )
      {
        aps[i].center.x = (aps[i].found_count * aps[i].center.x + ap.center.x) / (aps[i].found_count + 1);
        aps[i].center.y = (aps[i].found_count * aps[i].center.y + ap.center.y) / (aps[i].found_count + 1);
        aps[i].module_size = (aps[i].found_count * aps[i].module_size + ap.module_size) / (aps[i].found_count + 1);
        aps[i].found_count++;
        return Tuple2<int, int>(i, counter);
      }
    }
  }
  //add a new alignment pattern
  aps[counter] = ap;
  counter++;
  return Tuple2<int, int>(-1, counter);
}

/*
 Save a found finder pattern into the finder pattern list
 @param fp the finder pattern
 @param fps the finder pattern list
 @param counter the number of finder patterns in the list
 @param fp_type_count the number of finder pattern types in the list
*/
int _saveFinderPattern(jab_finder_pattern fp, List<jab_finder_pattern> fps, int counter, List<int> fp_type_count) {
  //combine the finder patterns at the same position with the same size
  for(int i=0; i<counter; i++) {
    if(fps[i].found_count > 0) {
      if( (fp.center.x - fps[i].center.x).abs() <= fp.module_size && (fp.center.y - fps[i].center.y).abs() <= fp.module_size &&
          ((fp.module_size - fps[i].module_size).abs() <= fps[i].module_size || (fp.module_size - fps[i].module_size).abs() <= 1.0) &&
          fp.type == fps[i].type)
        {
          fps[i].center = jab_point((fps[i].found_count * fps[i].center.x + fp.center.x) / (fps[i].found_count + 1),
                                    (fps[i].found_count * fps[i].center.y + fp.center.y) / (fps[i].found_count + 1));
          fps[i].module_size = (fps[i].found_count * fps[i].module_size + fp.module_size) / (fps[i].found_count + 1);
          fps[i].found_count++;
          fps[i].direction += fp.direction;
          return counter;
        }
    }
  }
  //add a new finder pattern
  fps[counter] = fp;
  // ToDo unklar
  counter++;
  fp_type_count[fp.type]++;
  return counter;
}

/*
 Find the finder pattern with most detected times
 @param fps the finder pattern list
 @param fp_count the number of finder patterns in the list
 @return finder pattern
*/
jab_finder_pattern _getBestPattern(List<jab_finder_pattern> fps, int fp_count) {
  int counter = 0;
  double total_module_size = 0;
  for(int i=0; i<fp_count; i++) {
    if(fps[i].found_count > 0) {
      counter++;
      total_module_size += fps[i].module_size;
    }
  }
  double mean = total_module_size / counter;

  int max_found_count = 0;
  double min_diff = 100;
  int max_found_count_index = 0;
  for(int i=0; i<fp_count; i++) {
    if(fps[i].found_count > 0) {
      if(fps[i].found_count > max_found_count) {
        max_found_count = fps[i].found_count;
        max_found_count_index = i;
        min_diff = (fps[i].module_size - mean).abs();
      } else if(fps[i].found_count == max_found_count) {
        if((fps[i].module_size - mean).abs() < min_diff ) {
          max_found_count_index = i;
          min_diff = (fps[i].module_size - mean).abs();
        }
      }
    }
  }
  jab_finder_pattern fp = fps[max_found_count_index];
  fps[max_found_count_index].found_count = 0;
  return fp;
}

/*
 Select the best finder patterns out of the list
 @param fps the finder pattern list
 @param fp_count the number of finder patterns in the list
 @param fp_type_count the number of each finder pattern type
 @return the number of missing finder pattern types
*/
int _selectBestPatterns(List<jab_finder_pattern> fps, int fp_count, List<int> fp_type_count) {
  //classify finder patterns into four types
  var fps0 = List<jab_finder_pattern>.filled(fp_type_count[FP0], jab_finder_pattern());
  var fps1 = List<jab_finder_pattern>.filled(fp_type_count[FP1], jab_finder_pattern());
  var fps2 = List<jab_finder_pattern>.filled(fp_type_count[FP2], jab_finder_pattern());
  var fps3 = List<jab_finder_pattern>.filled(fp_type_count[FP3], jab_finder_pattern());
  int counter0 = 0, counter1 = 0, counter2 = 0, counter3 = 0;

  for(int i=0; i<fp_count; i++) {
    //abandon the finder patterns which are founds less than 3 times,
    //which means a module shall not be smaller than 3 pixels.
    if(fps[i].found_count < 3) continue;
    switch (fps[i].type) {
      case FP0:
        fps0[counter0++] = fps[i];
        break;
      case FP1:
        fps1[counter1++] = fps[i];
        break;
      case FP2:
        fps2[counter2++] = fps[i];
        break;
      case FP3:
        fps3[counter3++] = fps[i];
        break;
    }
  }

	//set fp0
  if(counter0 > 1) {
    fps[0] = _getBestPattern(fps0, counter0);
  } else if(counter0 == 1) {
    fps[0] = fps0[0];
  } else {
	  fps[0] = jab_finder_pattern();
	}
  //set fp1
  if(counter1 > 1) {
    fps[1] = _getBestPattern(fps1, counter1);
  } else if(counter1 == 1) {
    fps[1] = fps1[0];
  } else {
	  fps[1] = jab_finder_pattern();
	}
	//set fp2
  if(counter2 > 1) {
    fps[2] = _getBestPattern(fps2, counter2);
  } else if(counter2 == 1) {
	  fps[2] = fps2[0];
	} else {
	  fps[2] = jab_finder_pattern();
	}
  //set fp3
  if(counter3 > 1) {
    fps[3] = _getBestPattern(fps3, counter3);
  } else if(counter3 == 1) {
	  fps[3] = fps3[0];
	} else {
	  fps[3] = jab_finder_pattern();
	}

  //if the found-count of a FP is smaller than the half of the max-found-count, abandon it
  int max_found_count = 0;
  for(int i=0; i<4; i++)
  {
      if(fps[i].found_count > max_found_count)
      {
          max_found_count = fps[i].found_count;
      }
  }
  for(int i=0; i<4; i++) {
    if(fps[i].found_count > 0) {
      if(fps[i].found_count < (0.5*max_found_count)) {
        fps[i] = jab_finder_pattern();
      }
    }
  }

	//check how many finder patterns are not found
	int missing_fp_count = 0;
	for(int i=0; i<4; i++) {
		if(fps[i].found_count == 0) {
		  missing_fp_count++;
		}
	}
	return missing_fp_count;
}

/*
 Scan the image vertically
 @param ch the binarized color channels of the image
 @param min_module_size the minimal module size
 @param fps the found finder patterns
 @param fp_type_count the number of found finder patterns for each type
 @param total_finder_patterns the number of totally found finder patterns
 @return total_finder_patterns the number of totally found finder patterns
*/
int _scanPatternVertical(List<jab_bitmap> ch, int min_module_size, List<jab_finder_pattern> fps, List<int> fp_type_count, int total_finder_patterns) {
  bool done = false;

  for(int j=0; j<ch[0].width && done == false; j+=min_module_size) {
    int starty = 0;
    int endy = ch[0].height;
    int skip = 0;

    do {
      int type_r = 0, type_g = 0, type_b = 0;
      double centery_r = 0.0, centery_g = 0.0, centery_b = 0.0;
      double module_size_r = 0.0, module_size_g = 0.0, module_size_b = 0.0;
      int finder_pattern1_found = JAB_FAILURE;
      int finder_pattern2_found = JAB_FAILURE;

      starty += skip;
      endy = ch[0].height;
      //green channel
      var result = _seekPattern(ch[1], -1, j, starty, endy, centery_g, module_size_g, skip);
      starty= result.item2;
      endy= result.item3;
      centery_g= result.item4;
      module_size_g= result.item5;
      skip= result.item6;
      if(result.item1 == JAB_SUCCESS) {
        type_g = ch[1].pixel[((centery_g)*ch[0].width + j).toInt()] > 0 ? 255 : 0;

        centery_r = centery_g;
        centery_b = centery_g;
        //check blue channel for Finder Pattern UL and LL
        var result = _crossCheckPatternVertical(ch[2], module_size_g*2, j.toDouble(), centery_b);
        centery_b = result.item2;
        module_size_b = result.item3;

        if(result.item1 == JAB_SUCCESS) {
          type_b = ch[2].pixel[((centery_b)*ch[2].width + j).toInt()] > 0 ? 255 : 0;
          //check red channel
          module_size_r = module_size_g;
          int core_color_in_red_channel = jab_default_palette[FP3_CORE_COLOR * 3 + 0];
          if(_crossCheckColor(ch[0], core_color_in_red_channel, module_size_r.toInt(), 5, j, centery_r.toInt(), 1)== JAB_SUCCESS) {
            type_r = 0;
            finder_pattern1_found = JAB_SUCCESS;
          }

        //check red channel for Finder Pattern UR and LR
        } else {
          var result = _crossCheckPatternVertical(ch[0], module_size_g*2, j.toDouble(), centery_r);
          centery_r = result.item2;
          module_size_r =result.item3;

          if(result.item1 == JAB_SUCCESS) {
            type_r = ch[0].pixel[((centery_r) * ch[0].width + j).toInt()] > 0 ? 255 : 0;
            //check blue channel
            module_size_b = module_size_g;
            int core_color_in_blue_channel = jab_default_palette[FP2_CORE_COLOR * 3 + 2];
            if (_crossCheckColor(ch[2], core_color_in_blue_channel, module_size_b.toInt(), 5, j, centery_b.toInt(), 1) == JAB_SUCCESS) {
              type_b = 0;
              finder_pattern2_found = JAB_SUCCESS;
            }
          }
        }
        //finder pattern candidate found
        if(finder_pattern1_found == JAB_SUCCESS || finder_pattern2_found == JAB_SUCCESS) {
          var fp = jab_finder_pattern();
          fp.center = jab_point(j.toDouble(), fp.center.y);
          fp.found_count = 1;
          if(finder_pattern1_found == JAB_SUCCESS) {
            if(!_checkModuleSize2(module_size_g, module_size_b)) continue;
            fp.center = jab_point(fp.center.x, (centery_g + centery_b) / 2.0);
            fp.module_size = (module_size_g + module_size_b) / 2.0;
            if( type_r == jab_default_palette[FP0_CORE_COLOR * 3] &&
              type_g == jab_default_palette[FP0_CORE_COLOR * 3 + 1] &&
              type_b == jab_default_palette[FP0_CORE_COLOR * 3 + 2])
            {
              fp.type = FP0;	//candidate for fp0
            } else if(type_r == jab_default_palette[FP3_CORE_COLOR * 3] &&
                type_g == jab_default_palette[FP3_CORE_COLOR * 3 + 1] &&
                type_b == jab_default_palette[FP3_CORE_COLOR * 3 + 2])
            {
              fp.type = FP3;	//candidate for fp3
            } else {
              continue;		//invalid type
            }
          } else if(finder_pattern2_found == JAB_SUCCESS) {
            if(!_checkModuleSize2(module_size_r, module_size_g)) continue;
            fp.center = jab_point(fp.center.x, (centery_r + centery_g) / 2.0);
            fp.module_size = (module_size_r + module_size_g) / 2.0;
            if(type_r == jab_default_palette[FP1_CORE_COLOR * 3] &&
               type_g == jab_default_palette[FP1_CORE_COLOR * 3 + 1] &&
               type_b == jab_default_palette[FP1_CORE_COLOR * 3 + 2])
            {
              fp.type = FP1;	//candidate for fp1
            } else if(type_r == jab_default_palette[FP2_CORE_COLOR * 3] &&
                type_g == jab_default_palette[FP2_CORE_COLOR * 3 + 1] &&
                type_b == jab_default_palette[FP2_CORE_COLOR * 3 + 2])
            {
              fp.type = FP2;	//candidate for fp2
            } else {
              continue;		//invalid type
            }
          }
          //cross check
          if( _crossCheckPattern(ch, fp, 1) == JAB_SUCCESS) {
            total_finder_patterns = _saveFinderPattern(fp, fps, total_finder_patterns, fp_type_count);
            if(total_finder_patterns >= (MAX_FINDER_PATTERNS - 1) ) {
              done = true;
              break;
            }
          }
        }
      }
    } while(starty < ch[0].height && endy < ch[0].height);
  }
  return total_finder_patterns;
}

/*
 Search for the missing finder pattern at the estimated position
 @param bitmap the image bitmap
 @param fps the finder patterns
 @param miss_fp_index the index of the missing finder pattern
*/
void _seekMissingFinderPattern(jab_bitmap bitmap, List<jab_finder_pattern> fps, int miss_fp_index) {
	//determine the search area
	double radius = fps[miss_fp_index].module_size * 5;	//search radius
	int start_x = (fps[miss_fp_index].center.x - radius) >= 0 ? (fps[miss_fp_index].center.x - radius).toInt() : 0;
	int start_y = (fps[miss_fp_index].center.y - radius) >= 0 ? (fps[miss_fp_index].center.y - radius).toInt()  : 0;
	int end_x	  = (fps[miss_fp_index].center.x + radius) <= (bitmap.width - 1) ? (fps[miss_fp_index].center.x + radius).toInt()  : (bitmap.width - 1);
	int end_y   = (fps[miss_fp_index].center.y + radius) <= (bitmap.height- 1) ? (fps[miss_fp_index].center.y + radius).toInt()  : (bitmap.height- 1);
	int area_width = end_x - start_x;
	int area_height= end_y - start_y;

	var rgb = List<jab_bitmap>.filled(3, jab_bitmap());
	for(int i=0; i<3; i++) {
		// rgb[i] = jab_bitmap(); // (jab_bitmap*)calloc(1, sizeof(jab_bitmap) + area_height*area_width*sizeof(jab_byte));

		rgb[i].width = area_width;
		rgb[i].height= area_height;
		rgb[i].bits_per_channel = 8;
		rgb[i].bits_per_pixel = 8;
		rgb[i].channel_count = 1;
	}

	//calculate average pixel value
	int bytes_per_pixel = bitmap.bits_per_pixel ~/ 8;
  int bytes_per_row = bitmap.width * bytes_per_pixel;
	var pixel_sum = List<double>.filled(3, 0);
	var pixel_ave = List<double>.filled(3, 0);
	for(int i=start_y; i<end_y; i++) {
		for(int j=start_x; j<end_x; j++) {
			int offset = i * bytes_per_row + j * bytes_per_pixel;
			pixel_sum[0] += bitmap.pixel[offset + 0];
			pixel_sum[1] += bitmap.pixel[offset + 1];
			pixel_sum[2] += bitmap.pixel[offset + 2];
		}
	}
	pixel_ave[0] = pixel_sum[0] / (area_width * area_height);
	pixel_ave[1] = pixel_sum[1] / (area_width * area_height);
	pixel_ave[2] = pixel_sum[2] / (area_width * area_height);

	//quantize the pixels inside the search area to black, cyan and yellow
	for(int i=start_y, y=0; i<end_y; i++, y++) {
		for(int j=start_x, x=0; j<end_x; j++, x++) {
			int offset = i * bytes_per_row + j * bytes_per_pixel;
			//check black pixel
			if(bitmap.pixel[offset + 0] < pixel_ave[0] && bitmap.pixel[offset + 1] < pixel_ave[1] && bitmap.pixel[offset + 2] < pixel_ave[2]) {
				rgb[0].pixel[y*area_width + x] = 0;
				rgb[1].pixel[y*area_width + x] = 0;
				rgb[2].pixel[y*area_width + x] = 0;
			} else if(bitmap.pixel[offset + 0] < bitmap.pixel[offset + 2]) {	//R < B
				rgb[0].pixel[y*area_width + x] = 0;
				rgb[1].pixel[y*area_width + x] = 255;
				rgb[2].pixel[y*area_width + x] = 255;
			} else {	 														//R > B
				rgb[0].pixel[y*area_width + x] = 255;
				rgb[1].pixel[y*area_width + x] = 255;
				rgb[2].pixel[y*area_width + x] = 0;
			}
		}
	}

	//set the core type of the expected finder pattern
	int exp_type_r=0, exp_type_g=0, exp_type_b=0;
	switch(miss_fp_index) {
	case 0:
	case 1:
		exp_type_r = 0;
		exp_type_g = 0;
		exp_type_b = 0;
		break;
	case 2:
		exp_type_r = 255;
		exp_type_g = 255;
		exp_type_b = 0;
		break;
	case 3:
		exp_type_r = 0;
		exp_type_g = 255;
		exp_type_b = 255;
		break;
	}
	//search for the missing finder pattern
	var fps_miss = List<jab_finder_pattern>.filled (MAX_FINDER_PATTERNS, jab_finder_pattern()); //calloc(MAX_FINDER_PATTERNS, sizeof(jab_finder_pattern));

  int total_finder_patterns = 0;
  bool done = false;
  var fp_type_count = List<int>.filled(4, 0);

	for(int i=0; i<area_height && done == false; i++) {
    //get row
    var row_r = rgb[0].pixel.sublist(i*rgb[0].width); //rgb[0].pixel + i*rgb[0].width;
    var row_g = rgb[1].pixel.sublist(i*rgb[1].width); //rgb[1].pixel + i*rgb[1].width;
    var row_b = rgb[2].pixel.sublist(i*rgb[2].width); //rgb[2].pixel + i*rgb[2].width;

    int startx = 0;
    int endx = rgb[0].width;
    int skip = 0;

    do {
      var fp = jab_finder_pattern();

      int type_r = 0, type_g = 0, type_b = 0;
      double centerx_r = 0.0, centerx_g = 0.0, centerx_b = 0.0;
      double module_size_r = 0.0, module_size_g = 0.0, module_size_b = 0.0;
      int finder_pattern_found = JAB_FAILURE;

      startx += skip;
      endx = rgb[0].width;
      //green channel
      var result = _seekPatternHorizontal(row_g, startx, endx, centerx_g, module_size_g, skip);
      startx = result.item2;
      endx = result.item3;
      centerx_g = result.item4;
      module_size_g = result.item5;
      skip = result.item6;
      if(result.item1 == JAB_SUCCESS) {
        type_g = row_g[(centerx_g).toInt()] > 0 ? 255 : 0;
        if(type_g != exp_type_g) continue;

        centerx_r = centerx_g;
        centerx_b = centerx_g;
        switch(miss_fp_index) {
          case 0:
          case 3:
            //check blue channel for Finder Pattern UL and LL
            var result = _crossCheckPatternHorizontal(rgb[2], module_size_g*2, centerx_b, i.toDouble());
            centerx_b = result.item2;
            module_size_b = result.item3;

            if(result.item1== JAB_SUCCESS) {
              type_b = row_b[(centerx_b).toInt()] > 0 ? 255 : 0;
              if(type_b != exp_type_b) continue;
              //check red channel
              module_size_r = module_size_g;
              int core_color_in_red_channel = jab_default_palette[FP3_CORE_COLOR * 3 + 0];
              if(_crossCheckColor(rgb[0], core_color_in_red_channel, module_size_r.toInt(), 5, centerx_r.toInt(), i, 0) == JAB_SUCCESS) {
                type_r = 0;
                finder_pattern_found = JAB_SUCCESS;
              }
            }
            if(finder_pattern_found == JAB_SUCCESS) {
              if(!_checkModuleSize2(module_size_g, module_size_b)) continue;
              fp.center = jab_point((centerx_g + centerx_b) / 2.0, fp.center.y);
              fp.module_size = (module_size_g + module_size_b) / 2.0;
            }
            break;
          case 1:
          case 2:
            //check red channel for Finder Pattern UR and LR
            var result = _crossCheckPatternHorizontal(rgb[0], module_size_g*2, centerx_r, i.toDouble());
            centerx_r= result.item2;
            module_size_r= result.item3;
            if(result.item1== JAB_SUCCESS) {
              type_r = row_r[(centerx_r).toInt()] > 0 ? 255 : 0;
              if(type_r != exp_type_r) continue;
              //check blue channel
              module_size_b = module_size_g;
              int core_color_in_blue_channel = jab_default_palette[FP2_CORE_COLOR * 3 + 2];
              if(_crossCheckColor(rgb[2], core_color_in_blue_channel, module_size_b.toInt(), 5, centerx_b.toInt(), i, 0) == JAB_SUCCESS) {
                type_b = 0;
                finder_pattern_found = JAB_SUCCESS;
              }
            }
            if(finder_pattern_found == JAB_SUCCESS) {
              if(!_checkModuleSize2(module_size_r, module_size_g)) continue;
              fp.center =  jab_point((centerx_r + centerx_g) / 2.0, fp.center.y);
              fp.module_size = (module_size_r + module_size_g) / 2.0;
            }
          break;
        }
        //finder pattern candidate found
        if(finder_pattern_found == JAB_SUCCESS) {
          fp.center = jab_point(fp.center.x,i.toDouble());
          fp.found_count = 1;
          fp.type = miss_fp_index;
          //cross check
          if( _crossCheckPattern(rgb, fp, 0) == JAB_SUCCESS) {
            //combine the finder patterns at the same position with the same size
            total_finder_patterns = _saveFinderPattern(fp, fps_miss, total_finder_patterns, fp_type_count);
            if(total_finder_patterns >= (MAX_FINDER_PATTERNS - 1)) {
              done = true;
              break;
            }
          }
        }
      }
    } while(startx < rgb[0].width && endx < rgb[0].width);
  }
	//if the missing FP is found, get the best found
	if(total_finder_patterns > 0) {
    int max_found = 0;
    int max_index = 0;
    for(int i=0; i<total_finder_patterns; i++) {
      if(fps_miss[i].found_count > max_found) {
        max_found = fps_miss[i].found_count;
        max_index = i;
      }
    }
    fps[miss_fp_index] = fps_miss[max_index];
    //recover the coordinates in bitmap
    fps[miss_fp_index].center = jab_point(fps[miss_fp_index].center.x + start_x,
                                          fps[miss_fp_index].center.y + start_y);
  }
}

/*
 Find the master symbol in the image
 @param bitmap the image bitmap
 @param ch the binarized color channels of the image
 @param mode the detection mode
 @return item1 the finder pattern list | NULL
 @return item2 status the detection status
*/
Tuple2<int, List<jab_finder_pattern>> _findMasterSymbol(jab_bitmap bitmap, List<jab_bitmap> ch, jab_detect_mode mode) {
	int status;
  //suppose the code size is minimally 1/4 image size
  int min_module_size = ch[0].height ~/ (2 * MAX_SYMBOL_ROWS * MAX_MODULES);
  if(min_module_size < 1 || mode == jab_detect_mode.INTENSIVE_DETECT) min_module_size = 1;

  var fps = List<jab_finder_pattern>.filled (MAX_FINDER_PATTERNS, jab_finder_pattern()); //calloc(MAX_FINDER_PATTERNS, sizeof(jab_finder_pattern));
  // if(fps == null) {
  //   // reportError("Memory allocation for finder patterns failed");
  //   status = FATAL_ERROR;
  //   return null;
  // }
  int total_finder_patterns = 0;
  bool done = false;
  var fp_type_count = List<int>.filled(4, 0);

  for(int i=0; i<ch[0].height && !done; i+=min_module_size) {
    //get row
    var row_r = ch[0].pixel.sublist(i*ch[0].width); //ch[0].pixel + i*ch[0].width;
    var row_g = ch[1].pixel.sublist(i*ch[1].width); //ch[1].pixel + i*ch[1].width
    var row_b = ch[2].pixel.sublist(i*ch[2].width); //ch[2].pixel + i*ch[2].width

    int startx = 0;
    int endx = ch[0].width;
    int skip = 0;

    do {
      int type_r = 0, type_g = 0, type_b = 0;
      double centerx_r = 0.0, centerx_g = 0.0, centerx_b = 0.0;
      double module_size_r = 0.0, module_size_g = 0.0, module_size_b = 0.0;
      var finder_pattern1_found = JAB_FAILURE;
      var finder_pattern2_found = JAB_FAILURE;

      startx += skip;
      endx = ch[0].width;
      //green channel
      var result = _seekPatternHorizontal(row_g, startx, endx, centerx_g, module_size_g, skip);
      startx = result.item2;
      endx = result.item3;
      centerx_g = result.item4;
      module_size_g = result.item5;
      skip = result.item6;
      if(result.item1 == JAB_SUCCESS) {
        type_g = row_g[centerx_g.toInt()] > 0 ? 255 : 0;

        centerx_r = centerx_g;
        centerx_b = centerx_g;
        //check blue channel for Finder Pattern UL and LL
        var result = _crossCheckPatternHorizontal(ch[2], module_size_g * 2, centerx_b, i.toDouble());
        centerx_b=result.item2;
        module_size_b=result.item3;
        if(result.item1 == JAB_SUCCESS) {
          type_b = row_b[centerx_b.toInt()] > 0 ? 255 : 0;
          //check red channel
          module_size_r = module_size_g;
          int core_color_in_red_channel = jab_default_palette[FP3_CORE_COLOR * 3 + 0];
          if(_crossCheckColor(ch[0], core_color_in_red_channel, module_size_r.toInt(), 5, centerx_r.toInt(), i, 0) == JAB_SUCCESS) {
            type_r = 0;
            finder_pattern1_found = JAB_SUCCESS;
          }

        //check red channel for Finder Pattern UR and LR
        } else {
          result = _crossCheckPatternHorizontal(ch[0], module_size_g * 2, centerx_r, i.toDouble());
          centerx_r = result.item2;
          module_size_r = result.item3;
          if (result.item1 == JAB_SUCCESS) {
            type_r = row_r[centerx_r.toInt()] > 0 ? 255 : 0;
            //check blue channel
            module_size_b = module_size_g;
            int core_color_in_blue_channel = jab_default_palette[FP2_CORE_COLOR * 3 + 2];
            if (_crossCheckColor(ch[2], core_color_in_blue_channel, module_size_b.toInt(), 5, centerx_b.toInt(), i, 0) == JAB_SUCCESS) {
              type_b = 0;
              finder_pattern2_found = JAB_SUCCESS;
            }
          }
        }
        //finder pattern candidate found
        if(finder_pattern1_found == JAB_SUCCESS || finder_pattern2_found == JAB_SUCCESS) {
          var fp= jab_finder_pattern();
          fp.center = jab_point(fp.center.x, i.toDouble() );
          fp.found_count = 1;
          if(finder_pattern1_found == JAB_SUCCESS) {
            if(!_checkModuleSize2(module_size_g, module_size_b)) continue;
            fp.center = jab_point((centerx_g + centerx_b) / 2.0, fp.center.y);
            fp.module_size = (module_size_g + module_size_b) / 2.0;
            if( type_r == jab_default_palette[FP0_CORE_COLOR * 3] &&
              type_g == jab_default_palette[FP0_CORE_COLOR * 3 + 1] &&
              type_b == jab_default_palette[FP0_CORE_COLOR * 3 + 2])
            {
              fp.type = FP0;	//candidate for fp0
            } else if(type_r == jab_default_palette[FP3_CORE_COLOR * 3] &&
              type_g == jab_default_palette[FP3_CORE_COLOR * 3 + 1] &&
              type_b == jab_default_palette[FP3_CORE_COLOR * 3 + 2])
            {
              fp.type = FP3;	//candidate for fp3
            } else {
              continue;		//invalid type
            }
          } else if(finder_pattern2_found == JAB_SUCCESS) {
            if(!_checkModuleSize2(module_size_r, module_size_g)) continue;
            fp.center = jab_point((centerx_r + centerx_g) / 2.0, fp.center.y);
            fp.module_size = (module_size_r + module_size_g) / 2.0;
            if(type_r == jab_default_palette[FP1_CORE_COLOR * 3] &&
              type_g == jab_default_palette[FP1_CORE_COLOR * 3 + 1] &&
              type_b == jab_default_palette[FP1_CORE_COLOR * 3 + 2])
            {
              fp.type = FP1;	//candidate for fp1
            } else if(type_r == jab_default_palette[FP2_CORE_COLOR * 3] &&
              type_g == jab_default_palette[FP2_CORE_COLOR * 3 + 1] &&
              type_b == jab_default_palette[FP2_CORE_COLOR * 3 + 2])
            {
              fp.type = FP2;	//candidate for fp2
            } else {
              continue;		//invalid type
            }
          }
          //cross check
          if( _crossCheckPattern(ch, fp, 0) == JAB_SUCCESS) {
            total_finder_patterns = _saveFinderPattern(fp, fps, total_finder_patterns, fp_type_count);
            if(total_finder_patterns >= (MAX_FINDER_PATTERNS - 1)) {
              done = true;
              break;
            }
          }
        }
      }
    } while(startx < ch[0].width && endx < ch[0].width);
  }

  //if only FP0 and FP1 are found or only FP2 and FP3 are found, do vertical-scan
	if( (fp_type_count[0] != 0 && fp_type_count[1] !=0 && fp_type_count[2] == 0 && fp_type_count[3] == 0) ||
	    (fp_type_count[0] == 0 && fp_type_count[1] ==0 && fp_type_count[2] != 0 && fp_type_count[3] != 0) )
	{
    total_finder_patterns = _scanPatternVertical(ch, min_module_size, fps, fp_type_count, total_finder_patterns);
		//set dir to 2?
	}
  
	for(int i=0; i<total_finder_patterns; i++) {
		fps[i].direction = fps[i].direction >=0 ? 1 : -1;
	}
	//select best patterns
	int missing_fp_count = _selectBestPatterns(fps, total_finder_patterns, fp_type_count);

	//if more than one finder patterns are missing, detection fails
	if(missing_fp_count > 1) {
		status = JAB_FAILURE;
		return Tuple2<int, List<jab_finder_pattern>>(status, fps); //Too few finder pattern found
	}

    //if only one finder pattern is missing, try anyway by estimating the missing one
    if(missing_fp_count == 1) {
      //estimate the missing finder pattern
      int miss_fp = 0;
      if(fps[0].found_count == 0) {
        miss_fp = 0;
        double ave_size_fp23 = (fps[2].module_size + fps[3].module_size) / 2.0;
        double ave_size_fp13 = (fps[1].module_size + fps[3].module_size) / 2.0;
        fps[0].center = jab_point((fps[3].center.x - fps[2].center.x) / ave_size_fp23 * ave_size_fp13 + fps[1].center.x,
                                  (fps[3].center.y - fps[2].center.y) / ave_size_fp23 * ave_size_fp13 + fps[1].center.y);
        fps[0].type = FP0;
        fps[0].found_count = 1;
        fps[0].direction = -fps[1].direction;
        fps[0].module_size = (fps[1].module_size + fps[2].module_size + fps[3].module_size) / 3.0;
      } else if(fps[1].found_count == 0) {
        miss_fp = 1;
        double ave_size_fp23 = (fps[2].module_size + fps[3].module_size) / 2.0;
        double ave_size_fp02 = (fps[0].module_size + fps[2].module_size) / 2.0;
        fps[1].center = jab_point((fps[2].center.x - fps[3].center.x) / ave_size_fp23 * ave_size_fp02 + fps[0].center.x,
                                  (fps[2].center.y - fps[3].center.y) / ave_size_fp23 * ave_size_fp02 + fps[0].center.y);
        fps[1].type = FP1;
        fps[1].found_count = 1;
        fps[1].direction = -fps[0].direction;
        fps[1].module_size = (fps[0].module_size + fps[2].module_size + fps[3].module_size) / 3.0;
      } else if(fps[2].found_count == 0) {
        miss_fp = 2;
        double ave_size_fp01 = (fps[0].module_size + fps[1].module_size) / 2.0;
        double ave_size_fp13 = (fps[1].module_size + fps[3].module_size) / 2.0;
        fps[2].center = jab_point((fps[1].center.x - fps[0].center.x) / ave_size_fp01 * ave_size_fp13 + fps[3].center.x,
                                (fps[1].center.y - fps[0].center.y) / ave_size_fp01 * ave_size_fp13 + fps[3].center.y);
        fps[2].type = FP2;
        fps[2].found_count = 1;
        fps[2].direction = fps[3].direction;
        fps[2].module_size = (fps[0].module_size + fps[1].module_size + fps[3].module_size) / 3.0;
      } else if(fps[3].found_count == 0) {
        miss_fp = 3;
        double ave_size_fp01 = (fps[0].module_size + fps[1].module_size) / 2.0;
        double ave_size_fp02 = (fps[0].module_size + fps[2].module_size) / 2.0;
        fps[3].center = jab_point((fps[0].center.x - fps[1].center.x) / ave_size_fp01 * ave_size_fp02 + fps[2].center.x,
                                (fps[0].center.y - fps[1].center.y) / ave_size_fp01 * ave_size_fp02 + fps[2].center.y);
        fps[3].type = FP3;
        fps[3].found_count = 1;
        fps[3].direction = fps[2].direction;
        fps[3].module_size = (fps[0].module_size + fps[1].module_size + fps[2].module_size) / 3.0;
      }
      //check the position of the missed finder pattern
		  if(fps[miss_fp].center.x < 0 || fps[miss_fp].center.x > ch[0].width - 1 ||
         fps[miss_fp].center.y < 0 || fps[miss_fp].center.y > ch[0].height - 1)
		  {
        fps[miss_fp].found_count = 0;
        status = JAB_FAILURE; //Finder pattern %d out of image", miss_fp
        return Tuple2<int, List<jab_finder_pattern>>(status, fps);
      }
      
		_seekMissingFinderPattern(bitmap, fps, miss_fp);
  }
    
  status = JAB_SUCCESS;
  return Tuple2<int, List<jab_finder_pattern>>(status, fps);
}

/*
 Crosscheck the alignment pattern candidate in diagonal direction
 @param image the image bitmap
 @param ap_type the alignment pattern type
 @param module_size_max the maximal allowed module size
 @param center the alignment pattern center
 @param dir the alignment pattern direction
 @return item1 the y coordinate of the diagonal scanline center | -1 if failed
 @return item2 dir the alignment pattern direction
 */
Tuple2<double, int> _crossCheckPatternDiagonalAP(jab_bitmap image, int ap_type, int module_size_max, jab_point center, int dir) {
  int offset_x, offset_y;
  bool fix_dir = false;
  //if the direction is given, ONLY check the given direction
	if(dir != 0) {
		if(dir > 0) {
			offset_x = -1;
			offset_y = -1;
			dir = 1;
    } else {
			offset_x = 1;
			offset_y = -1;
			dir = -1;
		}
		fix_dir = true;
  } else {
		//for ap0 and ap1, first check the diagonal at +45 degree
    if(ap_type == AP0 || ap_type == AP1) {
			offset_x = -1;
			offset_y = -1;
			dir = 1;

		//for ap2 and ap3, first check the diagonal at -45 degree
    } else {
			offset_x = 1;
			offset_y = -1;
			dir = -1;
		}
	}

  bool flag = false;
  int try_count = 0;
  do {
    flag = false;
    try_count++;

    int i, state_index;
    var state_count = List<int>.filled(3, 0);
    int startx = center.x.toInt();
    int starty = center.y.toInt();

    state_count[1]++;
    state_index=0;
    for(i=1; i<=starty && i<=startx && state_index<=1; i++) {
      if( image.pixel[(starty + i*offset_y)*image.width + (startx + i*offset_x)] == image.pixel[(starty + (i-1)*offset_y)*image.width + (startx + (i-1)*offset_x)] ) {
        state_count[1 - state_index]++;
      } else {
        if (state_index >0 && state_count[1 - state_index] < 3) {
          state_count[1 - (state_index-1)] += state_count[1 - state_index];
          state_count[1 - state_index] = 0;
          state_index--;
          state_count[1 - state_index]++;
        } else {
          state_index++;
          if(state_index > 1) {
            break;
          } else {
            state_count[1 - state_index]++;
          }
        }
      }
    }
    if(state_index < 1) {
      if(try_count == 1) {
        flag = true;
        offset_x = -offset_x;
        dir = -dir;
      } else {
        return Tuple2<double, int>(-1, dir);
      }
    }

		if(!flag) {
      state_index=0;
			for(i=1; (starty+i)<image.height && (startx+i)<image.width && state_index<=1; i++) {
				if( image.pixel[(starty - i*offset_y)*image.width + (startx - i*offset_x)] == image.pixel[(starty - (i-1)*offset_y)*image.width + (startx - (i-1)*offset_x)] ) {
					state_count[1 + state_index]++;
        } else {
					if(state_index >0 && state_count[1 + state_index] < 3) {
						state_count[1 + (state_index-1)] += state_count[1 + state_index];
						state_count[1 + state_index] = 0;
						state_index--;
						state_count[1 + state_index]++;
					} else {
						state_index++;
						if(state_index > 1) {
						  break;
						} else {
						  state_count[1 + state_index]++;
						}
					}
				}
			}
			if(state_index < 1) {
				if(try_count == 1) {
					flag = true;
					offset_x = -offset_x;
					dir = -dir;
				} else {
				  return Tuple2<double, int>(-1, dir);
				}
			}
		}

		if(!flag) {
			//check module size, if it is too big, assume it is a false positive
			if(state_count[1] < module_size_max && state_count[0] > 0.5 * state_count[1] && state_count[2] > 0.5 * state_count[1]) {
				double new_centery = (starty + i - state_count[2]) - state_count[1] / 2.0;
				return Tuple2<double, int>(new_centery, dir);
			} else {
				flag = true;
				offset_x = - offset_x;
				dir = -dir;
			}
		}
  } while(flag && try_count < 2 && !fix_dir);

  return Tuple2<double, int>(-1, dir);
}

/*
 Crosscheck the alignment pattern candidate in vertical direction
 @param image the image bitmap
 @param center the alignment pattern center
 @param module_size_max the maximal allowed module size
 @param module_size the module size in vertical direction
 @return the y coordinate of the vertical scanline center | -1 if failed
 @return module_size the module size in vertical direction
*/
Tuple2<double, double> _crossCheckPatternVerticalAP(jab_bitmap image, jab_point center, int module_size_max, double module_size) {
  var state_count = List<int>.filled(3, 0);
  int centerx = center.x.toInt();
  int centery = center.y.toInt();
  int i, state_index;

  state_count[1]++;
  state_index=0;
  for(i=1; i<=centery && state_index<=1; i++) {
    if( image.pixel[(centery-i)*image.width + centerx] == image.pixel[(centery-(i-1))*image.width + centerx] ) {
      state_count[1 - state_index]++;
    } else {
      if(state_index > 0 && state_count[1 - state_index] < 3) {
        state_count[1 - (state_index-1)] += state_count[1 - state_index];
        state_count[1 - state_index] = 0;
        state_index--;
        state_count[1 - state_index]++;
      } else {
        state_index++;
        if(state_index > 1) {
          break;
        } else {
          state_count[1 - state_index]++;
        }
      }
    }
  }
  if(state_index < 1) {
    return Tuple2<double, double>(-1, module_size);
  }
  state_index=0;
  for(i=1; (centery+i)<image.height && state_index<=1; i++) {
    if( image.pixel[(centery+i)*image.width + centerx] == image.pixel[(centery+(i-1))*image.width + centerx] ) {
      state_count[1 + state_index]++;
    } else {
      if(state_index > 0 && state_count[1 + state_index] < 3) {
        state_count[1 + (state_index-1)] += state_count[1 + state_index];
        state_count[1 + state_index] = 0;
        state_index--;
        state_count[1 + state_index]++;
      } else {
        state_index++;
        if(state_index > 1) {
          break;
        } else {
          state_count[1 + state_index]++;
        }
      }
    }
  }
  if(state_index < 1) {
    return Tuple2<double, double>(-1, module_size);
  }

  //check module size, if it is too big, assume it is a false positive
  if(state_count[1] < module_size_max && state_count[0] > 0.5 * state_count[1] && state_count[2] > 0.5 * state_count[1]) {
    module_size = state_count[1].toDouble();
    double new_centery = (centery + i - state_count[2]) - state_count[1] / 2.0;
    return Tuple2<double, double>(new_centery, module_size);
  }
  return Tuple2<double, double>(-1, module_size);
}

/*
 Crosscheck the alignment pattern candidate in horizontal direction
 @param row the bitmap row
 @param channel the color channel
 @param startx the start position
 @param endx the end position
 @param centerx the center of the candidate scanline
 @param ap_type the alignment pattern type
 @param module_size_max the maximal allowed module size
 @param module_size the module size in horizontal direction
 @return the x coordinate of the horizontal scanline center | -1 if failed
 @return module_size the module size in horizontal direction
*/
Tuple2<double, double> _crossCheckPatternHorizontalAP(List<int> row, int channel, int startx, int endx, int centerx, int ap_type, double module_size_max, double module_size) {
  int core_color = -1;
  switch(ap_type) {
    case AP0:
      core_color = jab_default_palette[AP0_CORE_COLOR * 3 + channel];
      break;
    case AP1:
      core_color = jab_default_palette[AP1_CORE_COLOR * 3 + channel];
      break;
    case AP2:
      core_color = jab_default_palette[AP2_CORE_COLOR * 3 + channel];
      break;
    case AP3:
      core_color = jab_default_palette[AP3_CORE_COLOR * 3 + channel];
     break;
    case APX:
      core_color = jab_default_palette[APX_CORE_COLOR * 3 + channel];
      break;
  }
  if(row[centerx] != core_color) {
    return Tuple2<double, double>(-1, module_size);
  }

  var state_count = List<int>.filled(3, 0);
  int i, state_index;

  state_count[1]++;
  state_index=0;
  for(i=1; (centerx-i)>=startx && state_index<=1; i++) {
    if( row[centerx - i] == row[centerx - (i-1)] ) {
      state_count[1 - state_index]++;
    } else {
      if(state_index > 0 && state_count[1 - state_index] < 3) {
        state_count[1 - (state_index-1)] += state_count[1 - state_index];
        state_count[1 - state_index] = 0;
        state_index--;
        state_count[1 - state_index]++;
      } else {
        state_index++;
        if(state_index > 1) {
          break;
        } else {
          state_count[1 - state_index]++;
        }
      }
    }
  }
  if(state_index < 1) {
    return Tuple2<double, double>(-1, module_size);
  }
  state_index=0;
  for(i=1; (centerx+i)<=endx && state_index<=1; i++) {
    if( row[centerx + i] == row[centerx + (i-1)] ) {
      state_count[1 + state_index]++;
    } else {
      if(state_index > 0 && state_count[1 + state_index] < 3) {
        state_count[1 + (state_index-1)] += state_count[1 + state_index];
        state_count[1 + state_index] = 0;
        state_index--;
        state_count[1 + state_index]++;
      } else {
        state_index++;
        if(state_index > 1) {
          break;
        } else {
          state_count[1 + state_index]++;
        }
      }
    }
  }
  if(state_index < 1) {
    return Tuple2<double, double>(-1, module_size);
  }

  //check module size, if it is too big, assume it is a false positive
  if(state_count[1] < module_size_max && state_count[0] > 0.5 * state_count[1] && state_count[2] > 0.5 * state_count[1]) {
    module_size = state_count[1].toDouble();
    double new_centerx = (centerx + i - state_count[2]) - state_count[1] / 2.0;
    return Tuple2<double, double>(new_centerx, module_size);
  }
  return Tuple2<double, double>(-1, module_size);
}

/*
 Crosscheck the alignment pattern
 @param ch the binarized color channels of the image
 @param y the y coordinate of the horizontal scanline
 @param minx the minimal coordinate of the horizontal scanline
 @param maxx the maximal coordinate of the horizontal scanline
 @param cur_x the start position of the horizontal scanline
 @param ap_type the alignment pattern type
 @param max_module_size the maximal allowed module size
 @param centerx the x coordinate of the alignment pattern center
 @param centery the y coordinate of the alignment pattern center
 @param module_size the module size
 @param dir the alignment pattern direction
 @return item1 JAB_SUCCESS | JAB_FAILURE
 @return item2 center the  coordinate of the alignment pattern center
 @return item3 module_size the module size
 @return item4 dir the alignment pattern direction
*/
Tuple4<int, jab_point, double, int> _crossCheckPatternAP(List<jab_bitmap> ch, int y, int minx, int maxx, int cur_x, int ap_type, double max_module_size, double centerx, double centery, double module_size, int dir) {
	//get row
	var row_r = ch[0].pixel.sublist(y*ch[0].width, (y+1)*ch[0].width);
  var row_b = ch[2].pixel.sublist(y*ch[2].width, (y+1)*ch[2].width);

  var l_centerx = List<double>.filled(3, 0);
  var l_centery = List<double>.filled(3, 0);
  var l_module_size_h = List<double>.filled(3, 0);
  var l_module_size_v = List<double>.filled(3, 0);

	//check r channel horizontally
	var result = _crossCheckPatternHorizontalAP(row_r, 0, minx, maxx, cur_x, ap_type, max_module_size, l_module_size_h[0]);
  l_centerx[0] = result.item1;
  l_module_size_h[0] = result.item2;
	if(l_centerx[0] < 0) return Tuple4<int, jab_point, double, int>(JAB_FAILURE, jab_point(centerx, centery), module_size, dir);
	//check b channel horizontally
  result = _crossCheckPatternHorizontalAP(row_b, 2, minx, maxx, l_centerx[0].toInt(), ap_type, max_module_size, l_module_size_h[2]);
  l_centerx[2] = result.item1;
  l_module_size_h[2] = result.item2;
	if(l_centerx[2] < 0) return Tuple4<int, jab_point, double, int>(JAB_FAILURE, jab_point(centerx, centery), module_size, dir);
	//calculate the center and the module size
	var center = jab_point(0, 0);
	center.x = (l_centerx[0] + l_centerx[2]) / 2.0;
	center.y = y.toDouble();
	module_size = (l_module_size_h[0] + l_module_size_h[2]) / 2.0;
	//check g channel horizontally
	int core_color_in_green_channel = -1;
  switch(ap_type) {
    case AP0:
      core_color_in_green_channel = jab_default_palette[AP0_CORE_COLOR * 3 + 1];
      break;
    case AP1:
      core_color_in_green_channel = jab_default_palette[AP1_CORE_COLOR * 3 + 1];
      break;
    case AP2:
      core_color_in_green_channel = jab_default_palette[AP2_CORE_COLOR * 3 + 1];
      break;
    case AP3:
      core_color_in_green_channel = jab_default_palette[AP3_CORE_COLOR * 3 + 1];
      break;
    case APX:
      core_color_in_green_channel = jab_default_palette[APX_CORE_COLOR * 3 + 1];
      break;
  }
	if(_crossCheckColor(ch[1], core_color_in_green_channel, module_size.toInt(), 3, center.x.toInt(), center.y.toInt(), 0) == JAB_FAILURE) {
	  return Tuple4<int, jab_point, double, int>(JAB_FAILURE, jab_point(centerx, centery), module_size, dir);
	}

	//check r channel vertically
	result = _crossCheckPatternVerticalAP(ch[0], center, max_module_size.toInt(), l_module_size_v[0]);
  l_centery[0] = result.item1;
  l_module_size_v[0] = result.item2;
  if(l_centery[0] < 0) return Tuple4<int, jab_point, double, int>(JAB_FAILURE, jab_point(centerx, centery), module_size, dir);
	//again horizontally
	row_r = ch[0].pixel.sublist((l_centery[0]*ch[0].width).toInt(), ((l_centery[0]+1)*ch[0].width).toInt());
  result= _crossCheckPatternHorizontalAP(row_r, 0, minx, maxx, center.x.toInt(), ap_type, max_module_size, l_module_size_h[0]);
  l_centerx[0] = result.item1;
  l_module_size_h[0] = result.item2;
	if(l_centerx[0] < 0) return Tuple4<int, jab_point, double, int>(JAB_FAILURE, jab_point(centerx, centery), module_size, dir);

	//check b channel vertically
  result = _crossCheckPatternVerticalAP(ch[2], center, max_module_size.toInt(), l_module_size_v[2]);
  l_centery[2] = result.item1;
  l_module_size_v[2] = result.item2;
	if(l_centery[2] < 0) return Tuple4<int, jab_point, double, int>(JAB_FAILURE, jab_point(centerx, centery), module_size, dir);
	//again horizontally
	row_b = ch[2].pixel.sublist((l_centery[2]*ch[2].width).toInt(),((l_centery[2]+1)*ch[2].width).toInt());
  result = _crossCheckPatternHorizontalAP(row_b, 2, minx, maxx, center.x.toInt(), ap_type, max_module_size, l_module_size_h[2]);
	l_centerx[2] = result.item1;
  l_module_size_h[2] = result.item2;
	if(l_centerx[2] < 0) return Tuple4<int, jab_point, double, int>(JAB_FAILURE, jab_point(centerx, centery), module_size, dir);

	//update the center and the module size
	module_size = (l_module_size_h[0] + l_module_size_h[2] + l_module_size_v[0] + l_module_size_v[2]) / 4.0;
	centerx = (l_centerx[0] + l_centerx[2]) / 2.0;
	centery = (l_centery[0] + l_centery[2]) / 2.0;
	center.x = centerx;
	center.y = centery;

	//check g channel vertically
	if(_crossCheckColor(ch[1], core_color_in_green_channel, module_size.toInt(), 3, center.x.toInt(), center.y.toInt(), 1)== JAB_FAILURE) {
	  return Tuple4<int, jab_point, double, int>(JAB_FAILURE, jab_point(centerx, centery), module_size, dir);
	}

	//diagonal check
	var l_dir = List<int>.filled(3, 0);
  var result1 = _crossCheckPatternDiagonalAP(ch[0], ap_type, (module_size*2).toInt(), center, l_dir[0]);
  l_dir[0] = result1.item2;
	if(result1.item1 < 0) return Tuple4<int, jab_point, double, int>(JAB_FAILURE, jab_point(centerx, centery), module_size, dir);
  result1 = _crossCheckPatternDiagonalAP(ch[2], ap_type, (module_size*2).toInt(), center, l_dir[2]);
  l_dir[2] = result1.item2;
	if(result1.item1 < 0) return Tuple4<int, jab_point, double, int>(JAB_FAILURE, jab_point(centerx, centery), module_size, dir);
	if(_crossCheckColor(ch[1], core_color_in_green_channel, module_size.toInt(), 3, center.x.toInt(), center.y.toInt(), 2) == JAB_FAILURE) {
	  return Tuple4<int, jab_point, double, int>(JAB_FAILURE, jab_point(centerx, centery), module_size, dir);
	}
	dir = (l_dir[0] + l_dir[2]) > 0 ? 1 : -1;

	return Tuple4<int, jab_point, double, int>(JAB_SUCCESS, jab_point(centerx, centery), module_size, dir);
}

/*
 Find alignment pattern around a given position
 @param ch the binarized color channels of the image
 @param x the x coordinate of the given position
 @param y the y coordinate of the given position
 @param module_size the module size
 @param ap_type the alignment pattern type
 @return the found alignment pattern
*/
jab_alignment_pattern _findAlignmentPattern(List<jab_bitmap> ch, double x, double y, double module_size, int ap_type) {
  var ap =jab_alignment_pattern();
  ap.type = -1;
  ap.found_count = 0;

    //determine the core color of r channel
	int core_color_r = -1;
	switch(ap_type) {
		case AP0:
			core_color_r = jab_default_palette[AP0_CORE_COLOR * 3];
			break;
		case AP1:
			core_color_r = jab_default_palette[AP1_CORE_COLOR * 3];
			break;
		case AP2:
			core_color_r = jab_default_palette[AP2_CORE_COLOR * 3];
			break;
		case AP3:
			core_color_r = jab_default_palette[AP3_CORE_COLOR * 3];
			break;
		case APX:
			core_color_r = jab_default_palette[APX_CORE_COLOR * 3];
			break;
	}

  //define search range
  int radius = (4 * module_size).toInt();
  int radius_max = 4 * radius;

  for(; radius<radius_max; radius<<=1) {
    var aps = List<jab_alignment_pattern>.filled(MAX_FINDER_PATTERNS, jab_alignment_pattern()); //calloc(MAX_FINDER_PATTERNS, sizeof(jab_alignment_pattern));
    // if(aps == null) {
    //   // reportError("Memory allocation for alignment patterns failed");
    //   return ap;
    // }

    int startx = max(0, x - radius).toInt();
    int starty = max(0, y - radius).toInt();
    int endx = min(ch[0].width - 1, x + radius).toInt();
    int endy = min(ch[0].height - 1, y + radius).toInt();
    if(endx - startx < 3 * module_size || endy - starty < 3 * module_size) continue;

    int counter = 0;
    for(int k=starty; k<endy; k++) {
      //search from middle outwards
      int kk = k - starty;
      int i = (y + ((kk & 0x01) == 0 ? (kk + 1) / 2 : -((kk + 1) / 2))).toInt();
      if(i < starty) {
        continue;
      } else if(i > endy) {
        continue;
      }

      //get r channel row
      var row_r = ch[0].pixel.sublist(i*ch[0].width, (i+1)*ch[0].width);

      double ap_module_size = 0.0, centerx = 0.0, centery = 0.0;
      int ap_dir = 0;

      int ap_found = 0;
      int dir = -1;
      int left_tmpx = x.toInt();
      int right_tmpx = x.toInt();
      while((left_tmpx > startx || right_tmpx < endx) && ap_found==0) {
        if(dir < 0)	{ //go to left
          while(row_r[left_tmpx] != core_color_r && left_tmpx > startx) {
            left_tmpx--;
          }
          if(left_tmpx <= startx) {
            dir = -dir;
            continue;
          }
          var result = _crossCheckPatternAP(ch, i, startx, endx, left_tmpx, ap_type, module_size*2, centerx, centery, ap_module_size, ap_dir);
          ap_found = result.item1;
          centerx = result.item2.x;
          centery = result.item2.y;
          ap_module_size = result.item3;
          ap_dir = result.item4;

          while(row_r[left_tmpx] == core_color_r && left_tmpx > startx) {
            left_tmpx--;
          }
          dir = -dir;
        } else { //go to right
          while(row_r[right_tmpx] == core_color_r && right_tmpx < endx) {
            right_tmpx++;
          }
          while(row_r[right_tmpx] != core_color_r && right_tmpx < endx) {
            right_tmpx++;
          }
          if(right_tmpx >= endx) {
            dir = -dir;
            continue;
          }

          var result = _crossCheckPatternAP(ch, i, startx, endx, right_tmpx, ap_type, module_size*2, centerx, centery, ap_module_size, ap_dir);
          ap_found = result.item1;
          centerx = result.item2.x;
          centery = result.item2.y;
          ap_module_size = result.item3;
          ap_dir = result.item4;

          while(row_r[right_tmpx] == core_color_r && right_tmpx < endx) {
            right_tmpx++;
          }
          dir = -dir;
        }
      }

      if(ap_found==0) continue;

      ap.center.x = centerx;
      ap.center.y = centery;
      ap.module_size = ap_module_size;
      ap.direction = ap_dir;
      ap.type = ap_type;
      ap.found_count = 1;

      var result = _saveAlignmentPattern(ap, aps, counter);
      int index = result.item1;
      counter = result.item2;
      if(index >= 0) { //if found twice, done!
        ap = aps[index];
        // free(aps);
        return ap;
      }
    }
    // free(aps);
  }
  ap.type = -1;
  ap.found_count = 0;
  return ap;
}

/*
 Find a docked slave symbol
 @param bitmap the image bitmap
 @param ch the binarized color channels of the image
 @param host_symbol the host symbol
 @param slave_symbol the slave symbol
 @param docked_position the docked position
 @return JAB_SUCCESS | JAB_FAILURE
*/
int _findSlaveSymbol(jab_bitmap bitmap, List<jab_bitmap> ch, jab_decoded_symbol host_symbol, jab_decoded_symbol slave_symbol, int docked_position) {
  var aps = List<jab_alignment_pattern>.filled (4, jab_alignment_pattern()); //calloc(4, sizeof(jab_alignment_pattern));
  // if(aps == null) {
  //   // reportError("Memory allocation for alignment patterns failed");
  //   return JAB_FAILURE;
  // }

  //get slave symbol side size from its metadata
  slave_symbol.side_size.x = VERSION2SIZE(slave_symbol.metadata.side_version.x);
  slave_symbol.side_size.y = VERSION2SIZE(slave_symbol.metadata.side_version.y);

  //docked horizontally
  double distx01 = host_symbol.pattern_positions[1].x - host_symbol.pattern_positions[0].x;
  double disty01 = host_symbol.pattern_positions[1].y - host_symbol.pattern_positions[0].y;
  double distx32 = host_symbol.pattern_positions[2].x - host_symbol.pattern_positions[3].x;
  double disty32 = host_symbol.pattern_positions[2].y - host_symbol.pattern_positions[3].y;
  //docked vertically
  double distx03 = host_symbol.pattern_positions[3].x - host_symbol.pattern_positions[0].x;
  double disty03 = host_symbol.pattern_positions[3].y - host_symbol.pattern_positions[0].y;
  double distx12 = host_symbol.pattern_positions[2].x - host_symbol.pattern_positions[1].x;
  double disty12 = host_symbol.pattern_positions[2].y - host_symbol.pattern_positions[1].y;

  double alpha1 = 0.0, alpha2 = 0.0;
  int sign = 1;
  int docked_side_size = 0;
  int undocked_side_size = 0;
  int ap1 = 0, ap2 = 0, ap3 = 0, ap4 = 0, hp1 = 0, hp2 = 0;
  switch(docked_position) {
    case 3:
      /*
      fp[0] ... fp[1] .. ap[0] ... ap[1]
        .         .         .         .
        .  master .         .  slave  .
        .         .         .         .
      fp[3] ... fp[2] .. ap[3] ... ap[2]
      */
      alpha1 = atan2(disty01, distx01);
      alpha2 = atan2(disty32, distx32);
      sign = 1;
      docked_side_size   = slave_symbol.side_size.y;
      undocked_side_size = slave_symbol.side_size.x;
      ap1 = AP0;	//ap[0]
      ap2 = AP3;	//ap[3]
      ap3 = AP1;	//ap[1]
      ap4 = AP2;	//ap[2]
      hp1 = FP1;	//fp[1] or ap[1] of the host
      hp2 = FP2;	//fp[2] or ap[2] of the host
      slave_symbol.host_position = 2;
      break;
    case 2:
      /*
      ap[0] ... ap[1] .. fp[0] ... fp[1]
        .         .        .         .
        .  slave  .        .  master .
        .         .        .         .
      ap[3] ... ap[2] .. fp[3] ... fp[2]
      */
      alpha1 = atan2(disty32, distx32);
      alpha2 = atan2(disty01, distx01);
      sign = -1;
      docked_side_size   = slave_symbol.side_size.y;
      undocked_side_size = slave_symbol.side_size.x;
      ap1 = AP2;	//ap[2]
      ap2 = AP1;	//ap[1]
      ap3 = AP3;	//ap[3]
      ap4 = AP0;	//ap[0]
      hp1 = FP3;	//fp[3] or ap[3] of the host
      hp2 = FP0;	//fp[0] or ap[0] of the host
      slave_symbol.host_position = 3;
      break;
    case 1:
      /*
      fp[0] ... fp[1]
        .         .
        .  master .
        .         .
      fp[3] ... fp[2]
        .			.
        . 		.
      ap[0] ... ap[1]
        .         .
        .  slave  .
        .         .
      ap[3] ... ap[2]
      */
      alpha1 = atan2(disty12, distx12);
      alpha2 = atan2(disty03, distx03);
      sign = 1;
      docked_side_size   = slave_symbol.side_size.x;
      undocked_side_size = slave_symbol.side_size.y;
      ap1 = AP1;	//ap[1]
      ap2 = AP0;	//ap[0]
      ap3 = AP2;	//ap[2]
      ap4 = AP3;	//ap[3]
      hp1 = FP2;	//fp[2] or ap[2] of the host
      hp2 = FP3;	//fp[3] or ap[3] of the host
      slave_symbol.host_position = 0;
      break;
    case 0:
      /*
      ap[0] ... ap[1]
        .         .
        .  slave  .
        .         .
      ap[3] ... ap[2]
        .			.
        . 		.
      fp[0] ... fp[1]
        .         .
        .  master .
        .         .
      fp[3] ... fp[2]
      */
      alpha1 = atan2(disty03, distx03);
      alpha2 = atan2(disty12, distx12);
      sign = -1;
      docked_side_size   = slave_symbol.side_size.x;
      undocked_side_size = slave_symbol.side_size.y;
      ap1 = AP3;	//ap[3]
      ap2 = AP2;	//ap[2]
      ap3 = AP0;	//ap[0]
      ap4 = AP1;	//ap[1]
      hp1 = FP0;	//fp[0] or ap[0] of the host
      hp2 = FP1;	//fp[1] or ap[1] of the host
      slave_symbol.host_position = 1;
      break;
  }

  //calculate the coordinate of ap1
  aps[ap1].center.x = host_symbol.pattern_positions[hp1].x + sign * 7 * host_symbol.module_size * cos(alpha1);
  aps[ap1].center.y = host_symbol.pattern_positions[hp1].y + sign * 7 * host_symbol.module_size * sin(alpha1);
  //find the alignment pattern around ap1
  aps[ap1] = _findAlignmentPattern(ch, aps[ap1].center.x, aps[ap1].center.y, host_symbol.module_size, ap1);
  if(aps[ap1].found_count == 0) {
    return JAB_FAILURE; //The first alignment pattern in slave symbol %d not found", slave_symbol.index
  }
  //calculate the coordinate of ap2
  aps[ap2].center.x = host_symbol.pattern_positions[hp2].x + sign * 7 * host_symbol.module_size * cos(alpha2);
  aps[ap2].center.y = host_symbol.pattern_positions[hp2].y + sign * 7 * host_symbol.module_size * sin(alpha2);
  //find alignment pattern around ap2
  aps[ap2] = _findAlignmentPattern(ch, aps[ap2].center.x, aps[ap2].center.y, host_symbol.module_size, ap2);
  if(aps[ap2].found_count == 0) {
    // JAB_REPORT_ERROR(("The second alignment pattern in slave symbol %d not found", slave_symbol.index))
    return JAB_FAILURE;
  }

  //estimate the module size in the slave symbol
  slave_symbol.module_size = DIST(aps[ap1].center.x, aps[ap1].center.y, aps[ap2].center.x, aps[ap2].center.y) / (docked_side_size - 7);

  //calculate the coordinate of ap3
  aps[ap3].center.x = aps[ap1].center.x + sign * (undocked_side_size - 7) * slave_symbol.module_size * cos(alpha1);
  aps[ap3].center.y = aps[ap1].center.y + sign * (undocked_side_size - 7) * slave_symbol.module_size * sin(alpha1);
  //find alignment pattern around ap3
  aps[ap3] = _findAlignmentPattern(ch, aps[ap3].center.x, aps[ap3].center.y, slave_symbol.module_size, ap3);
  //calculate the coordinate of ap4
  aps[ap4].center.x = aps[ap2].center.x + sign * (undocked_side_size - 7) * slave_symbol.module_size * cos(alpha2);
  aps[ap4].center.y = aps[ap2].center.y + sign * (undocked_side_size - 7) * slave_symbol.module_size * sin(alpha2);
  //find alignment pattern around ap4
  aps[ap4] = _findAlignmentPattern(ch, aps[ap4].center.x, aps[ap4].center.y, slave_symbol.module_size, ap4);

  //if neither ap3 nor ap4 is found, failed
  if(aps[ap3].found_count == 0 && aps[ap4].found_count == 0) {
    return JAB_FAILURE;
  }
  //if only 3 aps are found, try anyway by estimating the coordinate of the fourth one
  if(aps[ap3].found_count == 0) {
    double ave_size_ap24 = (aps[ap2].module_size + aps[ap4].module_size) / 2.0;
    double ave_size_ap14 = (aps[ap1].module_size + aps[ap4].module_size) / 2.0;
    aps[ap3].center.x = (aps[ap4].center.x - aps[ap2].center.x) / ave_size_ap24 * ave_size_ap14 + aps[ap1].center.x;
    aps[ap3].center.y = (aps[ap4].center.y - aps[ap2].center.y) / ave_size_ap24 * ave_size_ap14 + aps[ap1].center.y;
    aps[ap3].type = ap3;
    aps[ap3].found_count = 1;
    aps[ap3].module_size = (aps[ap1].module_size + aps[ap2].module_size + aps[ap4].module_size) / 3.0;
    if(aps[ap3].center.x > bitmap.width - 1 || aps[ap3].center.y > bitmap.height - 1) {
      return JAB_FAILURE; //Alignment pattern %d out of image", ap3
    }
  }
  if(aps[ap4].found_count == 0) {
    double ave_size_ap13 = (aps[ap1].module_size + aps[ap3].module_size) / 2.0;
    double ave_size_ap23 = (aps[ap2].module_size + aps[ap3].module_size) / 2.0;
    aps[ap4].center.x = (aps[ap3].center.x - aps[ap1].center.x) / ave_size_ap13 * ave_size_ap23 + aps[ap2].center.x;
    aps[ap4].center.y = (aps[ap3].center.y - aps[ap1].center.y) / ave_size_ap13 * ave_size_ap23 + aps[ap2].center.y;
    aps[ap4].type = ap4;
    aps[ap4].found_count = 1;
    aps[ap4].module_size = (aps[ap1].module_size + aps[ap1].module_size + aps[ap3].module_size) / 3.0;
    if(aps[ap4].center.x > bitmap.width - 1 || aps[ap4].center.y > bitmap.height - 1) {
      return JAB_FAILURE; //Alignment pattern %d out of image", ap4
    }
  }

  //save the coordinates of aps into the slave symbol
  slave_symbol.pattern_positions[ap1] = aps[ap1].center;
  slave_symbol.pattern_positions[ap2] = aps[ap2].center;
  slave_symbol.pattern_positions[ap3] = aps[ap3].center;
  slave_symbol.pattern_positions[ap4] = aps[ap4].center;
  slave_symbol.module_size = (aps[ap1].module_size + aps[ap2].module_size + aps[ap3].module_size + aps[ap4].module_size) / 4.0;
    
  return JAB_SUCCESS;
}

/*
 Get the nearest valid side size to a given size
 @param size the input size
 @return the nearest valid side size | -1: invalid side size
 @return flag the flag indicating the magnitude of error
*/
Tuple2<int, int> _getSideSize(int size) {
	var flag = 1;
  switch (size & 0x03) { //mod 4
  case 0:
    size++;
    break;
  case 2:
    size--;
    break;
  case 3:
    size += 2;	//error is bigger than 1, guess the next version and try anyway
    flag = 0;
    break;
  }
  if(size < 21) {
		size = -1;
		flag = -1;
	} else if(size > 145) {
		size = -1;
		flag = -1;
	}
  return Tuple2<int, int>(size, flag);
}

/*
 Choose the side size according to the detection reliability
 @param size1 the first side size
 @param flag1 the detection flag of the first size
 @param size2 the second side size
 @param flag2 the detection flag of the second size
 @return the chosen side size
*/
int _chooseSideSize(int size1, int flag1, int size2, int flag2) {
	if(flag1 == -1 && flag2 == -1) {
		return -1;
	} else if(flag1 == flag2) {
	  return max(size1, size2);
	} else {
		if(flag1 > flag2) {
		  return size1;
		} else {
		  return size2;
		}
	}
}

/*
 Calculate the number of modules between two finder/alignment patterns
 @param fp1 the first finder/alignment pattern
 @param fp2 the second finder/alignment pattern
 @return the number of modules
*/
int _calculateModuleNumber(jab_finder_pattern fp1, jab_finder_pattern fp2) {
  double dist = DIST(fp1.center.x, fp1.center.y, fp2.center.x, fp2.center.y);
  //the angle between the scanline and the connection between finder/alignment patterns
  double cos_theta = max((fp2.center.x - fp1.center.x).abs(), (fp2.center.y - fp1.center.y).abs()) / dist;
  double mean = (fp1.module_size + fp2.module_size)*cos_theta / 2.0;
  int number = (dist / mean + 0.5).toInt();
  return number;
}

/*
 Calculate the side sizes of master symbol
 @param fps the finder patterns
 @return the horizontal and vertical side sizes
*/
jab_vector2d _calculateSideSize(List<jab_finder_pattern> fps) {
  /* finder pattern type layout
      0	1
      3	2
  */
	var side_size = jab_vector2d(-1, -1);
	int flag1, flag2;

	//calculate the horizontal side size
  int size_x_top = _calculateModuleNumber(fps[0], fps[1]) + 7;
  var result = _getSideSize(size_x_top);
  size_x_top = result.item1;
  flag1 = result.item2;
  int size_x_bottom = _calculateModuleNumber(fps[3], fps[2]) + 7;

  result = _getSideSize(size_x_bottom);
  size_x_bottom = result.item1;
  flag2 = result.item2;
	side_size.x = _chooseSideSize(size_x_top, flag1, size_x_bottom, flag2);

	//calculate the vertical side size
	int size_y_left = _calculateModuleNumber(fps[0], fps[3]) + 7;
  result = _getSideSize(size_y_left);
  size_y_left = result.item1;
  flag1 = result.item2;

  int size_y_right = _calculateModuleNumber(fps[1], fps[2]) + 7;
  result = _getSideSize(size_y_right);
  size_y_right = result.item1;
  flag2 = result.item2;
  side_size.y = _chooseSideSize(size_y_left, flag1, size_y_right, flag2);

  return side_size;
}

/*
 Get the nearest valid position of the first alignment pattern
 @param pos the input position
 @return the nearest valid position | -1: invalid position
*/
int _getFirstAPPos(int pos) {
  switch (pos % 3) {
  case 0:
    pos--;
    break;
  case 1:
    pos++;
    break;
  }
  if(pos < 14 || pos > 26) {
    pos = -1;
  }
  return pos;
}

/*
 Detect the first alignment pattern between two finder patterns
 @param ch the binarized color channels of the image
 @param side_version the side version
 @param fp1 the first finder pattern
 @param fp2 the second finder pattern
 @return the position of the found alignment pattern | JAB_FAILURE: if not found
*/
int _detectFirstAP(List<jab_bitmap> ch, int side_version, jab_finder_pattern fp1, jab_finder_pattern fp2) {
  var ap = jab_alignment_pattern();
   //direction: from FP1 to FP2
  double distx = fp2.center.x - fp1.center.x;
  double disty = fp2.center.y - fp1.center.y;
  double alpha = atan2(disty, distx);

  int next_version = side_version;
  int dir = 1;
  int up = 0, down = 0;
  do {
    //distance to FP1
    double distance = fp1.module_size * (jab_ap_pos[next_version-1][1] - jab_ap_pos[next_version-1][0]);
    //estimate the coordinate of the first AP
    ap.center.x = fp1.center.x + distance * cos(alpha);
    ap.center.y = fp1.center.y + distance * sin(alpha);
    ap.module_size = fp1.module_size;
    //detect AP
    ap.found_count = 0;
    ap = _findAlignmentPattern(ch, ap.center.x, ap.center.y, ap.module_size, APX);
    if(ap.found_count > 0) {
      int pos = _getFirstAPPos(4 + _calculateModuleNumber(fp1, jab_finder_pattern().import(ap)));
      if(pos > 0) {
        return pos;
      }
    }

    //try next version
    dir = -dir;
    if(dir == -1) {
      up++;
      next_version = up * dir + side_version;
      if(next_version < 6 || next_version > 32) {
        dir = -dir;
        up--;
        down++;
        next_version = down * dir + side_version;
      }
    } else {
      down++;
      next_version = down * dir + side_version;
      if(next_version < 6 || next_version > 32) {
        dir = -dir;
        down--;
        up++;
        next_version = up * dir + side_version;
      }
    }
  }while((up+down) < 5);

  return JAB_FAILURE;
}

/*
 Confirm the side version by alignment pattern's positions
 @param side_version the side version
 @param found_ap_number the number of the found alignment patterns
 @param ap_positions the positions of the found alignment patterns
 @return the confirmed side version | JAB_FAILURE: if can not be confirmed
*/
int _confirmSideVersion(int side_version, int first_ap_pos) {
  if(first_ap_pos <= 0) {
    return JAB_FAILURE;
  }

  int v = side_version;
  int k = 1, sign = -1;
  bool flag = false;
  do {
    if(first_ap_pos == jab_ap_pos[v-1][1]) {
        flag = true;
        break;
    }
    v = side_version + sign*k;
    if(sign > 0) k++;
    sign = -sign;
  } while(v>=6 && v<=32);

  if(flag) {
    return v;
  } else {
    return JAB_FAILURE;
  }
}

/*
 Confirm the symbol size by alignment patterns
 @param ch the binarized color channels of the image
 @param fps the finder patterns
 @param symbol the symbol
 @return JAB_SUCCESS | JAB_FAILURE
*/
int _confirmSymbolSize(List<jab_bitmap> ch, List<jab_finder_pattern> fps, jab_decoded_symbol symbol) {
 	int first_ap_pos;

	//side version x: scan the line between FP0 and FP1
  first_ap_pos = _detectFirstAP(ch, symbol.metadata.side_version.x, fps[0], fps[1]);
  int side_version_x = _confirmSideVersion(symbol.metadata.side_version.x, first_ap_pos);
  if(side_version_x == 0) { //if failed, try the line between FP3 and FP2
    first_ap_pos = _detectFirstAP(ch, symbol.metadata.side_version.x, fps[3], fps[2]);
    side_version_x = _confirmSideVersion(symbol.metadata.side_version.x, first_ap_pos);
    if(side_version_x == 0) {
      return JAB_FAILURE;
    }
  }
  symbol.metadata.side_version.x = side_version_x;
  symbol.side_size.x = VERSION2SIZE(side_version_x);

  //side version y: scan the line between FP0 and FP3
  first_ap_pos = _detectFirstAP(ch, symbol.metadata.side_version.y, fps[0], fps[3]);
  int side_version_y = _confirmSideVersion(symbol.metadata.side_version.y, first_ap_pos);
  if(side_version_y == 0) { //if failed, try the line between FP1 and FP2
    first_ap_pos = _detectFirstAP(ch, symbol.metadata.side_version.y, fps[1], fps[2]);
    side_version_y = _confirmSideVersion(symbol.metadata.side_version.y, first_ap_pos);
    if(side_version_y == 0) {
      return JAB_FAILURE;
    }
  }
  symbol.metadata.side_version.y = side_version_y;
  symbol.side_size.y = VERSION2SIZE(side_version_y);

  return JAB_SUCCESS;
}

/*
 Sample a symbol using alignment patterns
 @param bitmap the image bitmap
 @param ch the binarized color channels of the image
 @param symbol the symbol to be sampled
 @param fps the finder patterns
 @return the sampled symbol matrix | NULL if failed
*/
jab_bitmap? _sampleSymbolByAlignmentPattern(jab_bitmap bitmap, List<jab_bitmap> ch, jab_decoded_symbol symbol, List<jab_finder_pattern> fps) {
	//if no alignment pattern available, abort
  if(symbol.metadata.side_version.x < 6 && symbol.metadata.side_version.y < 6) {
		return null; //No alignment pattern is available
	}

	//For default mode, first confirm the symbol side size
	if(symbol.metadata.default_mode)   {
    if(_confirmSymbolSize(ch, fps, symbol) == JAB_FAILURE) {
      return null; //The symbol size can not be recognized.
    }
  }

  int side_ver_x_index = symbol.metadata.side_version.x - 1;
	int side_ver_y_index = symbol.metadata.side_version.y - 1;
	int number_of_ap_x = jab_ap_num[side_ver_x_index];
  int number_of_ap_y = jab_ap_num[side_ver_y_index];

  //buffer for all possible alignment patterns
	var aps = List<jab_alignment_pattern>.filled (number_of_ap_x * number_of_ap_y, jab_alignment_pattern()); //jab_alignment_pattern *)malloc(number_of_ap_x * number_of_ap_y *sizeof(jab_alignment_pattern));

  //detect all APs
	for(int i=0; i<number_of_ap_y; i++) {
		for(int j=0; j<number_of_ap_x; j++) {
			int index = i * number_of_ap_x + j;
			if(i == 0 && j == 0) {
			  aps[index] = jab_alignment_pattern().import(fps[0]);
			} else if(i == 0 && j == number_of_ap_x - 1) {
			  aps[index] = jab_alignment_pattern().import(fps[1]);
			} else if(i == number_of_ap_y - 1 && j == number_of_ap_x - 1) {
			  aps[index] = jab_alignment_pattern().import(fps[2]);
			} else if(i == number_of_ap_y - 1 && j == 0) {
			  aps[index] = jab_alignment_pattern().import(fps[3]);
			} else {
				if(i == 0) {
					//direction: from aps[0][j-1] to fps[1]
					double distx = fps[1].center.x - aps[j-1].center.x;
					double disty = fps[1].center.y - aps[j-1].center.y;
					double alpha = atan2(disty, distx);
					//distance:  aps[0][j-1].module_size * module_number_between_APs
					double distance = aps[j-1].module_size * (jab_ap_pos[side_ver_x_index][j] - jab_ap_pos[side_ver_x_index][j-1]);
					//calculate the coordinate of ap[index]
					aps[index].center.x = aps[j-1].center.x + distance * cos(alpha);
					aps[index].center.y = aps[j-1].center.y + distance * sin(alpha);
					aps[index].module_size = aps[j-1].module_size;
				} else if(j == 0) {
					//direction: from aps[i-1][0] to fps[3]
					double distx = fps[3].center.x - aps[(i-1) * number_of_ap_x].center.x;
					double disty = fps[3].center.y - aps[(i-1) * number_of_ap_x].center.y;
					double alpha = atan2(disty, distx);
					//distance:  aps[i-1][0].module_size * module_number_between_APs
					double distance = aps[(i-1) * number_of_ap_x].module_size * (jab_ap_pos[side_ver_y_index][i] - jab_ap_pos[side_ver_y_index][i-1]);
					//calculate the coordinate of ap[index]
					aps[index].center.x = aps[(i-1) * number_of_ap_x].center.x + distance * cos(alpha);
					aps[index].center.y = aps[(i-1) * number_of_ap_x].center.y + distance * sin(alpha);
					aps[index].module_size = aps[(i-1) * number_of_ap_x].module_size;
				} else {
					//estimate the coordinate of ap[index] from aps[i-1][j-1], aps[i-1][j] and aps[i][j-1]
					int index_ap0 = (i-1) * number_of_ap_x + (j-1);	//ap at upper-left
					int index_ap1 = (i-1) * number_of_ap_x + j;		//ap at upper-right
					int index_ap3 = i * number_of_ap_x + (j-1);		//ap at left
					double ave_size_ap01 = (aps[index_ap0].module_size + aps[index_ap1].module_size) / 2.0;
					double ave_size_ap13 = (aps[index_ap1].module_size + aps[index_ap3].module_size) / 2.0;
					aps[index].center.x = (aps[index_ap1].center.x - aps[index_ap0].center.x) / ave_size_ap01 * ave_size_ap13 + aps[index_ap3].center.x;
					aps[index].center.y = (aps[index_ap1].center.y - aps[index_ap0].center.y) / ave_size_ap01 * ave_size_ap13 + aps[index_ap3].center.y;
					aps[index].module_size = ave_size_ap13;
				}
				//find aps[index]
				aps[index].found_count = 0;
				jab_alignment_pattern tmp = aps[index];
				aps[index] = _findAlignmentPattern(ch, aps[index].center.x, aps[index].center.y, aps[index].module_size, APX);
				if(aps[index].found_count == 0) {
					aps[index] = tmp;	//recover the estimated one
				}
			}
		}
	}

	//determine the minimal sampling rectangle for each block
	int block_number = (number_of_ap_x-1) * (number_of_ap_y-1);
	var rect = List<jab_vector2d>.filled(block_number * 2, jab_vector2d(0,0));
	int rect_index = 0;
	for(int i=0; i<number_of_ap_y-1; i++) {
    for(int j=0; j<number_of_ap_x-1; j++) {
      var tl=jab_vector2d(0,0);
      var br=jab_vector2d(0,0);
      bool flag = true;

      for(int delta=0; delta<=(number_of_ap_x-2 + number_of_ap_y-2) && flag; delta++) {
        for(int dy=0; dy<=min(delta, number_of_ap_y-2) && flag; dy++) {
          int dx = min(delta - dy, number_of_ap_x-2);
          for(int dy1=0; dy1<=dy && flag; dy1++) {
            int dy2 = dy - dy1;
            for(int dx1=0; dx1<=dx && flag; dx1++) {
              int dx2 = dx - dx1;

              tl.x = max(j - dx1, 0);
              tl.y = max(i - dy1, 0);
              br.x = min(j + 1 + dx2, number_of_ap_x - 1);
              br.y = min(i + 1 + dy2, number_of_ap_y - 1);
              if(aps[tl.y*number_of_ap_x + tl.x].found_count > 0 &&
                 aps[tl.y*number_of_ap_x + br.x].found_count > 0 &&
                 aps[br.y*number_of_ap_x + tl.x].found_count > 0 &&
                 aps[br.y*number_of_ap_x + br.x].found_count > 0)
              {
                flag = false;
              }
            }
          }
        }
      }
      //save the minimal rectangle if there is no duplicate
      bool dup_flag = false;
      for(int k=0; k<rect_index; k+=2) {
        if(rect[k].x == tl.x && rect[k].y == tl.y && rect[k+1].x == br.x && rect[k+1].y == br.y) {
          dup_flag = true;
          break;
        }
      }
      if(!dup_flag) {
        rect[rect_index] = tl;
        rect[rect_index+1] = br;
        rect_index += 2;
      }
    }
	}
	//sort the rectangles in descending order according to the size
	for(int i=0; i<rect_index-2; i+=2) {
		for(int j=0; j<rect_index-2-i; j+=2) {
			int size0 = (rect[j+1].x - rect[j].x) * (rect[j+1].y - rect[j].y);
			int size1 = (rect[j+2+1].x - rect[j+2].x) * (rect[j+2+1].y - rect[j+2].y);
			if(size1 > size0) {
				jab_vector2d tmp;
				//swap top-left
				tmp = rect[j];
				rect[j] = rect[j+2];
				rect[j+2] = tmp;
				//swap bottom-right
				tmp = rect[j+1];
				rect[j+1] = rect[j+2+1];
				rect[j+2+1] = tmp;
			}
		}
	}

	//allocate the buffer for the sampled matrix of the symbol
  int width = symbol.side_size.x;
	int height= symbol.side_size.y;
	int mtx_bytes_per_pixel = (bitmap.bits_per_pixel / 8).toInt();
	int mtx_bytes_per_row = width * mtx_bytes_per_pixel;

  var matrix = jab_bitmap(); //  (jab_bitmap*)malloc(sizeof(jab_bitmap) + width*height*mtx_bytes_per_pixel*sizeof(jab_byte));
  matrix.pixel = Uint8List(width*height);
	matrix.channel_count = bitmap.channel_count;
	matrix.bits_per_channel = bitmap.bits_per_channel;
	matrix.bits_per_pixel = matrix.bits_per_channel * matrix.channel_count;
	matrix.width = width;
	matrix.height= height;

	for(int i=0; i<rect_index; i+=2) {
		var blk_size = jab_vector2d(0, 0);
		var p0 = jab_point(0, 0);
    var p1 = jab_point(0, 0);
    var p2 = jab_point(0, 0);
    var p3 = jab_point(0, 0);

		//middle blocks
		blk_size.x = jab_ap_pos[side_ver_x_index][rect[i+1].x] - jab_ap_pos[side_ver_x_index][rect[i].x] + 1;
		blk_size.y = jab_ap_pos[side_ver_y_index][rect[i+1].y] - jab_ap_pos[side_ver_y_index][rect[i].y] + 1;
		p0.x = 0.5;
		p0.y = 0.5;
		p1.x = blk_size.x - 0.5;
		p1.y = 0.5;
		p2.x = blk_size.x - 0.5;
		p2.y = blk_size.y - 0.5;
		p3.x = 0.5;
		p3.y = blk_size.y - 0.5;
		//blocks on the top border row
		if(rect[i].y == 0) {
			blk_size.y += (DISTANCE_TO_BORDER - 1);
			p0.y = 3.5;
			p1.y = 3.5;
			p2.y = blk_size.y - 0.5;
			p3.y = blk_size.y - 0.5;
		}
		//blocks on the bottom border row
		if(rect[i+1].y == (number_of_ap_y-1)) {
			blk_size.y += (DISTANCE_TO_BORDER - 1);
			p2.y = blk_size.y - 3.5;
			p3.y = blk_size.y - 3.5;
		}
		//blocks on the left border column
		if(rect[i].x == 0) {
			blk_size.x += (DISTANCE_TO_BORDER - 1);
			p0.x = 3.5;
			p1.x = blk_size.x - 0.5;
			p2.x = blk_size.x - 0.5;
			p3.x = 3.5;
		}
		//blocks on the right border column
		if(rect[i+1].x == (number_of_ap_x-1)) {
			blk_size.x += (DISTANCE_TO_BORDER - 1);
			p1.x = blk_size.x - 3.5;
			p2.x = blk_size.x - 3.5;
		}
		//calculate perspective transform matrix for the current block
		var pt = perspectiveTransform(
					p0.x, p0.y,
					p1.x, p1.y,
					p2.x, p2.y,
					p3.x, p3.y,
					aps[rect[i+0].y*number_of_ap_x + rect[i+0].x].center.x, aps[rect[i+0].y*number_of_ap_x + rect[i+0].x].center.y,
					aps[rect[i+0].y*number_of_ap_x + rect[i+1].x].center.x, aps[rect[i+0].y*number_of_ap_x + rect[i+1].x].center.y,
					aps[rect[i+1].y*number_of_ap_x + rect[i+1].x].center.x, aps[rect[i+1].y*number_of_ap_x + rect[i+1].x].center.y,
					aps[rect[i+1].y*number_of_ap_x + rect[i+0].x].center.x, aps[rect[i+1].y*number_of_ap_x + rect[i+0].x].center.y);
		// if(pt == null) {
		// 	// free(aps);
		// 	// free(matrix);
		// 	return null;
		// }
		//sample the current block
		var block = sampleSymbol(bitmap, pt, blk_size);
		if (block == null) {
			return null; //Sampling block failed
		}
		//save the sampled block in the matrix
		int start_x = jab_ap_pos[side_ver_x_index][rect[i].x] - 1;
		int start_y = jab_ap_pos[side_ver_y_index][rect[i].y] - 1;
		if(rect[i].x == 0) {
		  start_x = 0;
		}
		if(rect[i].y == 0) {
		  start_y = 0;
		}
		int blk_bytes_per_pixel = block.bits_per_pixel ~/ 8;
		int blk_bytes_per_row = blk_size.x * mtx_bytes_per_pixel;
		for(int y=0, mtx_y=start_y; y<blk_size.y && mtx_y<height; y++, mtx_y++) {
			for(int x=0, mtx_x=start_x; x<blk_size.x && mtx_x<width; x++, mtx_x++) {
				int mtx_offset = mtx_y * mtx_bytes_per_row + mtx_x * mtx_bytes_per_pixel;
				int blk_offset = y * blk_bytes_per_row + x * blk_bytes_per_pixel;
				matrix.pixel[mtx_offset] 	  = block.pixel[blk_offset];
				matrix.pixel[mtx_offset + 1] = block.pixel[blk_offset + 1];
				matrix.pixel[mtx_offset + 2] = block.pixel[blk_offset + 2];
				matrix.pixel[mtx_offset + 3] = block.pixel[blk_offset + 3];
			}
		}
		// free(block);
	}

	return matrix;
}

/*
 Get the average pixel value around the found finder patterns
 @param bitmap the image bitmap
 @param fps the finder patterns
 @return rgb_ave the average pixel value
*/
List<double> _getAveragePixelValue(jab_bitmap bitmap, List<jab_finder_pattern> fps ) {
  var rgb_ave = List<double>.filled(3, 0);
  var r_ave = List<double>.filled(4, 0);
  var g_ave = List<double>.filled(4, 0);
  var b_ave = List<double>.filled(4, 0);

  //calculate average pixel value around each found FP
  for(int i=0; i<4; i++) {
    if(fps[i].found_count <= 0) continue;

    double radius = fps[i].module_size * 4;
    int start_x = (fps[i].center.x - radius) >= 0 ? (fps[i].center.x - radius).toInt() : 0;
    int start_y = (fps[i].center.y - radius) >= 0 ? (fps[i].center.y - radius).toInt() : 0;
    int end_x	  = (fps[i].center.x + radius) <= (bitmap.width - 1) ? (fps[i].center.x + radius).toInt() : (bitmap.width - 1);
    int end_y   = (fps[i].center.y + radius) <= (bitmap.height- 1) ? (fps[i].center.y + radius).toInt() : (bitmap.height- 1);
    int area_width = end_x - start_x;
    int area_height= end_y - start_y;

    int bytes_per_pixel = bitmap.bits_per_pixel ~/ 8;
    int bytes_per_row = bitmap.width * bytes_per_pixel;
    for(int y=start_y; y<end_y; y++) {
      for(int x=start_x; x<end_x; x++) {
        int offset = y * bytes_per_row + x * bytes_per_pixel;
        r_ave[i] += bitmap.pixel[offset + 0];
        g_ave[i] += bitmap.pixel[offset + 1];
        b_ave[i] += bitmap.pixel[offset + 2];
      }
    }
    r_ave[i] /= (area_width * area_height);
    g_ave[i] /= (area_width * area_height);
    b_ave[i] /= (area_width * area_height);
  }

  //calculate the average values of the average pixel values
  var rgb_sum = List<double>.filled(3, 0);
  var rgb_count = List<int>.filled(3, 0);
  for(int i=0; i<4; i++) {
    if(r_ave[i] > 0) {
      rgb_sum[0] += r_ave[i];
      rgb_count[0]++;
    }
    if(g_ave[i] > 0) {
      rgb_sum[1] += g_ave[i];
      rgb_count[1]++;
    }
    if(b_ave[i] > 0) {
      rgb_sum[2] += b_ave[i];
      rgb_count[2]++;
    }
  }
  if(rgb_count[0] > 0) rgb_ave[0] = rgb_sum[0] / rgb_count[0];
  if(rgb_count[1] > 0) rgb_ave[1] = rgb_sum[1] / rgb_count[1];
  if(rgb_count[2] > 0) rgb_ave[2] = rgb_sum[2] / rgb_count[2];

  return rgb_ave;
}



/*
 Detect and decode a master symbol
 @param bitmap the image bitmap
 @param ch the binarized color channels of the image
 @param master_symbol the master symbol
 @return JAB_SUCCESS | JAB_FAILURE
*/
int _detectMaster(jab_bitmap bitmap, List<jab_bitmap> ch, jab_decoded_symbol master_symbol) {
  //find master symbol
  var result = _findMasterSymbol(bitmap, ch, jab_detect_mode.INTENSIVE_DETECT);
  var status = result.item1;
  var fps = result.item2;
  if(status == FATAL_ERROR) {
    return JAB_FAILURE;
  } else if(status == JAB_FAILURE) {
    //calculate the average pixel value around the found FPs
    var rgb_ave = _getAveragePixelValue(bitmap, fps);
   //binarize the bitmap using the average pixel values as thresholds
    for(int i=0; i<3;i++) {
      ch[i]= jab_bitmap();
    }
    if(binarizerRGB(bitmap, ch, rgb_ave)==0) {
      return JAB_FAILURE;
    }
    //find master symbol
    result = _findMasterSymbol(bitmap, ch, jab_detect_mode.INTENSIVE_DETECT);
    status = result.item1;
    fps = result.item2;
    if(status == JAB_FAILURE || status == FATAL_ERROR) {
      return JAB_FAILURE;
    }
  }

  //calculate the master symbol side size
  jab_vector2d side_size = _calculateSideSize(fps);
  if(side_size.x == -1 || side_size.y == -1) {
    return JAB_FAILURE; //Calculating side size failed
  }

  //try decoding using only finder patterns
  //calculate perspective transform matrix
  var pt = getPerspectiveTransform(fps[0].center, fps[1].center, fps[2].center, fps[3].center, side_size);
  // if(pt == null) {
  //   // free(fps);
  //   return JAB_FAILURE;
  // }

	//sample master symbol
	var matrix = sampleSymbol(bitmap, pt, side_size);
	if(matrix == null) {
		return JAB_FAILURE; //Sampling master symbol failed
	}

	//save the detection result
	master_symbol.index = 0;
	master_symbol.host_index = 0;
	master_symbol.side_size = side_size;
	master_symbol.module_size = (fps[0].module_size + fps[1].module_size + fps[2].module_size + fps[3].module_size) / 4.0;
	master_symbol.pattern_positions[0] = fps[0].center;
	master_symbol.pattern_positions[1] = fps[1].center;
	master_symbol.pattern_positions[2] = fps[2].center;
	master_symbol.pattern_positions[3] = fps[3].center;

	//decode master symbol
	int decode_result = decodeMaster(matrix, master_symbol);
	// free(matrix);
	if(decode_result == JAB_SUCCESS) {
		return JAB_SUCCESS;
	} else if(decode_result < 0) {	//fatal error occurred
		return JAB_FAILURE;
	} else { //if decoding using only finder patterns failed, try decoding using alignment patterns
  master_symbol.side_size.x = VERSION2SIZE(master_symbol.metadata.side_version.x);
  master_symbol.side_size.y = VERSION2SIZE(master_symbol.metadata.side_version.y);
  matrix = _sampleSymbolByAlignmentPattern(bitmap, ch, master_symbol, fps);
  if(matrix == null) {
    return JAB_FAILURE;
  }
  decode_result = decodeMaster(matrix, master_symbol);
  if(decode_result == JAB_SUCCESS) {
    return JAB_SUCCESS;
  } else {
    return JAB_FAILURE;
  }
	}
}

/*
 Detect a slave symbol
 @param bitmap the image bitmap
 @param ch the binarized color channels of the image
 @param host_symbol the host symbol
 @param slave_symbol the slave symbol
 @param docked_position the docked position
 @return item1 the sampled slave symbol matrix | NULL if failed
 @return item2 host_symbol the host symbol
 @return item3 slave_symbol the slave symbol
 *
*/
Tuple3<jab_bitmap?, jab_decoded_symbol, jab_decoded_symbol> _detectSlave(jab_bitmap bitmap, List<jab_bitmap> ch, jab_decoded_symbol host_symbol, jab_decoded_symbol slave_symbol, int docked_position) {
  if(docked_position < 0 || docked_position > 3) {
    // reportError("Wrong docking position");
    return Tuple3<jab_bitmap?, jab_decoded_symbol, jab_decoded_symbol>(null, host_symbol, slave_symbol);
  }

  //find slave symbol next to the host symbol
  if(_findSlaveSymbol(bitmap, ch, host_symbol, slave_symbol, docked_position) == JAB_FAILURE) {
    return Tuple3<jab_bitmap?, jab_decoded_symbol, jab_decoded_symbol>(null, host_symbol, slave_symbol); //"Slave symbol %d not found", slave_symbol.index
  }

  //calculate perspective transform matrix
  var pt = getPerspectiveTransform(slave_symbol.pattern_positions[0], slave_symbol.pattern_positions[1],
                                                          slave_symbol.pattern_positions[2], slave_symbol.pattern_positions[3],
                                                          slave_symbol.side_size);
  // if(pt == null) {
  //   return null;
  // }

  //sample slave symbol
  jab_bitmap? matrix = sampleSymbol(bitmap, pt, slave_symbol.side_size);
  if(matrix == null) {
    return Tuple3<jab_bitmap?, jab_decoded_symbol, jab_decoded_symbol>(null, host_symbol, slave_symbol); //Sampling slave symbol %d failed", slave_symbol.index
  }

  return Tuple3<jab_bitmap?, jab_decoded_symbol, jab_decoded_symbol>(matrix, host_symbol, slave_symbol);
}

/*
 Decode docked slave symbols around a host symbol
 @param bitmap the image bitmap
 @param ch the binarized color channels of the image
 @param symbols the symbol list
 @param host_index the index number of the host symbol
 @param total the number of symbols in the list
 @return item1 JAB_SUCCESS | JAB_FAILURE
 @return item2 total the number of symbols in the list
*/
Tuple2<int, int> _decodeDockedSlaves(jab_bitmap bitmap, List<jab_bitmap> ch, List<jab_decoded_symbol> symbols, int host_index, int total) {
  var docked_positions = List<int>.filled(4, 0);
  docked_positions[0] = symbols[host_index].metadata.docked_position & 0x08;
  docked_positions[1] = symbols[host_index].metadata.docked_position & 0x04;
  docked_positions[2] = symbols[host_index].metadata.docked_position & 0x02;
  docked_positions[3] = symbols[host_index].metadata.docked_position & 0x01;

  for(int j=0; j<4; j++) {
    if(docked_positions[j] > 0 && total<MAX_SYMBOL_NUMBER) {
      symbols[total].index = total;
      symbols[total].host_index = host_index;
      symbols[total].metadata = symbols[host_index].slave_metadata[j];
      var result = _detectSlave(bitmap, ch, symbols[host_index], symbols[total], j);
      jab_bitmap? matrix = result.item1;
      symbols[host_index] = result.item2;
      symbols[total] = result.item3;
      if(matrix == null) {
        return Tuple2<int, int>(JAB_FAILURE, total); //Detecting slave symbol %d failed", symbols[*total].index
      }
      if(decodeSlave(matrix, symbols[total]) == JAB_SUCCESS) {
        total++;
      } else {
        return Tuple2<int, int>(JAB_FAILURE, total);
      }
    }
  }
  return Tuple2<int, int>(JAB_SUCCESS, total);
}



/*
 Extended function to decode a JAB Code
 @param bitmap the image bitmap
 @param mode the decoding mode(NORMAL_DECODE: only output completely decoded data when all symbols are correctly decoded
 *								 COMPATIBLE_DECODE: also output partly decoded data even if some symbols are not correctly decoded
 @param symbols the decoded symbols
 @param max_symbol_number the maximal possible number of symbols to be decoded
 @return item1 the decoded data | NULL if failed
 @return item2 status the decoding status code (0: not detectable, 1: not decodable, 2: partly decoded with COMPATIBLE_DECODE mode, 3: fully decoded)
*/
Tuple2<jab_data?, int>? _decodeJABCodeEx(jab_bitmap bitmap, int mode, List<jab_decoded_symbol>? symbols) {
	int status = 0;
	if(symbols == null) {
	  return null;
	}

	//binarize r, g, b channels
	var ch = List<jab_bitmap>.filled(3, jab_bitmap());
	balanceRGB(bitmap);
  if (binarizerRGB(bitmap, ch, null) == 0) {
    return null;
  }

  int total = 0;	//total number of decoded symbols
  bool res = true;

  //detect and decode master symbol
  if(_detectMaster(bitmap, ch, symbols[0]) == JAB_SUCCESS) {
    total++;
  }

  //detect and decode docked slave symbols recursively
  if(total>0) {
    for(int i=0; i<total && total<symbols.length; i++) {
      var result = _decodeDockedSlaves(bitmap, ch, symbols, i, total);
      total= result.item2;
      if(result.item1 == JAB_FAILURE) {
        res = false;
        break;
     }
    }
  }

    //check result
	if(total == 0 || (mode == NORMAL_DECODE && !res)) {
		if(symbols[0].module_size > 0 && status != 0) {
		  status = 1;
		}
		// //clean memory
		// for(int i=0; i<3;
    //   ch[i++]= null);
		// for(int i=0; i<=min(total, symbols.length-1); i++) {
		// 	symbols[i]?.palette= null;
		// 	symbols[i]?.data= null;
		// }
    return null;
	}
	if(mode == COMPATIBLE_DECODE && !res) {
		if(status!=0) status = 2;
		res = true;
	}

	//concatenate the decoded data
  int total_data_length = 0;
  for(int i=0; i<total; i++) {
    total_data_length += symbols[i].data.length;
  }
  var decoded_bits = jab_data(); //(jab_data *)malloc(sizeof(jab_data) + total_data_length * sizeof(jab_char));
	decoded_bits.data = Uint8List(total_data_length);
  // if(decoded_bits == null) {
  //   if(status!=0) status = 1;
  //   return Tuple2<jab_data?, int>(null, status);
  // }
  int offset = 0;
  for(int i=0; i<total; i++) {
    var src = symbols[i].data.data;
    var dst = decoded_bits.data;
    // dst += offset;
    dst.setRange(offset, symbols[i].data.length, src); // memcpy(dst, src, symbols[i].data.length);
    offset += symbols[i].data.length;
  }
  decoded_bits.length = total_data_length;
  //decode data
  var decoded_data = decodeData(decoded_bits);
  if(decoded_data == null) {
    if(status != 0) status = 1; //Decoding data failed
    res = false;
  }

  // //clean memory
  // for(int i=0; i<3; ch[i++]=null);
  // for(int i=0; i<=min(total, symbols.length-1); i++) {
  //   symbols[i].palette= null;
  //   symbols[i].data= null;
  // }
	if(!res) {
	  return Tuple2<jab_data?, int>(null, status);
	}
	if(status != 0) {
		if(status != 2) {
		  status = 3;
		}
	}
  return Tuple2<jab_data?, int>(decoded_data, status);
}

/*
 Decode a JAB Code
 @param bitmap the image bitmap
 @param mode the decoding mode(NORMAL_DECODE: only output completely decoded data when all symbols are correctly decoded
 								 COMPATIBLE_DECODE: also output partly decoded data even if some symbols are not correctly decoded
 @return item1 the decoded data | NULL if failed
 @return item2 status the decoding status code (0: not detectable, 1: not decodable, 2: partly decoded with COMPATIBLE_DECODE mode, 3: fully decoded)
*/
Tuple2<jab_data?, int>? decodeJABCode(jab_bitmap bitmap, int mode) {
  var symbols = List<jab_decoded_symbol>.filled(MAX_SYMBOL_NUMBER, jab_decoded_symbol());
	return _decodeJABCodeEx(bitmap, mode, symbols);
}
