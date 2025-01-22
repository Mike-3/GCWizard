/*
 libjabcode - JABCode Encoding/Decoding Library

 Copyright 2016 by Fraunhofer SIT. All rights reserved.
 See LICENSE file for full terms of use and distribution.

 Contact: Huajian Liu <liu@sit.fraunhofer.de>
 			Waldemar Berchtold <waldemar.berchtold@sit.fraunhofer.de>

 Symbol encoding
*/


import 'dart:core';
import 'dart:math';
import 'dart:typed_data';

import 'package:gc_wizard/tools/images_and_files/jabcode/logic/decoder.dart';
import 'package:gc_wizard/tools/images_and_files/jabcode/logic/decoder_h.dart';
import 'package:gc_wizard/tools/images_and_files/jabcode/logic/encoder_h.dart';
import 'package:gc_wizard/tools/images_and_files/jabcode/logic/interleave.dart';
import 'package:gc_wizard/tools/images_and_files/jabcode/logic/jabcode_h.dart';
import 'package:gc_wizard/tools/images_and_files/jabcode/logic/ldpc.dart';
import 'package:gc_wizard/tools/images_and_files/jabcode/logic/mask.dart';

/*
 Generate color palettes with more than 8 colors
 @param color_number the number of colors
 @param palette the color palette
*/
void _genColorPalette(int color_number, Int8List palette){
	if(color_number < 8) {
	  return;
	}

	int vr, vg, vb;	//the number of variable colors for r, g, b channels
	switch(color_number) {
	case 16:
		vr = 4;
		vg = 2;
		vb = 2;
		break;
	case 32:
		vr = 4;
		vg = 4;
		vb = 2;
		break;
	case 64:
		vr = 4;
		vg = 4;
		vb = 4;
		break;
	case 128:
		vr = 8;
		vg = 4;
		vb = 4;
		break;
	case 256:
		vr = 8;
		vg = 8;
		vb = 4;
		break;
	default:
		return;
	}

	double dr, dg, db;	//the pixel value interval for r, g, b channels
	dr = (vr - 1) == 3 ? 85 : 256 / (vr - 1);
	dg = (vg - 1) == 3 ? 85 : 256 / (vg - 1);
	db = (vb - 1) == 3 ? 85 : 256 / (vb - 1);

	int r, g, b;		//pixel value
	int index = 0;	//palette index
	for(int i=0; i<vr; i++) {
		r = min((dr * i).toInt(), 255);
		for(int j=0; j<vg; j++) {
			g = min((dg * j).toInt(), 255);
			for(int k=0; k<vb; k++) {
				b = min((db * k).toInt(), 255);
				palette[index++] = r;
				palette[index++] = g;
				palette[index++] = b;
			}
		}
	}
}

/*
 Set default color palette
 @param color_number the number of colors
 @param palette the color palette
*/
void _setDefaultPalette(int color_number, Int8List palette) {
  if(color_number == 4) {
    palette.setRange(0, 0+3, jab_default_palette.sublist(FP0_CORE_COLOR * 3)); //black   000 for 00 // memcpy(palette + 0, jab_default_palette + FP0_CORE_COLOR * 3, 3);	//black   000 for 00
    palette.setRange(3, 3+3, jab_default_palette.sublist(5 * 3)); //magenta 101 for 01 //memcpy(palette + 3, jab_default_palette + 5 * 3, 3);				//magenta 101 for 01
    palette.setRange(6, 6+3, jab_default_palette.sublist(FP2_CORE_COLOR * 3)); 	//yellow  110 for 10 memcpy(palette + 6, jab_default_palette + FP2_CORE_COLOR * 3, 3);	//yellow  110 for 10
    palette.setRange(9, 9+3, jab_default_palette.sublist(FP3_CORE_COLOR * 3)); 	//cyan    011 for 11 memcpy(palette + 9, jab_default_palette + FP3_CORE_COLOR * 3, 3);	//cyan    011 for 11
  } else if(color_number == 8) {
    for(int i=0; i<color_number*3; i++) {
      palette[i] = jab_default_palette[i];
    }
  } else {
    _genColorPalette(color_number, palette);
  }
}

/*
 Set default error correction levels
 @param symbol_number the number of symbols
 @param ecc_levels the ecc_level for each symbol
*/
void _setDefaultEccLevels(int symbol_number, Int8List ecc_levels){
  ecc_levels = Int8List(symbol_number);
}

/*
 Swap two integer elements
 @param index1 the first index
 @param index2 the second index2
*/
void _swap_int(int index1, int index2, Int32List list) {
  int temp= list[index1];
  list[index1]=list[index2];
  list[index2]=temp;
}

/*
 Swap two byte elements
 @param index1 the first index
 @param index2 the second index2
*/
void _swap_int8(int index1, int index2, Int8List list) {
  int temp= list[index1];
  list[index1]=list[index2];
  list[index2]=temp;
}

/*
 Swap two vector2d
 @param index1 the first index
 @param index2 the second index2
*/
void _swap_vector_2D(int index1, int index2, List<jab_vector2d> list) {
  jab_vector2d temp= list[index1];
  list[index1]=list[index2];
  list[index2]=temp;
}


/*
 Convert decimal to binary
 @param dec the decimal value
 @param bin the data in binary representation
 @param start_position the position to write in encoded data array
 @param length the length of the converted binary sequence
*/
void _convert_dec_to_bin(int dec, Uint8List bin, int start_position, int length) {
  if(dec < 0) dec += 256;
  for (int j=0; j<length; j++) {
    int t = dec % 2;
    bin[start_position+length-1-j] = t;
    dec = dec~/2;
  }
}

/*
 Create encode object
 @param color_number the number of module colors
 @param symbol_number the number of symbols
 @return the created encode parameter object | null: fatal error (out of memory)
*/
jab_encode createEncode(int color_number, int symbol_number) {
  var enc = jab_encode();
  // if(enc == null) {
  //   return null;
  // }

  if(color_number != 4  && color_number != 8   && color_number != 16 &&
     color_number != 32 && color_number != 64 && color_number != 128 && color_number != 256)
  {
    color_number = DEFAULT_COLOR_NUMBER;
  }
  if(symbol_number < 1 || symbol_number > MAX_SYMBOL_NUMBER) {
    symbol_number = DEFAULT_SYMBOL_NUMBER;
  }

  enc.color_number 		 = color_number;
  enc.symbol_number 		 = symbol_number;
  enc.master_symbol_width = 0;
  enc.master_symbol_height= 0;
  enc.module_size 		 = DEFAULT_MODULE_SIZE;

  //set default color palette
  enc.palette = Int8List(color_number * 3);
  // if(enc.palette == null) {
  //   // reportError("Memory allocation for palette failed");
  //   return null;
  // }
  _setDefaultPalette(enc.color_number, enc.palette!);
  //allocate memory for symbol versions
  enc.symbol_versions = List<jab_vector2d>.filled(symbol_number, jab_vector2d(0,0));
  // if(enc.symbol_versions == null) {
  //   // reportError("Memory allocation for symbol versions failed");
  //   return null;
  // }
  //set default error correction levels
  enc.symbol_ecc_levels = Int8List(symbol_number);
  // if(enc.symbol_ecc_levels == null) {
  //   // reportError("Memory allocation for ecc levels failed");
  //   return null;
  // }
  _setDefaultEccLevels(enc.symbol_number, enc.symbol_ecc_levels);
  //allocate memory for symbol positions
  enc.symbol_positions= Int32List(symbol_number);
  // if(enc.symbol_positions == null) {
  //   // reportError("Memory allocation for symbol positions failed");
  //   return null;
  // }
  //allocate memory for symbols
  enc.symbols = List<jab_symbol>.filled(symbol_number, jab_symbol());
  // if(enc.symbols == null) {
  //   // reportError("Memory allocation for symbols failed");
  //   return null;
  // }
  return enc;
}

/*
 Analyze the input data and determine the optimal encoding modes for each character
 @param input the input character data
 @param encoded_length the shortest encoding length
 @return the optimal encoding sequence | null: fatal error (out of memory)
*/
List<int>? _analyzeInputData(jab_data input, int encoded_length) {
  int encode_seq_length=ENC_MAX;
  var seq = Uint8List(input.length); //(jab_char *)malloc(sizeof(jab_char)*input.length);
  var curr_seq_len= List<int>.filled((input.length+2)*14, 0);
  var prev_mode=List<int>.filled(((2*input.length+2)*14), 0);

  for (int i=0; i < (2*input.length+2)*14; i++) {
    prev_mode[i] = ENC_MAX~/2;
  }

  var switch_mode = List<int>.filled(28, 0);

  for (int i=0; i < 28; i++) {
    switch_mode[i] = ENC_MAX~/2;
  }
  var temp_switch_mode = List<int>.filled(28, 0);

  for (int i=0; i < 28; i++) {
    temp_switch_mode[i] = ENC_MAX~/2;
  }

  //calculate the shortest encoding sequence
  //initialize start in upper case mode; no previous mode available
  for (int k=0;k<7;k++) {
    curr_seq_len[k]=curr_seq_len[k+7]=ENC_MAX;
    prev_mode[k]=prev_mode[k+7]=ENC_MAX;
  }

  curr_seq_len[0]=0;
  int jp_to_nxt_char=0, confirm=0;
  int curr_seq_counter=0;
  bool is_shift=false;
  int nb_char=0;
  int end_of_loop=input.length;
  int prev_mode_index=0;
  for (int i=0;i<end_of_loop;i++) {
    int tmp=input.data[nb_char];
    int tmp1=0;
    if(nb_char+1 < input.length) {
      tmp1=input.data[nb_char+1];
    }
    if(tmp<0) {
      tmp=256+tmp;
    }
    if(tmp1<0) {
      tmp1=256+tmp1;
    }
    curr_seq_counter++;
    for (int j=0;j<JAB_ENCODING_MODES;j++) {
      if (jab_enconing_table[tmp][j]>-1 && jab_enconing_table[tmp][j]<64) {
        //check if character is in encoding table
        curr_seq_len[(i+1)*14+j]=curr_seq_len[(i+1)*14+j+7]=character_size[j];
      } else if((jab_enconing_table[tmp][j]==-18 && tmp1==10) || (jab_enconing_table[tmp][j]<-18 && tmp1==32)) { //read next character to decide if encodalbe in current mode
        curr_seq_len[(i+1)*14+j]=curr_seq_len[(i+1)*14+j+7]=character_size[j];
        jp_to_nxt_char=1; //jump to next character
      } else {
        //not encodable in this mode
        curr_seq_len[(i+1)*14+j]=curr_seq_len[(i+1)*14+j+7]=ENC_MAX;
      }
    }
    curr_seq_len[(i+1)*14+6]=curr_seq_len[(i+1)*14+13]=character_size[6]; //input sequence can always be encoded by byte mode
    is_shift=false;
    for (int j=0;j<14;j++) {
      int prev=-1;
      int len=curr_seq_len[(i+1)*14+j]+curr_seq_len[i*14+j]+latch_shift_to[j][j];
      prev_mode[curr_seq_counter*14+j]=j;
      for (int k=0;k<14;k++) {
        if((len>=curr_seq_len[(i+1)*14+j]+curr_seq_len[i*14+k]+latch_shift_to[k][j] && k<13) || (k==13 && prev==j)) {
          len=curr_seq_len[(i+1)*14+j]+curr_seq_len[i*14+k]+latch_shift_to[k][j];
          if (temp_switch_mode[2*k]==k) {
            prev_mode[curr_seq_counter*14+j]=temp_switch_mode[2*k+1];
          } else {
            prev_mode[curr_seq_counter*14+j]=k;
          }
          if (k==13 && prev==j) {
            prev=-1;
          }
        }
      }
      curr_seq_len[(i+1)*14+j]=len;
      //shift back to mode if shift is used
      if (j>6) {
        if ((curr_seq_len[(i+1)*14+prev_mode[curr_seq_counter*14+j]]>len ||
          (jp_to_nxt_char==1 && curr_seq_len[(i+1)*14+prev_mode[curr_seq_counter*14+j]]+character_size[(prev_mode[curr_seq_counter*14+j])%7]>len)) &&
           j != 13)
        {
          int index=prev_mode[curr_seq_counter*14+j];
          int loop=1;
          while (index>6 && curr_seq_counter-loop >= 0) {
            index=prev_mode[(curr_seq_counter-loop)*14+index];
            loop++;
          }

          curr_seq_len[(i+1)*14+index]=len;
          prev_mode[(curr_seq_counter+1)*14+index]=j;
          switch_mode[2*index]=index;
          switch_mode[2*index+1]=j;
          is_shift=true;
          if(jp_to_nxt_char==1 && j==11) {
              confirm=1;
              prev_mode_index=index;
          }
        } else if ((curr_seq_len[(i+1)*14+prev_mode[curr_seq_counter*14+j]]>len ||
                (jp_to_nxt_char==1 && curr_seq_len[(i+1)*14+prev_mode[curr_seq_counter*14+j]]+character_size[prev_mode[curr_seq_counter*14+j]%7]>len)) && j == 13 ) {
          curr_seq_len[(i+1)*14+prev_mode[curr_seq_counter*14+j]]=len;
          prev_mode[(curr_seq_counter+1)*14+prev_mode[curr_seq_counter*14+j]]=j;
          switch_mode[2*prev_mode[curr_seq_counter*14+j]]=prev_mode[curr_seq_counter*14+j];
          switch_mode[2*prev_mode[curr_seq_counter*14+j]+1]=j;
          is_shift=true;
        }
        if(j!=13) {
          curr_seq_len[(i+1)*14+j]=ENC_MAX;
        } else {
          prev=prev_mode[curr_seq_counter*14+j];
        }
      }
    }
    for (int j=0;j<28;j++) {
      temp_switch_mode[j]=switch_mode[j];
      switch_mode[j]=ENC_MAX~/2;
    }

    if(jp_to_nxt_char==1 && confirm==1) {
      for (int j=0;j<=2*JAB_ENCODING_MODES+1;j++) {
        if(j != prev_mode_index) {
          curr_seq_len[(i+1)*14+j]=ENC_MAX;
        }
      }
      nb_char++;
      end_of_loop--;
    }
    jp_to_nxt_char=0;
    confirm=0;
    nb_char++;
  }

  //pick smallest number in last step
  int current_mode=0;
  for (int j=0;j<=2*JAB_ENCODING_MODES+1;j++) {
    if (encode_seq_length>curr_seq_len[(nb_char-(input.length-end_of_loop))*14+j]) {
      encode_seq_length=curr_seq_len[(nb_char-(input.length-end_of_loop))*14+j];
      current_mode=j;
    }
  }
  if(current_mode>6) {
    is_shift=true;
  }
  if (is_shift && temp_switch_mode[2*current_mode+1]<14) {
    current_mode=temp_switch_mode[2*current_mode+1];
  }

  var encode_seq = List<int>.filled((curr_seq_counter+1+ (is_shift ? 1: 0)), 0);
  // if(encode_seq == null) {
  //   // reportError("Memory allocation for encode sequence failed");
  //   return null;
  // }

  //check if byte mode is used more than 15 times in sequence
  //.>length will be increased by 13
  int counter=0;
  int seq_len=0;
  int modeswitch=0;
  encode_seq[curr_seq_counter]=current_mode;//prev_mode[(curr_seq_counter)*14+current_mode];//prev_mode[(curr_seq_counter+is_shift-1)*14+current_mode];
  seq_len+=character_size[encode_seq[curr_seq_counter]%7];
  for (int i=curr_seq_counter;i>0;i--) {
    if (encode_seq[i]==13 || encode_seq[i]==6) {
      counter++;
    } else {
      if(counter>15) {
        encode_seq_length+=13;
        seq_len+=13;

        //--------------------------------
        if(counter>8207) {//2^13+15
          if (encode_seq[i]==0 || encode_seq[i]==1 || encode_seq[i]==7 || encode_seq[i]==8) {
            modeswitch=11;
          }
          if (encode_seq[i]==2 || encode_seq[i]==9) {
            modeswitch=10;
          }
          if (encode_seq[i]==5 || encode_seq[i]==12) {
            modeswitch=12;
          }
          int remain_in_byte_mode=counter~/8207;
          int remain_in_byte_mode_residual=counter%8207;
          encode_seq_length+=(remain_in_byte_mode) * modeswitch;
          seq_len+=(remain_in_byte_mode) * modeswitch;
          if(remain_in_byte_mode_residual<16) {
            encode_seq_length+=(remain_in_byte_mode-1) * 13;
            seq_len+=(remain_in_byte_mode-1) * 13;
          } else {
            encode_seq_length+=remain_in_byte_mode * 13;
            seq_len+=remain_in_byte_mode * 13;
          }
          if(remain_in_byte_mode_residual==0) {
            encode_seq_length-= modeswitch;
            seq_len-= modeswitch;
          }
        }
        //--------------------------------
        counter=0;
      }
    }
    if (encode_seq[i]<14 && i-1!=0) {
      encode_seq[i-1]=prev_mode[i*14+encode_seq[i]];
      seq_len+=character_size[encode_seq[i-1]%7];
      if(encode_seq[i-1]!=encode_seq[i]) {
        seq_len+=latch_shift_to[encode_seq[i-1]][encode_seq[i]];
      }
    } else if (i-1==0) {
      encode_seq[i-1]=0;
      if(encode_seq[i-1]!=encode_seq[i]) {
        seq_len+=latch_shift_to[encode_seq[i-1]][encode_seq[i]];
      }
      if(counter>15) {
        encode_seq_length+=13;
        seq_len+=13;

        //--------------------------------
        if(counter>8207) { //2^13+15

          modeswitch=11;
          int remain_in_byte_mode=counter~/8207;
          int remain_in_byte_mode_residual=counter%8207;
          encode_seq_length+=remain_in_byte_mode * modeswitch;
          seq_len+=remain_in_byte_mode * modeswitch;
          if(remain_in_byte_mode_residual<16)
          {
            encode_seq_length+=(remain_in_byte_mode-1) * 13;
            seq_len+=(remain_in_byte_mode-1) * 13;
          } else {
            encode_seq_length+=remain_in_byte_mode * 13;
            seq_len+=remain_in_byte_mode * 13;
          }
          if(remain_in_byte_mode_residual==0) {
            encode_seq_length-= modeswitch;
            seq_len-= modeswitch;
          }
        }
        //--------------------------------
        counter=0;
      }
    } else {
      return null;
    }
  }
  encoded_length=encode_seq_length;
  return encode_seq;
}

/*
 Check if master symbol shall be encoded in default mode
 @param enc the encode parameters
 @return JAB_SUCCESS | JAB_FAILURE
*/
int _isDefaultMode(jab_encode enc) {
	if(enc.color_number == 8 && (enc.symbol_ecc_levels[0] == 0 || enc.symbol_ecc_levels[0] == DEFAULT_ECC_LEVEL)) {
		return JAB_SUCCESS;
	}
	return JAB_FAILURE;
}

/*
 Calculate the (encoded) metadata length
 @param enc the encode parameters
 @param index the symbol index
 @return the metadata length (encoded length for master symbol)
*/
int _getMetadataLength(jab_encode enc, int index){
  int length = 0;

  if (index == 0) { //master symbol, the encoded length
    //default mode, no metadata
    if(_isDefaultMode(enc) == JAB_SUCCESS) {
      length = 0;
    } else {
      //Part I
      length += MASTER_METADATA_PART1_LENGTH;
      //Part II
      length += MASTER_METADATA_PART2_LENGTH;
    }
  } else { //slave symbol, the original net length
    //Part I
    length += 2;
    //Part II
    int host_index = enc.symbols[index].host;
    //V in Part II, compare symbol shape and size with host symbol
    if (enc.symbol_versions[index].x != enc.symbol_versions[host_index].x || enc.symbol_versions[index].y != enc.symbol_versions[host_index].y) {
      length += 5;
    }

    //E in Part II
    if (enc.symbol_ecc_levels[index] != enc.symbol_ecc_levels[host_index]) {
      length += 6;
    }
  }
  return length;
}

/*
 Calculate the data capacity of a symbol
 @param enc the encode parameters
 @param index the symbol index
 @return the data capacity
*/
int _getSymbolCapacity(jab_encode enc, int index) {
	//number of modules for finder patterns
  int nb_modules_fp;
  if(index == 0) {	//master symbol
		nb_modules_fp = 4 * 17;
	} else {			//slave symbol
		nb_modules_fp = 4 * 7;
	}
    //number of modules for color palette
  int nb_modules_palette = enc.color_number > 64 ? (64-2)*COLOR_PALETTE_NUMBER : (enc.color_number-2)*COLOR_PALETTE_NUMBER;
	//number of modules for alignment pattern
	int side_size_x = VERSION2SIZE(enc.symbol_versions[index].x);
	int side_size_y = VERSION2SIZE(enc.symbol_versions[index].y);
	int number_of_aps_x = jab_ap_num[enc.symbol_versions[index].x - 1];
	int number_of_aps_y = jab_ap_num[enc.symbol_versions[index].y - 1];
	int nb_modules_ap = (number_of_aps_x * number_of_aps_y - 4) * 7;
	//number of modules for metadata
	int nb_of_bpm = log(enc.color_number) ~/ log(2);
	int nb_modules_metadata = 0;
	if(index == 0) {	//master symbol
		int nb_metadata_bits = _getMetadataLength(enc, index);
		if(nb_metadata_bits > 0) {
			nb_modules_metadata = (nb_metadata_bits - MASTER_METADATA_PART1_LENGTH) ~/ nb_of_bpm; //only modules for PartII
			if((nb_metadata_bits - MASTER_METADATA_PART1_LENGTH) % nb_of_bpm != 0) {
				nb_modules_metadata++;
			}
			nb_modules_metadata += MASTER_METADATA_PART1_MODULE_NUMBER; //add modules for PartI
		}
	}
	int capacity = (side_size_x*side_size_y - nb_modules_fp - nb_modules_ap - nb_modules_palette - nb_modules_metadata) * nb_of_bpm;
	return capacity;
}

/*
 Get the optimal error correction capability
 @param capacity the symbol capacity
 @param net_data_length the original data length
 @param wcwr the LPDC parameters wc and wr
*/
void _getOptimalECC(int capacity, int net_data_length, List<int> wcwr) {
	double min = capacity.toDouble();
	for (int k=3; k<=6+2; k++) {
		for (int j=k+1; j<=6+3; j++) {
			double dist = (capacity/j)*j - (capacity/j)*k - net_data_length; //max_gross_payload = floor(capacity / wr) * wr
			if(dist<min && dist>=0) {
				wcwr[1] = j;
				wcwr[0] = k;
				min = dist;
			}
		}
	}
}

/*
 Encode the input data
 @param data the character input data
 @param encoded_length the optimal encoding length
 @param encode_seq the optimal encoding sequence
 @return the encoded data | null if failed
*/
jab_data? _encodeData(jab_data data, int encoded_length,List<int> encode_seq) {
  var encoded_data = jab_data();//List<jab_data>.filled ()jab_data *)malloc(sizeof(jab_data) + encoded_length*sizeof(jab_char));
  encoded_data.data = Uint8List(encoded_length);
  // if(encoded_data == null) {
  //   // reportError("Memory allocation for encoded data failed");
  //   return null;
  // }
  encoded_data.length = encoded_length;

  int counter=0;
  bool shift_back=false;
  int position=0;
  int current_encoded_length=0;
  int end_of_loop=data.length;
  int byte_offset=0;
  int byte_counter=0;
  int factor=1;
  //encoding starts in upper case mode
  for (int i=0;i<end_of_loop;i++) {
    int tmp=data.data[current_encoded_length];
    if (tmp < 0) {
      tmp += 256;
    }
    if (position<encoded_length) {
      int decimal_value;
      //check if mode is switched
      if (encode_seq[counter] != encode_seq[counter+1]) {
        //encode mode switch
        int length=latch_shift_to[encode_seq[counter]][encode_seq[counter+1]];
        if(encode_seq[counter+1] == 6 || encode_seq[counter+1] == 13) {
          length -= 4;
        }
        if(length < ENC_MAX) {
          _convert_dec_to_bin(mode_switch[encode_seq[counter]][encode_seq[counter+1]],encoded_data.data,position,length);
        } else {
          return null; //Encoding data failed
        }
        position+=latch_shift_to[encode_seq[counter]][encode_seq[counter+1]];
        if(encode_seq[counter+1] == 6 || encode_seq[counter+1] == 13) {
          position -= 4;
        }
        //check if latch or shift
        if((encode_seq[counter+1]>6 && encode_seq[counter+1]<=13) || (encode_seq[counter+1]==13 && encode_seq[counter+2]!=13)) {
          shift_back = true;//remember to shift back to mode from which was invoked
        }
      }
      //if not byte mode
      if (encode_seq[counter+1]%7 != 6) { // || end_of_loop-1 == i)
        if(jab_enconing_table[tmp][encode_seq[counter+1]%7]>-1 && character_size[encode_seq[counter+1]%7] < ENC_MAX) {
          //encode character
          _convert_dec_to_bin(jab_enconing_table[tmp][encode_seq[counter+1]%7],encoded_data.data,position,character_size[encode_seq[counter+1]%7]);
          position+=character_size[encode_seq[counter+1]%7];
          counter++;
        } else if (jab_enconing_table[tmp][encode_seq[counter+1]%7]<-1) {
          int tmp1=data.data[current_encoded_length+1];
          if (tmp1 < 0) {
            tmp1 += 256;
          }
          //read next character to see if more efficient encoding possible
          if (((tmp==44 || tmp== 46 || tmp==58) && tmp1==32) || (tmp==13 && tmp1==10)) {
            decimal_value=(jab_enconing_table[tmp][encode_seq[counter+1]%7]).abs();
          } else if (tmp==13 && tmp1!=10) {
            decimal_value = 18;
          } else {
            return null; //Encoding data failed
          }
          if (character_size[encode_seq[counter+1]%7] < ENC_MAX) {
            _convert_dec_to_bin(decimal_value,encoded_data.data,position,character_size[encode_seq[counter+1]%7]);
          }
          position+=character_size[encode_seq[counter+1]%7];
          counter++;
          end_of_loop--;
          current_encoded_length++;
        } else {
          return null; //Encoding data failed
        }
      } else {
        //byte mode
        if(encode_seq[counter] != encode_seq[counter+1]) {
          //loop over sequence to check how many characters in byte mode follow
          byte_counter=0;
          for(int byte_loop=counter+1;byte_loop<=end_of_loop;byte_loop++) {
            if(encode_seq[byte_loop]==6 || encode_seq[byte_loop]==13) {
              byte_counter++;
            } else {
              break;
            }
          }
          _convert_dec_to_bin(byte_counter > 15 ? 0 : byte_counter,encoded_data.data,position,4);
          position+=4;
          if(byte_counter > 15) {
            if(byte_counter <= 8207) { //8207=2^13+15; if number of bytes exceeds 8207, encoder shall shift to byte mode again from upper case mode && byte_counter < 8207
              _convert_dec_to_bin(byte_counter-15-1,encoded_data.data,position,13);
            } else {
              _convert_dec_to_bin(8191,encoded_data.data,position,13);
            }
            position+=13;
          }
          byte_offset=byte_counter;
        }
        if(byte_offset-byte_counter==factor*8207) { //byte mode exceeds 2^13 + 15
          if(encode_seq[counter-(byte_offset-byte_counter)]==0 || encode_seq[counter-(byte_offset-byte_counter)]==7 || encode_seq[counter-(byte_offset-byte_counter)]==1|| encode_seq[counter-(byte_offset-byte_counter)]==8) {
            _convert_dec_to_bin(124,encoded_data.data,position,7);// shift from upper case to byte
            position+=7;
          }
          if(encode_seq[counter-(byte_offset-byte_counter)]==2 || encode_seq[counter-(byte_offset-byte_counter)]==9) {
            _convert_dec_to_bin(60,encoded_data.data,position,5);// shift from numeric to byte
            position+=5;
          }
          if(encode_seq[counter-(byte_offset-byte_counter)]==5 || encode_seq[counter-(byte_offset-byte_counter)]==12) {
            _convert_dec_to_bin(252,encoded_data.data,position,8);// shift from alphanumeric to byte
            position+=8;
          }
          _convert_dec_to_bin(byte_counter > 15 ? 0 : byte_counter,encoded_data.data,position,4); //write the first 4 bits
          position+=4;
          if(byte_counter > 15) { //if more than 15 bytes . use the next 13 bits to wirte the length
            if(byte_counter <= 8207) { //8207=2^13+15; if number of bytes exceeds 8207, encoder shall shift to byte mode again from upper case mode && byte_counter < 8207
              _convert_dec_to_bin(byte_counter-15-1,encoded_data.data,position,13);
            } else { //number exceeds 2^13 + 15
              _convert_dec_to_bin(8191,encoded_data.data,position,13);
            }
            position+=13;
          }
          factor++;
        }
        if (character_size[encode_seq[counter+1]%7] < ENC_MAX) {
          _convert_dec_to_bin(tmp,encoded_data.data,position,character_size[encode_seq[counter+1]%7]);
        } else {
          return null; //Encoding data failed
        }
        position+=character_size[encode_seq[counter+1]%7];
        counter++;
        byte_counter--;
      }
      //shift back to mode from which mode was invoked
      if (shift_back && byte_counter==0) {
        if(byte_offset==0) {
          encode_seq[counter]=encode_seq[counter-1];
        } else {
          encode_seq[counter]=encode_seq[counter-byte_offset];
        }
        shift_back=false;
        byte_offset=0;
      }

    } else {
      return null; //Encoding data failed
    }
    current_encoded_length++;
  }
  return encoded_data;
}

/*
 Encode metadata
 @param enc the encode parameters
 @return JAB_SUCCESS | JAB_FAILURE
*/
int _encodeMasterMetadata(jab_encode enc) {
	int partI_length 	= MASTER_METADATA_PART1_LENGTH~/2;	//partI net length
	int partII_length	= MASTER_METADATA_PART2_LENGTH~/2;	//partII net length
	int V_length = 10;
	int E_length = 6;
	int MSK_length = 3;
	//set master metadata variables
	int Nc = (log(enc.color_number)/log(2.0) - 1).toInt();
	int V = ((enc.symbol_versions[0].x -1) << 5) + (enc.symbol_versions[0].y - 1);
	int E1 = enc.symbols[0].wcwr[0] - 3;
	int E2 = enc.symbols[0].wcwr[1] - 4;
	int MSK = DEFAULT_MASKING_REFERENCE;

	//write each part of master metadata
	//Part I
	var partI = jab_data(); //(jab_data *)malloc(sizeof(jab_data) + partI_length*sizeof(jab_char));
	partI.length = partI_length;
	_convert_dec_to_bin(Nc, partI.data, 0, partI.length);
	//Part II
	var partII = jab_data(); //(jab_data *)malloc(sizeof(jab_data) + partII_length*sizeof(jab_char));

	partII.length = partII_length;
	_convert_dec_to_bin(V,   partII.data, 0, V_length);
	_convert_dec_to_bin(E1,  partII.data, V_length, 3);
	_convert_dec_to_bin(E2,  partII.data, V_length+3, 3);
	_convert_dec_to_bin(MSK, partII.data, V_length+E_length, MSK_length);

	//encode each part of master metadata
	var wcwr = [2, -1];
	//Part I
	var encoded_partI = encodeLDPC(partI, wcwr);
	if(encoded_partI == null) {
		return JAB_FAILURE; //LDPC encoding master metadata Part I failed
	}
	//Part II
	var encoded_partII  = encodeLDPC(partII, wcwr);
	if(encoded_partII == null) {
		return JAB_FAILURE; //LDPC encoding master metadata Part II failed
	}

	int encoded_metadata_length = encoded_partI.length + encoded_partII.length;
	enc.symbols[0].metadata = jab_data(); // (jab_data *)malloc(sizeof(jab_data) + encoded_metadata_length*sizeof(jab_char));
	enc.symbols[0].metadata.length = encoded_metadata_length;
	//copy encoded parts into metadata
	_memcpy(enc.symbols[0].metadata.data,0, encoded_partI.data, 0, encoded_partI.length);
	_memcpy(enc.symbols[0].metadata.data, encoded_partI.length, encoded_partII.data, 0, encoded_partII.length);

  return JAB_SUCCESS;
}

/*
 Update master symbol metadata PartII if the default masking reference is changed
 @param enc the encode parameter
 @param mask_ref the masking reference
 @return JAB_SUCCESS | JAB_FAILURE
*/
int _updateMasterMetadataPartII(jab_encode enc, int mask_ref) {
	int partII_length	= MASTER_METADATA_PART2_LENGTH~/2;	//partII net length
	var partII = jab_data(); //(jab_data *)malloc(sizeof(jab_data) + partII_length*sizeof(jab_char));
  partII.data=Uint8List(partII_length);
	partII.length = partII_length;

	//set V and E
	int V_length = 10;
	int E_length = 6;
	int MSK_length = 3;
	int V = ((enc.symbol_versions[0].x -1) << 5) + (enc.symbol_versions[0].y - 1);
	int E1 = enc.symbols[0].wcwr[0] - 3;
	int E2 = enc.symbols[0].wcwr[1] - 4;
	_convert_dec_to_bin(V,   partII.data, 0, V_length);
	_convert_dec_to_bin(E1,  partII.data, V_length, 3);
	_convert_dec_to_bin(E2,  partII.data, V_length+3, 3);

	//update masking reference in PartII
	_convert_dec_to_bin(mask_ref, partII.data, V_length+E_length, MSK_length);

	//encode new PartII
	var wcwr = [2, -1];
	var encoded_partII = encodeLDPC(partII, wcwr);
	if(encoded_partII == null) {
		return JAB_FAILURE; //LDPC encoding master metadata Part II failed
	}
	//update metadata
	_memcpy(enc.symbols[0].metadata.data, MASTER_METADATA_PART1_LENGTH, encoded_partII.data, 0, encoded_partII.length);

	return JAB_SUCCESS;
}

/*
 Update master symbol metadata PartII if the default masking reference is changed
 @param enc the encode parameter
*/
void _placeMasterMetadataPartII(jab_encode enc) {
  //rewrite metadata in master with mask information
  int nb_of_bits_per_mod = log(enc.color_number)~/log(2);
  int x = MASTER_METADATA_X;
  int y = MASTER_METADATA_Y;
  int module_count = 0;
  //skip PartI and color palette
  int color_palette_size = min(enc.color_number-2, 64-2);
  int module_offset = MASTER_METADATA_PART1_MODULE_NUMBER + color_palette_size*COLOR_PALETTE_NUMBER;
  for(int i=0; i<module_offset; i++) {
    module_count++;
    var result = getNextMetadataModuleInMaster(enc.symbols[0].side_size.y, enc.symbols[0].side_size.x, module_count, x, y);
    x = result.item1;
    y = result.item2;
  }
	//update PartII
	int partII_bit_start = MASTER_METADATA_PART1_LENGTH;
	int partII_bit_end = MASTER_METADATA_PART1_LENGTH + MASTER_METADATA_PART2_LENGTH;
	int metadata_index = partII_bit_start;
	while(metadata_index <= partII_bit_end) {
    var color_index = enc.symbols[0].matrix[y*enc.symbols[0].side_size.x + x];
		for(int j=0; j<nb_of_bits_per_mod; j++) {
			if(metadata_index <= partII_bit_end) {
				var bit = enc.symbols[0].metadata.data[metadata_index];
				if(bit == 0) {
				  color_index &= ~(1 << (nb_of_bits_per_mod-1-j));
				} else {
				  color_index |= 1 << (nb_of_bits_per_mod-1-j);
				}
				metadata_index++;
			} else {
			  break;
			}
		}
    enc.symbols[0].matrix[y*enc.symbols[0].side_size.x + x] = color_index;
    module_count++;
    var result = getNextMetadataModuleInMaster(enc.symbols[0].side_size.y, enc.symbols[0].side_size.x, module_count, x, y);
    x = result.item1;
    y = result.item2;
  }
}

void _memcpy(Uint8List dst, int dst_offset, Uint8List src, int src_offset, int length) {
  dst.replaceRange(dst_offset, dst_offset + length, src.getRange(src_offset, src_offset + length));
}

/*
 Get color index for the color palette
 @param index the color index in the palette
 @param index_size the size of index
 @param color_number the number of colors
*/
void _getColorPaletteIndex(Uint8List index, int index_size, int color_number){
	for(int i=0; i<index_size; i++){
		index[i] = i;
	}

	if(color_number < 128) {
	  return;
	}

	var tmp = Uint8List(color_number);
	for(int i=0; i<color_number; i++) {
		tmp[i] = i;
	}

	if(color_number == 128) {
		_memcpy(index, 0, tmp, 0, 16);
		_memcpy(index, 16, tmp, 32, 16);
		_memcpy(index, 32, tmp, 80, 16);
		_memcpy(index, 48, tmp, 112, 16);
	} else if(color_number == 256) {
		_memcpy(index, 0, tmp, 0,  4);
		_memcpy(index, 4, tmp, 8,  4);
		_memcpy(index, 8, tmp, 20, 4);
		_memcpy(index, 12,tmp, 28, 4);

		_memcpy(index, 16, tmp, 64, 4);
		_memcpy(index, 20, tmp, 72, 4);
		_memcpy(index, 24, tmp, 84, 4);
		_memcpy(index, 28, tmp, 92, 4);

		_memcpy(index, 32, tmp, 160, 4);
		_memcpy(index, 36, tmp, 168, 4);
		_memcpy(index, 40, tmp, 180, 4);
		_memcpy(index, 44, tmp, 188, 4);

		_memcpy(index, 48, tmp, 224, 4);
		_memcpy(index, 52, tmp, 232, 4);
		_memcpy(index, 56, tmp, 244, 4);
		_memcpy(index, 60, tmp, 252, 4);
	}
}

/*
 Create symbol matrix
 @param enc the encode parameter
 @param index the symbol index
 @param ecc_encoded_data encoded data
 @return JAB_SUCCESS | JAB_FAILURE
*/
int _createMatrix(jab_encode enc, int index, jab_data ecc_encoded_data){
  //Allocate matrix
  enc.symbols[index].matrix = Int8List(enc.symbols[index].side_size.x * enc.symbols[index].side_size.y); // (jab_byte *)calloc(enc.symbols[index].side_size.x * enc.symbols[index].side_size.y, sizeof(jab_byte));
  //Allocate boolean matrix
  enc.symbols[index].data_map = Int8List(enc.symbols[index].side_size.x * enc.symbols[index].side_size.y); //(jab_byte *)malloc(enc.symbols[index].side_size.x * enc.symbols[index].side_size.y * sizeof(jab_byte));

  enc.symbols[index].data_map.fillRange(0, enc.symbols[index].data_map.length-1, 1);  // memset(enc.symbols[index].data_map, 1, enc.symbols[index].side_size.x * enc.symbols[index].side_size.y * sizeof(jab_byte));

  //set alignment patterns
  int Nc = (log(enc.color_number)/log(2.0) - 1).toInt();
  var apx_core_color = apx_core_color_index[Nc];
  var apx_peri_color = apn_core_color_index[Nc];
  var side_ver_x_index = SIZE2VERSION(enc.symbols[index].side_size.x) - 1;
  var side_ver_y_index = SIZE2VERSION(enc.symbols[index].side_size.y) - 1;
  for(int x=0; x<jab_ap_num[side_ver_x_index]; x++) {
    int left;
      if (x%2 == 1) {
        left=0;
      } else {
        left=1;
      }
      for(int y=0; y<jab_ap_num[side_ver_y_index]; y++) {
        int x_offset = jab_ap_pos[side_ver_x_index][x] - 1;
        int y_offset = jab_ap_pos[side_ver_y_index][y] - 1;
        //left alignment patterns
        if(	left == 1
            && (x != 0 || y != 0)
            && (x != 0 || y != jab_ap_num[side_ver_y_index]-1)
            && (x != jab_ap_num[side_ver_x_index]-1 || y != 0)
            && (x != jab_ap_num[side_ver_x_index]-1 || y != jab_ap_num[side_ver_y_index]-1))
        {
          enc.symbols[index].matrix[(y_offset-1)*enc.symbols[index].side_size.x + x_offset-1]=
          enc.symbols[index].matrix[(y_offset-1)*enc.symbols[index].side_size.x + x_offset  ]=
          enc.symbols[index].matrix[(y_offset  )*enc.symbols[index].side_size.x + x_offset-1]=
          enc.symbols[index].matrix[(y_offset  )*enc.symbols[index].side_size.x + x_offset+1]=
          enc.symbols[index].matrix[(y_offset+1)*enc.symbols[index].side_size.x + x_offset  ]=
          enc.symbols[index].matrix[(y_offset+1)*enc.symbols[index].side_size.x + x_offset+1]=apx_peri_color;
          enc.symbols[index].matrix[(y_offset  )*enc.symbols[index].side_size.x + x_offset  ]=apx_core_color;

          enc.symbols[index].data_map[(y_offset-1)*enc.symbols[index].side_size.x + x_offset-1]=
          enc.symbols[index].data_map[(y_offset-1)*enc.symbols[index].side_size.x + x_offset  ]=
          enc.symbols[index].data_map[(y_offset  )*enc.symbols[index].side_size.x + x_offset-1]=
          enc.symbols[index].data_map[(y_offset  )*enc.symbols[index].side_size.x + x_offset+1]=
          enc.symbols[index].data_map[(y_offset+1)*enc.symbols[index].side_size.x + x_offset  ]=
          enc.symbols[index].data_map[(y_offset+1)*enc.symbols[index].side_size.x + x_offset+1]=
          enc.symbols[index].data_map[(y_offset  )*enc.symbols[index].side_size.x + x_offset  ]=0;

        //right alignment patterns
        } else if(left == 0
                  && (x != 0 || y != 0)
                  && (x != 0 || y != jab_ap_num[side_ver_y_index]-1)
                  && (x != jab_ap_num[side_ver_x_index]-1 || y != 0)
                  && (x != jab_ap_num[side_ver_x_index]-1 || y != jab_ap_num[side_ver_y_index]-1))
          {
            enc.symbols[index].matrix[(y_offset-1)*enc.symbols[index].side_size.x + x_offset+1]=
            enc.symbols[index].matrix[(y_offset-1)*enc.symbols[index].side_size.x + x_offset  ]=
            enc.symbols[index].matrix[(y_offset  )*enc.symbols[index].side_size.x + x_offset-1]=
            enc.symbols[index].matrix[(y_offset  )*enc.symbols[index].side_size.x + x_offset+1]=
            enc.symbols[index].matrix[(y_offset+1)*enc.symbols[index].side_size.x + x_offset  ]=
            enc.symbols[index].matrix[(y_offset+1)*enc.symbols[index].side_size.x + x_offset-1]=apx_peri_color;
            enc.symbols[index].matrix[(y_offset  )*enc.symbols[index].side_size.x + x_offset  ]=apx_core_color;

            enc.symbols[index].data_map[(y_offset-1)*enc.symbols[index].side_size.x + x_offset+1]=
            enc.symbols[index].data_map[(y_offset-1)*enc.symbols[index].side_size.x + x_offset  ]=
            enc.symbols[index].data_map[(y_offset  )*enc.symbols[index].side_size.x + x_offset-1]=
            enc.symbols[index].data_map[(y_offset  )*enc.symbols[index].side_size.x + x_offset+1]=
            enc.symbols[index].data_map[(y_offset+1)*enc.symbols[index].side_size.x + x_offset  ]=
            enc.symbols[index].data_map[(y_offset+1)*enc.symbols[index].side_size.x + x_offset-1]=
            enc.symbols[index].data_map[(y_offset  )*enc.symbols[index].side_size.x + x_offset  ]=0;
          }
          if (left==0) {
            left=1;
          } else {
            left=0;
          }
      }
  }

  //outer layers of finder pattern for master symbol
  if(index == 0) {
    //if k=0 center, k=1 first layer, k=2 second layer
    for(int k=0;k<3;k++) {
      for(int i=0;i<k+1;i++) {
        for(int j=0;j<k+1;j++) {
          if (i==k || j==k) {
            var fp0_color_index = (k%2 != 0) ? fp3_core_color_index[Nc] : fp0_core_color_index[Nc];
            var fp1_color_index = (k%2 != 0) ? fp2_core_color_index[Nc] : fp1_core_color_index[Nc];
            var fp2_color_index = (k%2 != 0) ? fp1_core_color_index[Nc] : fp2_core_color_index[Nc];
            var fp3_color_index = (k%2 != 0) ? fp0_core_color_index[Nc] : fp3_core_color_index[Nc];

            //upper pattern
            enc.symbols[index].matrix[(DISTANCE_TO_BORDER-(i+1))*enc.symbols[index].side_size.x+DISTANCE_TO_BORDER-j-1]=
            enc.symbols[index].matrix[(DISTANCE_TO_BORDER+(i-1))*enc.symbols[index].side_size.x+DISTANCE_TO_BORDER+j-1]=fp0_color_index;
            enc.symbols[index].data_map[(DISTANCE_TO_BORDER-(i+1))*enc.symbols[index].side_size.x+DISTANCE_TO_BORDER-j-1]=
            enc.symbols[index].data_map[(DISTANCE_TO_BORDER+(i-1))*enc.symbols[index].side_size.x+DISTANCE_TO_BORDER+j-1]=0;

            enc.symbols[index].matrix[(DISTANCE_TO_BORDER-(i+1))*enc.symbols[index].side_size.x+enc.symbols[index].side_size.x-(DISTANCE_TO_BORDER-1)-j-1]=
            enc.symbols[index].matrix[(DISTANCE_TO_BORDER+(i-1))*enc.symbols[index].side_size.x+enc.symbols[index].side_size.x-(DISTANCE_TO_BORDER-1)+j-1]=fp1_color_index;
            enc.symbols[index].data_map[(DISTANCE_TO_BORDER-(i+1))*enc.symbols[index].side_size.x+enc.symbols[index].side_size.x-(DISTANCE_TO_BORDER-1)-j-1]=
            enc.symbols[index].data_map[(DISTANCE_TO_BORDER+(i-1))*enc.symbols[index].side_size.x+enc.symbols[index].side_size.x-(DISTANCE_TO_BORDER-1)+j-1]=0;

            //lower pattern
            enc.symbols[index].matrix[(enc.symbols[index].side_size.y-DISTANCE_TO_BORDER+i)*enc.symbols[index].side_size.x+enc.symbols[index].side_size.x-(DISTANCE_TO_BORDER-1)-j-1]=
            enc.symbols[index].matrix[(enc.symbols[index].side_size.y-DISTANCE_TO_BORDER-i)*enc.symbols[index].side_size.x+enc.symbols[index].side_size.x-(DISTANCE_TO_BORDER-1)+j-1]=fp2_color_index;
            enc.symbols[index].data_map[(enc.symbols[index].side_size.y-DISTANCE_TO_BORDER+i)*enc.symbols[index].side_size.x+enc.symbols[index].side_size.x-(DISTANCE_TO_BORDER-1)-j-1]=
            enc.symbols[index].data_map[(enc.symbols[index].side_size.y-DISTANCE_TO_BORDER-i)*enc.symbols[index].side_size.x+enc.symbols[index].side_size.x-(DISTANCE_TO_BORDER-1)+j-1]=0;

            enc.symbols[index].matrix[(enc.symbols[index].side_size.y-DISTANCE_TO_BORDER+i)*enc.symbols[index].side_size.x+(DISTANCE_TO_BORDER)-j-1]=
            enc.symbols[index].matrix[(enc.symbols[index].side_size.y-DISTANCE_TO_BORDER-i)*enc.symbols[index].side_size.x+(DISTANCE_TO_BORDER)+j-1]=fp3_color_index;
            enc.symbols[index].data_map[(enc.symbols[index].side_size.y-DISTANCE_TO_BORDER+i)*enc.symbols[index].side_size.x+(DISTANCE_TO_BORDER)-j-1]=
            enc.symbols[index].data_map[(enc.symbols[index].side_size.y-DISTANCE_TO_BORDER-i)*enc.symbols[index].side_size.x+(DISTANCE_TO_BORDER)+j-1]=0;
          }
        }
      }
    }
  } else { //finder alignments in slave
    //if k=0 center, k=1 first layer
    for(int k=0;k<2;k++) {
      for(int i=0;i<k+1;i++) {
        for(int j=0;j<k+1;j++) {
          if (i==k || j==k) {
            var ap0_color_index = (k%2 != 0) ? apx_core_color_index[Nc] : apn_core_color_index[Nc];
            var ap1_color_index = ap0_color_index;
            var ap2_color_index = ap0_color_index;
            var ap3_color_index = ap0_color_index;
            //upper pattern
            enc.symbols[index].matrix[(DISTANCE_TO_BORDER-(i+1))*enc.symbols[index].side_size.x+DISTANCE_TO_BORDER-j-1]=
            enc.symbols[index].matrix[(DISTANCE_TO_BORDER+(i-1))*enc.symbols[index].side_size.x+DISTANCE_TO_BORDER+j-1]=ap0_color_index;
            enc.symbols[index].data_map[(DISTANCE_TO_BORDER-(i+1))*enc.symbols[index].side_size.x+DISTANCE_TO_BORDER-j-1]=
            enc.symbols[index].data_map[(DISTANCE_TO_BORDER+(i-1))*enc.symbols[index].side_size.x+DISTANCE_TO_BORDER+j-1]=0;

            enc.symbols[index].matrix[(DISTANCE_TO_BORDER-(i+1))*enc.symbols[index].side_size.x+enc.symbols[index].side_size.x-(DISTANCE_TO_BORDER-1)-j-1]=
            enc.symbols[index].matrix[(DISTANCE_TO_BORDER+(i-1))*enc.symbols[index].side_size.x+enc.symbols[index].side_size.x-(DISTANCE_TO_BORDER-1)+j-1]=ap1_color_index;
            enc.symbols[index].data_map[(DISTANCE_TO_BORDER-(i+1))*enc.symbols[index].side_size.x+enc.symbols[index].side_size.x-(DISTANCE_TO_BORDER-1)-j-1]=
            enc.symbols[index].data_map[(DISTANCE_TO_BORDER+(i-1))*enc.symbols[index].side_size.x+enc.symbols[index].side_size.x-(DISTANCE_TO_BORDER-1)+j-1]=0;

            //lower pattern
            enc.symbols[index].matrix[(enc.symbols[index].side_size.y-DISTANCE_TO_BORDER+i)*enc.symbols[index].side_size.x+enc.symbols[index].side_size.x-(DISTANCE_TO_BORDER-1)-j-1]=
            enc.symbols[index].matrix[(enc.symbols[index].side_size.y-DISTANCE_TO_BORDER-i)*enc.symbols[index].side_size.x+enc.symbols[index].side_size.x-(DISTANCE_TO_BORDER-1)+j-1]=ap2_color_index;
            enc.symbols[index].data_map[(enc.symbols[index].side_size.y-DISTANCE_TO_BORDER+i)*enc.symbols[index].side_size.x+enc.symbols[index].side_size.x-(DISTANCE_TO_BORDER-1)-j-1]=
            enc.symbols[index].data_map[(enc.symbols[index].side_size.y-DISTANCE_TO_BORDER-i)*enc.symbols[index].side_size.x+enc.symbols[index].side_size.x-(DISTANCE_TO_BORDER-1)+j-1]=0;

            enc.symbols[index].matrix[(enc.symbols[index].side_size.y-DISTANCE_TO_BORDER+i)*enc.symbols[index].side_size.x+(DISTANCE_TO_BORDER)-j-1]=
            enc.symbols[index].matrix[(enc.symbols[index].side_size.y-DISTANCE_TO_BORDER-i)*enc.symbols[index].side_size.x+(DISTANCE_TO_BORDER)+j-1]=ap3_color_index;
            enc.symbols[index].data_map[(enc.symbols[index].side_size.y-DISTANCE_TO_BORDER+i)*enc.symbols[index].side_size.x+(DISTANCE_TO_BORDER)-j-1]=
            enc.symbols[index].data_map[(enc.symbols[index].side_size.y-DISTANCE_TO_BORDER-i)*enc.symbols[index].side_size.x+(DISTANCE_TO_BORDER)+j-1]=0;
          }
        }
      }
    }
  }

  //Metadata and color palette placement
  int nb_of_bits_per_mod = log(enc.color_number) ~/ log(2);
  int color_index;
  int module_count = 0;
  int x;
  int y;

  //get color index for color palette
  int palette_index_size = enc.color_number > 64 ? 64 : enc.color_number;
  var palette_index = Uint8List(palette_index_size);
  _getColorPaletteIndex(palette_index, palette_index_size, enc.color_number);

  if(index == 0) {//place metadata and color palette in master symbol
    x = MASTER_METADATA_X;
    y = MASTER_METADATA_Y;
    int metadata_index = 0;
    //metadata Part I
    if(_isDefaultMode(enc) == JAB_FAILURE) {
      while(metadata_index < enc.symbols[index].metadata.length && metadata_index < MASTER_METADATA_PART1_LENGTH) {
        //Read 3 bits from encoded PartI each time
        var bit1 = enc.symbols[index].metadata.data[metadata_index + 0];
        var bit2 = enc.symbols[index].metadata.data[metadata_index + 1];
        var bit3 = enc.symbols[index].metadata.data[metadata_index + 2];
        int val = (bit1 << 2) + (bit2 << 1) + bit3;
        //place two modules according to the value of every 3 bits
        for(int i=0; i<2; i++) {
          color_index = nc_color_encode_table[val][i] % enc.color_number;
          enc.symbols[index].matrix  [y*enc.symbols[index].side_size.x + x] = color_index;
          enc.symbols[index].data_map[y*enc.symbols[index].side_size.x + x] = 0;
          module_count++;
          var result = getNextMetadataModuleInMaster(enc.symbols[index].side_size.y, enc.symbols[index].side_size.x, module_count, x, y);
          x = result.item1;
          y = result.item2;
        }
        metadata_index += 3;
      }
    }
    //color palette
    for(int i=2; i<min(enc.color_number, 64); i++) {	//skip the first two colors in finder pattern
      enc.symbols[index].matrix  [y*enc.symbols[index].side_size.x+x] = palette_index[master_palette_placement_index[0][i]%enc.color_number];
      enc.symbols[index].data_map[y*enc.symbols[index].side_size.x+x] = 0;
      module_count++;
      var result = getNextMetadataModuleInMaster(enc.symbols[index].side_size.y, enc.symbols[index].side_size.x, module_count, x, y);
      x = result.item1;
      y = result.item2;

      enc.symbols[index].matrix  [y*enc.symbols[index].side_size.x+x] = palette_index[master_palette_placement_index[1][i]%enc.color_number];
      enc.symbols[index].data_map[y*enc.symbols[index].side_size.x+x] = 0;
      module_count++;
      result = getNextMetadataModuleInMaster(enc.symbols[index].side_size.y, enc.symbols[index].side_size.x, module_count, x, y);
      x = result.item1;
      y = result.item2;

      enc.symbols[index].matrix  [y*enc.symbols[index].side_size.x+x] = palette_index[master_palette_placement_index[2][i]%enc.color_number];
      enc.symbols[index].data_map[y*enc.symbols[index].side_size.x+x] = 0;
      module_count++;
      result = getNextMetadataModuleInMaster(enc.symbols[index].side_size.y, enc.symbols[index].side_size.x, module_count, x, y);
      x = result.item1;
      y = result.item2;

      enc.symbols[index].matrix  [y*enc.symbols[index].side_size.x+x] = palette_index[master_palette_placement_index[3][i]%enc.color_number];
      enc.symbols[index].data_map[y*enc.symbols[index].side_size.x+x] = 0;
      module_count++;
      result = getNextMetadataModuleInMaster(enc.symbols[index].side_size.y, enc.symbols[index].side_size.x, module_count, x, y);
      x = result.item1;
      y = result.item2;
    }
    //metadata PartII
    if(_isDefaultMode(enc) == JAB_FAILURE) {
      while(metadata_index < enc.symbols[index].metadata.length) {
        color_index = 0;
        for(int j=0; j<nb_of_bits_per_mod; j++) {
          if(metadata_index < enc.symbols[index].metadata.length) {
            color_index += (enc.symbols[index].metadata.data[metadata_index]) << (nb_of_bits_per_mod-1-j);
            metadata_index++;
          } else {
            break;
          }
        }
        enc.symbols[index].matrix  [y*enc.symbols[index].side_size.x + x] = color_index;
        enc.symbols[index].data_map[y*enc.symbols[index].side_size.x + x] = 0;
        module_count++;
        var result = getNextMetadataModuleInMaster(enc.symbols[index].side_size.y, enc.symbols[index].side_size.x, module_count, x, y);
        x = result.item1;
        y = result.item2;
      }
    }
    } else { //place color palette in slave symbol

      //color palette
    int width=enc.symbols[index].side_size.x;
    int height=enc.symbols[index].side_size.y;
    for (int i=2; i<min(enc.color_number, 64); i++)	{ //skip the first two colors in alignment pattern
      //left
      enc.symbols[index].matrix  [slave_palette_position[i-2].y*width + slave_palette_position[i-2].x] = palette_index[slave_palette_placement_index[i]%enc.color_number];
      enc.symbols[index].data_map[slave_palette_position[i-2].y*width + slave_palette_position[i-2].x] = 0;
      //top
      enc.symbols[index].matrix  [slave_palette_position[i-2].x*width + (width-1-slave_palette_position[i-2].y)] = palette_index[slave_palette_placement_index[i]%enc.color_number];
      enc.symbols[index].data_map[slave_palette_position[i-2].x*width + (width-1-slave_palette_position[i-2].y)] = 0;
      //right
      enc.symbols[index].matrix  [(height-1-slave_palette_position[i-2].y)*width + (width-1-slave_palette_position[i-2].x)] = palette_index[slave_palette_placement_index[i]%enc.color_number];
      enc.symbols[index].data_map[(height-1-slave_palette_position[i-2].y)*width + (width-1-slave_palette_position[i-2].x)] = 0;
      //bottom
      enc.symbols[index].matrix  [(height-1-slave_palette_position[i-2].x)*width + slave_palette_position[i-2].y] = palette_index[slave_palette_placement_index[i]%enc.color_number];
      enc.symbols[index].data_map[(height-1-slave_palette_position[i-2].x)*width + slave_palette_position[i-2].y] = 0;
    }
  }
  //Data placement
  int written_mess_part=0;
  int padding=0;
  for(int start_i=0;start_i<enc.symbols[index].side_size.x;start_i++) {
    for(int i=start_i;i<enc.symbols[index].side_size.x*enc.symbols[index].side_size.y;i=i+enc.symbols[index].side_size.x) {
      if (enc.symbols[index].data_map[i]!=0 && written_mess_part<ecc_encoded_data.length) {
        color_index=0;
        for(int j=0;j<nb_of_bits_per_mod;j++) {
          if(written_mess_part<ecc_encoded_data.length) {
            color_index+=(ecc_encoded_data.data[written_mess_part]) << (nb_of_bits_per_mod-1-j);//*pow(2,nb_of_bits_per_mod-1-j);
          } else {
            color_index+=padding << (nb_of_bits_per_mod-1-j);//*pow(2,nb_of_bits_per_mod-1-j);
            if (padding==0) {
              padding=1;
            } else {
              padding=0;
            }
          }
          written_mess_part++;
        }
        enc.symbols[index].matrix[i]=color_index;//i % enc.color_number;

      } else if(enc.symbols[index].data_map[i]!=0) { //write padding bits
        color_index=0;
        for(int j=0;j<nb_of_bits_per_mod;j++) {
          color_index+=padding << (nb_of_bits_per_mod-1-j);//*pow(2,nb_of_bits_per_mod-1-j);
          if (padding==0) {
            padding=1;
          } else {
            padding=0;
          }
        }
        enc.symbols[index].matrix[i]=color_index;//i % enc.color_number;
      }
    }
  }
	return JAB_SUCCESS;
}

/*
 Swap two symbols
 @param enc the encode parameters
 @param index1 the index number of the first symbol
 @param index2 the index number of the second symbol
*/
void _swap_symbols(jab_encode enc, int index1, int index2) {
	_swap_int(index1, index2, enc.symbol_positions);
	_swap_vector_2D(index1, index2, enc.symbol_versions);
	_swap_int8(index1, index2, enc.symbol_ecc_levels);
	//swap symbols
  jab_symbol s = enc.symbols[index1];
  enc.symbols[index1] = enc.symbols[index2];
  enc.symbols[index2] = s;
}

/*
 Assign docked symbols to their hosts
 @param enc the encode parameters
 @return JAB_SUCCESS | JAB_FAILURE
*/
int _assignDockedSymbols(jab_encode enc) {
	//initialize host and slaves
	for(int i=0; i<enc.symbol_number; i++) {
		//initialize symbol host index
		enc.symbols[i].host = -1;
		//initialize symbol's slave index
		for(int j=0; j<4; j++) {
		  enc.symbols[i].slaves[j] = 0;	//0:no slave
		}
	}
	//assign docked symbols
	int assigned_slave_index = 1;
  for(int i=0; i<enc.symbol_number-1 && assigned_slave_index<enc.symbol_number; i++) {
    for(int j=0; j<4 && assigned_slave_index<enc.symbol_number; j++) {
			for(int k=i+1; k<enc.symbol_number && assigned_slave_index<enc.symbol_number; k++) {
				if(enc.symbols[k].host == -1) {
					int hpos = enc.symbol_positions[i];
					int spos = enc.symbol_positions[k];
					int slave_found = JAB_FAILURE;
					switch(j) {
            case 0:	//top
              if(jab_symbol_pos[hpos].x == jab_symbol_pos[spos].x && jab_symbol_pos[hpos].y - 1 == jab_symbol_pos[spos].y) {
                enc.symbols[i].slaves[0] = assigned_slave_index;
                enc.symbols[k].slaves[1] = -1;	//-1:host position
                slave_found = JAB_SUCCESS;
              }
              break;
            case 1:	//bottom
              if(jab_symbol_pos[hpos].x == jab_symbol_pos[spos].x && jab_symbol_pos[hpos].y + 1 == jab_symbol_pos[spos].y) {
                enc.symbols[i].slaves[1] = assigned_slave_index;
                enc.symbols[k].slaves[0] = -1;
                slave_found = JAB_SUCCESS;
              }
              break;
            case 2:	//left
              if(jab_symbol_pos[hpos].y == jab_symbol_pos[spos].y && jab_symbol_pos[hpos].x - 1 == jab_symbol_pos[spos].x) {
                enc.symbols[i].slaves[2] = assigned_slave_index;
                enc.symbols[k].slaves[3] = -1;
                slave_found = JAB_SUCCESS;
              }
              break;
            case 3://right
              if(jab_symbol_pos[hpos].y == jab_symbol_pos[spos].y && jab_symbol_pos[hpos].x + 1 == jab_symbol_pos[spos].x) {
                enc.symbols[i].slaves[3] = assigned_slave_index;
                enc.symbols[k].slaves[2] = -1;
                slave_found = JAB_SUCCESS;
              }
              break;
          }
					if(slave_found == JAB_SUCCESS) {
						_swap_symbols(enc, k, assigned_slave_index);
						enc.symbols[assigned_slave_index].host = i;
						assigned_slave_index++;
					}
				}
			}
		}
  }
  //check if there is undocked symbol
  for(int i=1; i<enc.symbol_number; i++) {
    if(enc.symbols[i].host == -1) {
      // JAB_REPORT_ERROR(("Slave symbol at position %d has no host", enc.symbol_positions[i]))
      return JAB_FAILURE;
    }
  }
  return JAB_SUCCESS;
}

/*
 Calculate the code parameters according to the input symbols
 @param enc the encode parameters
 @return the code parameters
*/
jab_code _getCodePara(jab_encode enc) {
  var cp = jab_code(); // (jab_code *)malloc(sizeof(jab_code));

  //calculate the module size in pixel
  if(enc.master_symbol_width != 0 || enc.master_symbol_height != 0) {
    int dimension_x = enc.master_symbol_width~/enc.symbols[0].side_size.x;
    int dimension_y = enc.master_symbol_height~/enc.symbols[0].side_size.y;
    cp.dimension = dimension_x > dimension_y ? dimension_x : dimension_y;
    if(cp.dimension < 1) {
      cp.dimension = 1;
    }
  } else {
    cp.dimension = enc.module_size;
  }

  //find the coordinate range of symbols
  cp.min_x = 0;
  cp.min_y = 0;
  int max_x=0, max_y=0;
  for(int i=0; i<enc.symbol_number; i++) {
    //find the mininal x and y
    if (jab_symbol_pos[enc.symbol_positions[i]].x < cp.min_x) {
      cp.min_x = jab_symbol_pos[enc.symbol_positions[i]].x;
    }
    if (jab_symbol_pos[enc.symbol_positions[i]].y < cp.min_y) {
      cp.min_y = jab_symbol_pos[enc.symbol_positions[i]].y;
    }
    //find the maximal x and y
    if (jab_symbol_pos[enc.symbol_positions[i]].x > max_x) {
      max_x = jab_symbol_pos[enc.symbol_positions[i]].x;
    }
    if (jab_symbol_pos[enc.symbol_positions[i]].y > max_y) {
      max_y = jab_symbol_pos[enc.symbol_positions[i]].y;
    }
  }

  //calculate the code size
  cp.rows = max_y - cp.min_y + 1;
  cp.cols = max_x - cp.min_x + 1;
  cp.row_height = List<int>.filled(cp.rows, 0); // (int *)malloc(cp.rows * sizeof(int));
  cp.col_width = List<int>.filled(cp.cols, 0); //(int *)malloc(cp.cols * sizeof(int));

  cp.code_size.x = 0;
  cp.code_size.y = 0;
  bool flag = false;
  for(int x=cp.min_x; x<=max_x; x++) {
    flag = false;
    for(int i=0; i<enc.symbol_number; i++) {
      if(jab_symbol_pos[enc.symbol_positions[i]].x == x) {
        cp.col_width[x - cp.min_x] = enc.symbols[i].side_size.x;
        cp.code_size.x += cp.col_width[x - cp.min_x];
        flag = true;
      }
      if(flag) break;
    }
  }
  for(int y=cp.min_y; y<=max_y; y++) {
    flag = false;
    for(int i=0; i<enc.symbol_number; i++) {
      if(jab_symbol_pos[enc.symbol_positions[i]].y == y) {
        cp.row_height[y - cp.min_y] = enc.symbols[i].side_size.y;
        cp.code_size.y += cp.row_height[y - cp.min_y];
        flag = true;
      }
      if(flag) break;
    }
  }
  return cp;
}

/*
 Create bitmap for the code
 @param enc the encode parameters
 @param cp the code parameters
 @return JAB_SUCCESS | JAB_FAILURE
*/
int _createBitmap(jab_encode enc, jab_code cp) {
  //create bitmap
  int width = cp.dimension * cp.code_size.x;
  int height= cp.dimension * cp.code_size.y;
  int bytes_per_pixel = BITMAP_CHANNEL_COUNT;
  int bytes_per_row = width * bytes_per_pixel;
  enc.bitmap = jab_bitmap(); //(jab_bitmap *)calloc(1, sizeof(jab_bitmap) + width*height*bytes_per_pixel*sizeof(jab_byte));
  enc.bitmap!.pixel = Uint8List( width*height*bytes_per_pixel);

  enc.bitmap!.width = width;
  enc.bitmap!.height= height;
  enc.bitmap!.bits_per_channel = BITMAP_BITS_PER_CHANNEL;
  enc.bitmap!.channel_count = BITMAP_CHANNEL_COUNT;
  enc.bitmap!.bits_per_pixel = enc.bitmap!.bits_per_channel * enc.bitmap!.channel_count;


  //place symbols in bitmap
  for(int k=0; k<enc.symbol_number; k++) {
    //calculate the starting coordinates of the symbol matrix
    int startx = 0, starty = 0;
    int col = jab_symbol_pos[enc.symbol_positions[k]].x - cp.min_x;
    int row = jab_symbol_pos[enc.symbol_positions[k]].y - cp.min_y;
    for(int c=0; c<col; c++) {
      startx += cp.col_width[c];
    }
    for(int r=0; r<row; r++) {
      starty += cp.row_height[r];
    }

    //place symbol in the code
    int symbol_width = enc.symbols[k].side_size.x;
    int symbol_height= enc.symbols[k].side_size.y;
    for(int x=startx; x<(startx+symbol_width); x++) {
      for(int y=starty; y<(starty+symbol_height); y++) {
        //place one module in the bitmap
        int p_index = enc.symbols[k].matrix[(y-starty)*symbol_width + (x-startx)];
        for(int i=y*cp.dimension; i<(y*cp.dimension+cp.dimension); i++) {
          for(int j=x*cp.dimension; j<(x*cp.dimension+cp.dimension); j++) {
            enc.bitmap!.pixel[i*bytes_per_row + j*bytes_per_pixel]     = enc.palette![p_index * 3];	//R
            enc.bitmap!.pixel[i*bytes_per_row + j*bytes_per_pixel + 1] = enc.palette![p_index * 3 + 1];//B
            enc.bitmap!.pixel[i*bytes_per_row + j*bytes_per_pixel + 2] = enc.palette![p_index * 3 + 2];//G
            enc.bitmap!.pixel[i*bytes_per_row + j*bytes_per_pixel + 3] = 255; 							//A
          }
        }
      }
    }
  }
  return JAB_SUCCESS;
}


/*
 Checks if the docked symbol sizes are valid
 @param enc the encode parameters
 @return JAB_SUCCESS | JAB_FAILURE
*/
int _checkDockedSymbolSize(jab_encode enc) {
	for(int i=0; i<enc.symbol_number; i++) {
		for(int j=0; j<4; j++) {
			int slave_index = enc.symbols[i].slaves[j];
			if(slave_index > 0) {
				int hpos = enc.symbol_positions[i];
				int spos = enc.symbol_positions[slave_index];
				int x_diff = jab_symbol_pos[hpos].x - jab_symbol_pos[spos].x;
				int y_diff = jab_symbol_pos[hpos].y - jab_symbol_pos[spos].y;

				if(x_diff == 0 && enc.symbol_versions[i].x != enc.symbol_versions[slave_index].x) {
					return JAB_FAILURE; //Slave symbol at position %d has different side version in X direction as its host symbol at position %d", spos, hpos
				}
				if(y_diff == 0 && enc.symbol_versions[i].y != enc.symbol_versions[slave_index].y) {
					return JAB_FAILURE; //Slave symbol at position %d has different side version in Y direction as its host symbol at position %d", spos, hpos
				}
			}
		}
	}
	return JAB_SUCCESS;
}

/*
 Set the minimal master symbol version
 @param enc the encode parameters
 @param encoded_data the encoded message
 @return JAB_SUCCESS | JAB_FAILURE
 */
int _setMasterSymbolVersion(jab_encode enc, jab_data encoded_data) {
  //calculate required number of data modules depending on data_length
  int net_data_length = encoded_data.length;
  int payload_length = net_data_length + 5;  //plus S and flag bit
  if(enc.symbol_ecc_levels[0] == 0) enc.symbol_ecc_levels[0] = DEFAULT_ECC_LEVEL;
  enc.symbols[0].wcwr[0] = ecclevel2wcwr[enc.symbol_ecc_levels[0]][0];
  enc.symbols[0].wcwr[1] = ecclevel2wcwr[enc.symbol_ecc_levels[0]][1];

	//determine the minimum square symbol to fit data
	int capacity = 0, net_capacity;
	int found_flag = JAB_FAILURE;
	for (int i=1; i<=32; i++) {
		enc.symbol_versions[0].x = i;
		enc.symbol_versions[0].y = i;
		capacity = _getSymbolCapacity(enc, 0);
		net_capacity = ((capacity/enc.symbols[0].wcwr[1])*enc.symbols[0].wcwr[1] - (capacity/enc.symbols[0].wcwr[1])*enc.symbols[0].wcwr[0]).toInt();
		if(net_capacity >= payload_length) {
			found_flag = JAB_SUCCESS;
			break;
		}
	}
	if(found_flag == JAB_FAILURE) {
		int level = -1;
		for (int j=enc.symbol_ecc_levels[0]-1; j>0; j--) {
			net_capacity = ((capacity/ecclevel2wcwr[j][1])*ecclevel2wcwr[j][1] - (capacity/ecclevel2wcwr[j][1])*ecclevel2wcwr[j][0]).toInt();
			if(net_capacity >= payload_length) {
			  level = j;
			}
		}
		if(level > 0) {
			return JAB_FAILURE; //Message does not fit into one symbol with the given ECC level. Please use an ECC level lower than %d with '--ecc-level %d'", level, level
		} else {
			return JAB_FAILURE; //"Message does not fit into one symbol. Use more symbols.
		}
	}
	//update symbol side size
  enc.symbols[0].side_size.x = VERSION2SIZE(enc.symbol_versions[0].x);
	enc.symbols[0].side_size.y = VERSION2SIZE(enc.symbol_versions[0].y);

  return JAB_SUCCESS;
}

/*
 Add variable E to slave symbol metadata the data payload for each symbol
 @param slave the slave symbol
 @return JAB_SUCCESS | JAB_FAILURE
*/
int _addE2SlaveMetadata(jab_symbol slave) {
	//copy old metadata to new metadata
	int old_metadata_length = slave.metadata.length;
	int new_metadata_length = old_metadata_length + 6;
	var old_metadata = slave.metadata;
	slave.metadata = jab_data(); // (jab_data *)malloc(sizeof(jab_data) + new_metadata_length*sizeof(jab_char));
  slave.metadata.data = Uint8List(new_metadata_length);
	slave.metadata.length = new_metadata_length;
  slave.metadata.data.setRange(0, old_metadata_length, old_metadata.data); // = _memcpy(slave.metadata.data, old_metadata.data, old_metadata_length);

	//update SE = 1
	slave.metadata.data[1] = 1;
	//set variable E
	int E1 = slave.wcwr[0] - 3;
	int E2 = slave.wcwr[1] - 4;
	_convert_dec_to_bin(E1, slave.metadata.data, old_metadata_length, 3);
	_convert_dec_to_bin(E2, slave.metadata.data, old_metadata_length+3, 3);
	return JAB_SUCCESS;
}

/*
 Update slave metadata E in its host data stream
 @param enc the encode parameters
 @param host_index the host symbol index
 @param slave_index the slave symbol index
*/
void _updateSlaveMetadataE(jab_encode enc, int host_index, int slave_index) {
	var host = enc.symbols[host_index];
  var slave= enc.symbols[slave_index];

	int offset = host.data.length - 1;
	//find the start flag of metadata
	while(host.data.data[offset] == 0) {
		offset--;
	}
	//skip the flag bit
	offset--;
	//skip host metadata S
	if(host_index == 0) {
	  offset -= 4;
	} else {
	  offset -= 3;
	}
	//skip other slave symbol's metadata
	for(int i=0; i<4; i++) {
		if(host.slaves[i] == slave_index) {
		  break;
		} else if(host.slaves[i] <= 0) {
		  continue;
		} else {
		  offset -= enc.symbols[host.slaves[i]].metadata.length;
		}
	}
	//skip SS, SE and possibly V
  if(slave.metadata.data[0] == 1) {
    offset -= 7;
  } else {
    offset -= 2;
  }
	//update E
	var E = Uint8List(6);
	int E1 = slave.wcwr[0] - 3;
	int E2 = slave.wcwr[1] - 4;
	_convert_dec_to_bin(E1, E, 0, 3);
	_convert_dec_to_bin(E2, E, 3, 3);
	for(int i=0; i<6; i++) {
		host.data.data[offset--] = E[i];
	}
}

/*
 Set the data payload for each symbol
 @param enc the encode parameters
 @param encoded_data the encoded message
 @return JAB_SUCCESS | JAB_FAILURE
*/
int _fitDataIntoSymbols(jab_encode enc, jab_data encoded_data) {
	//calculate the net capacity of each symbol and the total net capacity
  var capacity = List<int>.filled(enc.symbol_number, 0);
	var net_capacity = List<int>.filled(enc.symbol_number, 0);
	int total_net_capacity = 0;
	for(int i=0; i<enc.symbol_number; i++) {
		capacity[i] = _getSymbolCapacity(enc, i);
		enc.symbols[i].wcwr[0] = ecclevel2wcwr[enc.symbol_ecc_levels[i]][0];
		enc.symbols[i].wcwr[1] = ecclevel2wcwr[enc.symbol_ecc_levels[i]][1];
		net_capacity[i] = ((capacity[i]/enc.symbols[i].wcwr[1])*enc.symbols[i].wcwr[1] - (capacity[i]/enc.symbols[i].wcwr[1])*enc.symbols[i].wcwr[0]).toInt();
		total_net_capacity += net_capacity[i];
	}
	//assign data into each symbol
	int assigned_data_length = 0;
	for(int i=0; i<enc.symbol_number; i++) {
		//divide data proportionally
		int s_data_length;
		if(i == enc.symbol_number - 1) {
			s_data_length = encoded_data.length - assigned_data_length;
		} else {
			double prop = net_capacity[i] / total_net_capacity;
			s_data_length = (prop * encoded_data.length).toInt();
		}
		int s_payload_length = s_data_length;

		//add flag bit
		s_payload_length++;
		//add host metadata S length (master metadata Part III or slave metadata Part III)
		if(i == 0) {
		  s_payload_length += 4;
		} else {
		  s_payload_length += 3;
		}
		//add slave metadata length
		for(int j=0; j<4; j++) {
			if(enc.symbols[i].slaves[j] > 0) {
				s_payload_length += enc.symbols[enc.symbols[i].slaves[j]].metadata.length;
			}
		}

		//check if the full payload exceeds net capacity
		if(s_payload_length > net_capacity[i]) {
			// reportError("Message does not fit into the specified code. Use higher symbol version.");
			return JAB_FAILURE;
		}

		//add metadata E for slave symbols if free capacity available
		int j = 0;
		while(net_capacity[i] - s_payload_length >= 6 && j < 4) {
			if(enc.symbols[i].slaves[j] > 0) {
				if(enc.symbols[enc.symbols[i].slaves[j]].metadata.data[1] == 0) { //check SE
					if(_addE2SlaveMetadata(enc.symbols[enc.symbols[i].slaves[j]]) == JAB_FAILURE) {
					  return JAB_FAILURE;
					}
					s_payload_length += 6;	//add E length
				}
			}
			j++;
		}

		//get optimal code rate
		int pn_length = s_payload_length;
		if(i == 0) {
			if(_isDefaultMode(enc) == JAB_FAILURE) {
				_getOptimalECC(capacity[i], s_payload_length, enc.symbols[i].wcwr);
				pn_length = ((capacity[i]/enc.symbols[i].wcwr[1])*enc.symbols[i].wcwr[1] - (capacity[i]/enc.symbols[i].wcwr[1])*enc.symbols[i].wcwr[0]).toInt();
			}
			else {
			  pn_length = net_capacity[i];
			}
		} else {
			if(enc.symbols[i].metadata.data[1] == 1) {	//SE = 1
				_getOptimalECC(capacity[i], pn_length, enc.symbols[i].wcwr);
				pn_length = ((capacity[i]/enc.symbols[i].wcwr[1])*enc.symbols[i].wcwr[1] - (capacity[i]/enc.symbols[i].wcwr[1])*enc.symbols[i].wcwr[0]).toInt();
				_updateSlaveMetadataE(enc, enc.symbols[i].host, i);
			}
			else {
			  pn_length = net_capacity[i];
			}
		}

		//start to set full payload
    enc.symbols[i].data = jab_data(); //(jab_data *)calloc(1, sizeof(jab_data) + pn_length*sizeof(jab_char));
    enc.symbols[i].data.data = Uint8List(pn_length);
    enc.symbols[i].data.data.fillRange(0, pn_length, 1);
    // if(enc.symbols[i].data == null) {
		// 	// reportError("Memory allocation for data payload in symbol failed");
		// 	return JAB_FAILURE;
		// }
		enc.symbols[i].data.length = pn_length;
		//set data
    enc.symbols[i].data.data.setRange(0, s_data_length, encoded_data.data.sublist(assigned_data_length)); // _memcpy(enc.symbols[i].data.data, &encoded_data.data[assigned_data_length], s_data_length);
		assigned_data_length += s_data_length;
		//set flag bit
		int set_pos = s_payload_length - 1;
		enc.symbols[i].data.data[set_pos--] = 1;
		//set host metadata S
		for(int k=0; k<4; k++) {
			if(enc.symbols[i].slaves[k] > 0) {
				enc.symbols[i].data.data[set_pos--] = 1;
			} else if(enc.symbols[i].slaves[k] == 0) {
				enc.symbols[i].data.data[set_pos--] = 0;
			}
		}
		//set slave metadata
		for(int k=0; k<4; k++) {
			if(enc.symbols[i].slaves[k] > 0) {
				for(int m=0; m<enc.symbols[enc.symbols[i].slaves[k]].metadata.length; m++) {
					enc.symbols[i].data.data[set_pos--] = enc.symbols[enc.symbols[i].slaves[k]].metadata.data[m];
				}
			}
		}
	}
	return JAB_SUCCESS;
}

/*
 Initialize symbols
 @param enc the encode parameters
 @return JAB_SUCCESS | JAB_FAILURE
*/
int _initSymbols(jab_encode enc){
	//check all information for multi-symbol code are valid
	if(enc.symbol_number > 1) {
		for(int i=0; i<enc.symbol_number; i++) {
			if(enc.symbol_versions[i].x < 1 || enc.symbol_versions[i].x > 32 || enc.symbol_versions[i].y < 1 || enc.symbol_versions[i].y > 32) {
				return JAB_FAILURE; //Incorrect symbol version for symbol %d", i
			}
			if(enc.symbol_positions[i] < 0 || enc.symbol_positions[i] > MAX_SYMBOL_NUMBER) {
				return JAB_FAILURE; //Incorrect symbol position for symbol %d", i
			}
		}
	}
	//move the master symbol to the first
  if(enc.symbol_number > 1 && enc.symbol_positions[0] != 0) {
		for(int i=0; i<enc.symbol_number; i++) {
			if(enc.symbol_positions[i] == 0) {
				_swap_int (i, 0, enc.symbol_positions);
        _swap_vector_2D (i, 0, enc.symbol_versions);
				_swap_int8(i, 0, enc.symbol_ecc_levels);
				break;
			}
		}
	}
  //if no master symbol exists in multi-symbol code
  if(enc.symbol_number > 1 && enc.symbol_positions[0] != 0) {
  return JAB_FAILURE; //Master symbol missing
  }
  //if only one symbol but its position is not 0 - set to zero. Everything else makes no sense.
  if(enc.symbol_number == 1 && enc.symbol_positions[0] != 0) {
    enc.symbol_positions[0] = 0;
  }
  //check if a symbol position is used twice
  for(int i=0; i<enc.symbol_number-1; i++) {
    for(int j=i+1; j<enc.symbol_number; j++) {
      if(enc.symbol_positions[i] == enc.symbol_positions[j]) {
        return JAB_FAILURE; //Duplicate symbol position
      }
    }
  }
	//assign docked symbols to their hosts
  if(_assignDockedSymbols(enc) == JAB_FAILURE) {
    return JAB_FAILURE;
  }
  //check if the docked symbol size matches the docked side of its host
  if(_checkDockedSymbolSize(enc) == JAB_FAILURE) {
    return JAB_FAILURE;
  }
  //set symbol index and symbol side size
  for(int i=0; i<enc.symbol_number; i++) {
    //set symbol index
    enc.symbols[i].index = i;
    //set symbol side size
    enc.symbols[i].side_size.x = VERSION2SIZE(enc.symbol_versions[i].x);
    enc.symbols[i].side_size.y = VERSION2SIZE(enc.symbol_versions[i].y);
  }
  return JAB_SUCCESS;
}

/*
 Set metadata for slave symbols
 @param enc the encode parameters
 @return JAB_SUCCESS | JAB_FAILURE
*/
int _setSlaveMetadata(jab_encode enc) {
	//set slave metadata variables
	for(int i=1; i<enc.symbol_number; i++) {
		int SS, SE, V = 0, E1 = 0, E2 = 0;
		int metadata_length = 2; //Part I length
		//SS and V
		if(enc.symbol_versions[i].x != enc.symbol_versions[enc.symbols[i].host].x) {
		  	SS = 1;
			V = enc.symbol_versions[i].x - 1;
			metadata_length += 5;
		}
		else if(enc.symbol_versions[i].y != enc.symbol_versions[enc.symbols[i].host].y) {
			SS = 1;
			V = enc.symbol_versions[i].y - 1;
			metadata_length += 5;
		} else {
			SS = 0;
		}
		//SE and E
		if(enc.symbol_ecc_levels[i] == 0 || enc.symbol_ecc_levels[i] == enc.symbol_ecc_levels[enc.symbols[i].host]) {
			SE = 0;
		} else {
			SE = 1;
			E1 = ecclevel2wcwr[enc.symbol_ecc_levels[i]][0] - 3;
			E2 = ecclevel2wcwr[enc.symbol_ecc_levels[i]][1] - 4;
			metadata_length += 6;
		}
		//write slave metadata
		enc.symbols[i].metadata = jab_data(); // (jab_data *)malloc(sizeof(jab_data) + metadata_length*sizeof(jab_char));
    enc.symbols[i].metadata.data = Uint8List(metadata_length);
		// if(enc.symbols[i].metadata == null) {
		// 	// reportError("Memory allocation for metadata in slave symbol failed");
		// 	return JAB_FAILURE;
		// }
		enc.symbols[i].metadata.length = metadata_length;
		//Part I
		enc.symbols[i].metadata.data[0] = SS;
		enc.symbols[i].metadata.data[1] = SE;
		//Part II
		if(SS == 1) {
			_convert_dec_to_bin(V, enc.symbols[i].metadata.data, 2, 5);
		}
		if(SE == 1) {
			int start_pos = (SS == 1) ? 7 : 2;
			_convert_dec_to_bin(E1, enc.symbols[i].metadata.data, start_pos, 3);
			_convert_dec_to_bin(E2, enc.symbols[i].metadata.data, start_pos+3, 3);
		}
	}
	return JAB_SUCCESS;
}

/*
 Generate JABCode
 @param enc the encode parameters
 @param data the input data
 @return 0:success | 1: out of memory | 2:no input data | 3:incorrect symbol version or position | 4: input data too long
*/
int generateJABCode(jab_encode enc, jab_data data) {
  //Check data
  // if(data == null) {
  //   return 2;
  // }
  if(data.length == 0) {
    return 2;
  }

  //initialize symbols and set metadata in symbols
  if(_initSymbols(enc) != JAB_SUCCESS) {
    return 3;
  }

  //get the optimal encoded length and encoding sequence
  int encoded_length = 0;
  var encode_seq = _analyzeInputData(data, encoded_length);
  if(encode_seq == null) {
    return 1; //Analyzing input data failed
  }
  //encode data using optimal encoding modes
  var encoded_data = _encodeData(data, encoded_length, encode_seq);
  if(encoded_data == null) {
    return 1;
  }
  //set master symbol version if not given
  if(enc.symbol_number == 1 && (enc.symbol_versions[0].x == 0 || enc.symbol_versions[0].y == 0)) {
    if(_setMasterSymbolVersion(enc, encoded_data) == JAB_FAILURE) {
      return 4;
    }
  }
  //set metadata for slave symbols
  if(_setSlaveMetadata(enc) == JAB_FAILURE) {
    return 1;
  }
	//assign encoded data into symbols
	if(_fitDataIntoSymbols(enc, encoded_data) == JAB_FAILURE) {
		return 4;
	}
	//set master metadata
	if(_isDefaultMode(enc) == JAB_FAILURE) {
		if(_encodeMasterMetadata(enc) == JAB_FAILURE) {
      return 1; //Encoding master symbol metadata failed
		}
	}

  //encode each symbol in turn
  for(int i=0; i<enc.symbol_number; i++) {
    //error correction for data
    var ecc_encoded_data = encodeLDPC(enc.symbols[i].data, enc.symbols[i].wcwr);
    if(ecc_encoded_data == null) {
      return 1; //LDPC encoding for the data in symbol %d failed", i
    }
    //interleave
    interleaveData(ecc_encoded_data);
    //create Matrix
    var cm_flag = _createMatrix(enc, i, ecc_encoded_data);
    if(cm_flag == JAB_FAILURE) {
      return 1; //Creating matrix for symbol %d failed", i
    }
  }

  //mask all symbols in the code
  var cp = _getCodePara(enc);
  // if(cp == JAB_FAILURE) {
  //   return 1;
  // }
  if(_isDefaultMode(enc) == JAB_SUCCESS) {	//default mode
    maskSymbols(enc, DEFAULT_MASKING_REFERENCE, null, null);
  } else {
    var mask_reference = maskCode(enc, cp);
    if(mask_reference < 0) {
      return 1;
    }
    if(mask_reference != DEFAULT_MASKING_REFERENCE) {
      //re-encode PartII of master symbol metadata
      _updateMasterMetadataPartII(enc, mask_reference);
      //update the masking reference in master symbol metadata
      _placeMasterMetadataPartII(enc);
    }
  }

  //create the code bitmap
  var cb_flag = _createBitmap(enc, cp);
  if(cb_flag == JAB_FAILURE) {
    return 1; //Creating the code bitmap failed
  }
  return 0;
}

