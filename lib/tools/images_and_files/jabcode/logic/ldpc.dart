/*
 libjabcode - JABCode Encoding/Decoding Library

 Copyright 2016 by Fraunhofer SIT. All rights reserved.
 See LICENSE file for full terms of use and distribution.

 Contact: Huajian Liu <liu@sit.fraunhofer.de>
			Waldemar Berchtold <waldemar.berchtold@sit.fraunhofer.de>

  LDPC encoder and decoder
*/

import 'dart:core';
import 'dart:math';
import 'dart:typed_data';

import 'pseudo_random.dart';
import 'package:gc_wizard/tools/images_and_files/jabcode/logic/jabcode_h.dart';

const _LPDC_METADATA_SEED =	38545;
const _LPDC_MESSAGE_SEED =	785465;

/*
 Create matrix A for message data
 @param wc the number of '1's in a column
 @param wr the number of '1's in a row
 @param capacity the number of columns of the matrix
 @return the matrix A | null if failed (out of memory)
*/
List<int> _createMatrixA(int wc, int wr, int capacity) {
  int nb_pcb;
  if(wr<4) {
    nb_pcb=capacity~/2;
  } else {
    nb_pcb=(capacity/wr*wc).toInt();
  }

  int effwidth=(capacity/32.0).ceil()*32;
  int offset=(capacity/32.0).ceil();
  //create a matrix with '0' entries
  var matrixA=List<int>.filled(((capacity/32.0).ceil())*nb_pcb, 0);
  var permutation=List<int>.filled(capacity, 0); //calloc(, sizeof(int)); //(int *)calloc

  for (int i=0;i<capacity;i++) {
    permutation[i]=i;
  }

  //Fill the first set with consecutive ones in each row
  for (int i=0;i<capacity/wr;i++) {
    for (int j=0;j<wr;j++) {
      matrixA[(i*(effwidth+wr)+j)~/32] |= 1 << (31 - ((i*(effwidth+wr)+j)%32));
    }
  }
  //Permutate the columns and fill the remaining matrix
  //generate matrixA by following Gallagers algorithm
  setSeed(_LPDC_MESSAGE_SEED);
  for (int i=1; i<wc; i++) {
    int off_index=i*(capacity/wr).toInt();
    for (int j=0;j<capacity;j++) {
      int pos = ( lcg64_temper() / UINT32_MAX * (capacity - j) ).toInt();
      for (int k=0;k<capacity/wr;k++) {
        matrixA[((off_index+k)*offset+j/32).toInt()] |= ((matrixA[(permutation[pos]/32+k*offset).toInt()] >> (31-permutation[pos]%32)) & 1) << (31-j%32);
      }
      int  tmp = permutation[capacity - 1 -j];
      permutation[capacity - 1 - j] = permutation[pos];
      permutation[pos] = tmp;
    }
  }
  return matrixA;
}

/*
 Gauss Jordan elimination algorithm
 @param matrixA the matrix
 @param wc the number of '1's in a column
 @param wr the number of '1's in a row
 @param capacity the number of columns of the matrix
 @param matrix_rank the rank of the matrix
 @param encode specifies if function is called by the encoder or decoder
 @return item1 0: success | 1: fatal error (out of memory)
 @return item2 matrix_rank the rank of the matrix
*/
({bool success, int matrix_rank}) _GaussJordan(List<int> matrixA, int wc, int wr, int matrix_rank, int capacity, bool encode) {
  int loop=0;
  int nb_pcb;
  if(wr<4) {
    nb_pcb=capacity~/2;
  } else {
    nb_pcb=(capacity/wr*wc).toInt();
  }

  int offset=(capacity/ 32.0).ceil();

  var matrixH=List<int>.filled(offset*nb_pcb, 0);// (int *)calloc(offset*nb_pcb,sizeof(int));
  var column_arrangement=List<int>.filled(capacity, 0);
  var processed_column=List<bool>.filled(capacity, false);
  var zero_lines_nb=List<int>.filled(nb_pcb, 0);
  var swap_col=List<int>.filled(2*capacity, 0);

  matrixH.setRange(0, offset*nb_pcb, matrixA);// memcpy(matrixH,matrixA,offset*nb_pcb*sizeof(int));

  int zero_lines=0;

  for (int i=0; i<nb_pcb; i++) {
    int pivot_column=capacity+1;
    for (int j=0; j<capacity; j++) {
      if(((matrixH[((offset*32*i+j)~/32)] >> (31-(offset*32*i+j)%32)) & 1) != 0) {
        pivot_column=j;
        break;
      }
    }
    if(pivot_column < capacity) {
      processed_column[pivot_column] = true;
      column_arrangement[pivot_column]=i;
      if (pivot_column>=nb_pcb) {
        swap_col[2*loop]=pivot_column;
        loop++;
      }

      int off_index=(pivot_column/32).toInt();
      int off_index1=pivot_column%32;
      for (int j=0; j<nb_pcb; j++) {
        // ToDo stimmt meine Umsetzung ?
        // ((matrixH[(off_index+j*offset).toInt()] >> (31-off_index1)) & 1) -> ungerade 1, gerade 0
        if (((matrixH[off_index + j * offset] >> (31 - off_index1)) & 1) != 0 && j != i) {
          //subtract pivot row GF(2)
          for (int k=0;k<offset;k++) {
            matrixH[k+offset*j] ^= matrixH[k+offset*i];
          }
        }
      }
    } else { //zero line
      zero_lines_nb[zero_lines]=i;
      zero_lines++;
    }
  }

  matrix_rank=nb_pcb-zero_lines;
  int loop2=0;
  for(int i= matrix_rank;i<nb_pcb;i++) {
    if(column_arrangement[i] > 0) {
      for (int j=0;j < nb_pcb;j++) {
        if (processed_column[j] == false) {
          column_arrangement[j]=column_arrangement[i];
          column_arrangement[i]=0;
          processed_column[j] = true;
          processed_column[i] = false;
          swap_col[2*loop]=i;
          swap_col[2*loop+1]=j;
          column_arrangement[i]=j;
          loop++;
          loop2++;
          break;
        }
      }
    }
  }

  int loop1=0;
  for (int kl=0;kl< nb_pcb;kl++) {
    if((processed_column[kl] == false) && (loop1 < loop-loop2)) {
      column_arrangement[kl]=column_arrangement[swap_col[2*loop1]];
      processed_column[kl] = true;
      swap_col[2*loop1+1] = kl;
      loop1++;
    }
  }

  loop1=0;
  for (int kl=0;kl< nb_pcb;kl++) {
    if(processed_column[kl]==false) {
      column_arrangement[kl]=zero_lines_nb[loop1];
      loop1++;
    }
  }
  //rearrange matrixH if encoder and store it in matrixA
  //rearrange matrixA if decoder
  if(encode) {
    for(int i=0;i< nb_pcb;i++) {
      matrixA.setRange(i*offset, i*offset+offset, matrixH.sublist(column_arrangement[i]*offset)); //memcpy(matrixA+i*offset,matrixH+column_arrangement[i]*offset,offset*sizeof(int));
    }

    //swap columns
    int tmp=0;
    for (int i=0;i<loop;i++) {
      for (int j=0;j<nb_pcb;j++) {
        tmp ^= (-((matrixA[(swap_col[2*i]/32+j*offset).toInt()] >> (31-swap_col[2*i]%32)) & 1) ^ tmp) & (1 << 0);
        matrixA[(swap_col[2*i]/32+j*offset).toInt()]   ^= (-((matrixA[(swap_col[2*i+1]/32+j*offset).toInt()] >> (31-swap_col[2*i+1]%32)) & 1) ^ matrixA[(swap_col[2*i]/32+j*offset).toInt()]) & (1 << (31-swap_col[2*i]%32));
        matrixA[(swap_col[2*i+1]/32+offset*j).toInt()] ^= (-((tmp >> 0) & 1) ^ matrixA[(swap_col[2*i+1]/32+offset*j).toInt()]) & (1 << (31-swap_col[2*i+1]%32));
      }
    }
  } else {
    //    memcpy(matrixH,matrixA,offset*nb_pcb*sizeof(int));
    for (int i=0;i< nb_pcb;i++) {
      matrixH.setRange(i*offset, i*offset+offset, matrixA.sublist(column_arrangement[i]*offset));  //memcpy(matrixH+i*offset,matrixA+column_arrangement[i]*offset,offset*sizeof(int));
    }

    //swap columns
    int tmp=0;
    for (int i=0;i<loop;i++) {
      for (int j=0;j<nb_pcb;j++) {
        tmp ^= (-((matrixH[(swap_col[2*i]/32+j*offset).toInt()] >> (31-swap_col[2*i]%32)) & 1) ^ tmp) & (1 << 0);
        matrixH[(swap_col[2*i]/32+j*offset).toInt()]   ^= (-((matrixH[(swap_col[2*i+1]/32+j*offset).toInt()] >> (31-swap_col[2*i+1]%32)) & 1) ^ matrixH[(swap_col[2*i]/32+j*offset).toInt()]) & (1 << (31-swap_col[2*i]%32));
        matrixH[(swap_col[2*i+1]/32+offset*j).toInt()] ^= (-((tmp >> 0) & 1) ^ matrixH[(swap_col[2*i+1]/32+offset*j).toInt()]) & (1 << (31-swap_col[2*i+1]%32));
      }
    }
    matrixA.setRange(0, offset*nb_pcb, matrixH); //memcpy(,,offset*nb_pcb*sizeof(int));
  }

  return (success: true, matrix_rank: matrix_rank);
}

/*
 Create the error correction matrix for the metadata
 @param wc the number of '1's in a column
 @param capacity the number of columns of the matrix
 @return the error correction matrix | null if failed
*/
List<int> _createMetadataMatrixA(int wc, int capacity) {
  int nb_pcb=capacity~/2;
  int offset=(capacity/32.0).ceil();
  //create a matrix with '0' entries
  var matrixA = List<int>.filled(offset*nb_pcb, 0); //(int *)calloc(offset*nb_pcb,sizeof(int));
  var permutation = List<int>.filled(capacity, 0); //calloc(, sizeof(int));

  for (int i=0;i<capacity;i++) {
    permutation[i]=i;
  }
  setSeed(_LPDC_METADATA_SEED);
  int nb_once=(capacity*nb_pcb/wc+3.0).toInt();
  nb_once=nb_once~/nb_pcb;
  //Fill matrix randomly
  for (int i=0;i<nb_pcb;i++) {
    for (int j=0; j< nb_once; j++) {
      int pos = ( lcg64_temper() / UINT32_MAX * (capacity-j) ).toInt();
      matrixA[(i*offset+permutation[pos]/32).toInt()] |= 1 << (31-permutation[pos]%32);
      int  tmp = permutation[capacity - 1 -j];
      permutation[capacity - 1 -j] = permutation[pos];
      permutation[pos] = tmp;
    }
  }
  return matrixA;
}

/*
 Create the generator matrix to encode messages
 @param matrixA the error correction matrix
 @param capacity the number of columns of the matrix
 @param Pn the number of net message bits
 @return the generator matrix | null if failed (out of memory)
*/
List<int> _createGeneratorMatrix(List<int> matrixA, int capacity, int Pn) {
  int effwidth=(Pn/32.0).ceil()*32;
  int offset=(Pn/32.0).ceil();
  int offset_cap=(capacity/32.0).ceil();
  //create G [I C]
  //remember matrixA is now A = [I CT], now use it and create G=[CTI ]
  var G= List<int>.filled(offset*capacity, 0); // int *)calloc(offset*capacity, sizeof(int));

  //fill identity matrix
  for (int i=0; i< Pn; i++) {
    G[((capacity-Pn+i) * offset+i/32).toInt()] |= 1 << (31-i%32);
  }

  //copy CT matrix from A to G
  int matrix_index=capacity-Pn;
  int loop=0;

  for (int i=0; i<(capacity-Pn)*effwidth; i++) {
    if(matrix_index >= capacity) {
      loop++;
      matrix_index=capacity-Pn;
    }
    if(i % effwidth < Pn) {
      G[i~/32] ^= (-((matrixA[(matrix_index/32+offset_cap*loop).toInt()] >> (31-matrix_index%32)) & 1) ^ G[i~/32]) & (1 << (31-i%32));
      matrix_index++;
    }
  }
  return G;
}

/*
 LDPC encoding
 @param data the data to be encoded
 @param coderate_params the two code rate parameter wc and wr indicating how many '1' in a column (Wc) and how many '1' in a row of the parity check matrix
 @return the encoded data | null if failed
*/
jab_data? encodeLDPC(jab_data data, List<int> coderate_params) {
  int matrix_rank=0;
  int wc, wr, Pg, Pn;       //number of '1' in column //number of '1' in row //gross message length //number of parity check symbols //calculate required parameters
  wc=coderate_params[0];
  wr=coderate_params[1];
  Pn=data.length;
  if(wr > 0){
    Pg = ((Pn*wr)/(wr-wc)).ceil();
    Pg = wr * ((Pg / wr).ceil());
  } else {
    Pg=Pn*2;
  }

  //in order to speed up the ldpc encoding, sub blocks are established
  int nb_sub_blocks=0;
  for(int i=1;i<10000;i++) {
    if(Pg / i < 2700) {
      nb_sub_blocks=i;
      break;
    }
  }
  int Pg_sub_block=0;
  int Pn_sub_block=0;
  if(wr > 0) {
    Pg_sub_block=(((Pg / nb_sub_blocks) / wr) * wr).toInt();
    Pn_sub_block=Pg_sub_block * (wr-wc) ~/ wr;
  } else {
    Pg_sub_block=Pg;
    Pn_sub_block=Pn;
  }
  nb_sub_blocks=Pg ~/ Pg_sub_block;//nb_sub_blocks;
  int encoding_iterations=nb_sub_blocks;
  if(Pn_sub_block * nb_sub_blocks < Pn) {
    encoding_iterations--;
  }
  List<int> matrixA;
  //Matrix A
  if(wr > 0) {
    matrixA = _createMatrixA(wc, wr, Pg_sub_block);
  } else {
    matrixA = _createMetadataMatrixA(wc, Pg_sub_block);
  }
  // if(matrixA == null) {
  //   return null;
  // }

  bool encode=true;
  var result = _GaussJordan(matrixA, wc, wr, Pg_sub_block, matrix_rank,encode);
  matrix_rank = result.matrix_rank;
  if(!result.success) {
    return null;
  }

  //Generator Matrix
  var G = _createGeneratorMatrix(matrixA, Pg_sub_block, Pg_sub_block - matrix_rank);
  // if(G == null) {
  //   return null;
  // }

  var ecc_encoded_data = jab_data(); //(jab_data *)malloc(sizeof(jab_data) + Pg*sizeof(jab_char));
  ecc_encoded_data.data = Uint8List(Pg);

  ecc_encoded_data.length = Pg;
  int temp,loop;
  int offset=((Pg_sub_block - matrix_rank)/32.0).ceil();
  //G * message = ecc_encoded_Data
  for (int iter=0; iter < encoding_iterations; iter++) {
    for (int i=0;i<Pg_sub_block;i++) {
      temp=0;
      loop=0;
      int offset_index=offset*i;
      for (int j=iter*Pn_sub_block; j < (iter+1)*Pn_sub_block; j++) {
        temp ^= (((G[(offset_index + loop/32).toInt()] >> (31-loop%32)) & 1) & ((data.data[j] >> 0) & 1)) << 0;
        loop++;
      }
      ecc_encoded_data.data[i+iter*Pg_sub_block]= ((temp >> 0) & 1);
    }
  }

  if(encoding_iterations != nb_sub_blocks) {
    int start=encoding_iterations*Pn_sub_block;
    int last_index=encoding_iterations*Pg_sub_block;
    matrix_rank=0;
    Pg_sub_block=Pg - encoding_iterations * Pg_sub_block;
    Pn_sub_block=Pg_sub_block * (wr-wc) ~/ wr;
    var matrixA = _createMatrixA(wc, wr, Pg_sub_block);
    // if(matrixA == null) {
    //   return null;
    // }

    var result = _GaussJordan(matrixA, wc, wr, Pg_sub_block, matrix_rank,encode);
    matrix_rank = result.matrix_rank;
    if(!result.success) {
      return null;
    }

    var G = _createGeneratorMatrix(matrixA, Pg_sub_block, Pg_sub_block - matrix_rank);
    // if(G == null) {
    //   return null;
    // }

    offset=((Pg_sub_block - matrix_rank)/32.0).ceil();
    for (int i=0;i<Pg_sub_block;i++){
      temp=0;
      loop=0;
      int offset_index=offset*i;
      for (int j=start; j < data.length; j++) {
        temp ^= (((G[(offset_index + loop/32).toInt()] >> (31-loop%32)) & 1) & ((data.data[j] >> 0) & 1)) << 0;
        loop++;
      }
      ecc_encoded_data.data[i+last_index]= ((temp >> 0) & 1);
    }
  }
  return ecc_encoded_data;
}

/*
 Iterative hard decision error correction decoder
 @param data the received data
 @param matrix the parity check matrix
 @param length the encoded data length
 @param height the number of check bits
 @param max_iter the maximal number of iterations
 @param is_correct indicating if decodedMessage function could correct all errors
 @param start_pos indicating the position to start reading in data array
 @return item1  bool is_correct /
 @return item2 error correction succeeded | 0: fatal error (out of memory)
*/
({bool is_correct, bool success}) _decodeMessage(List<int> data, List<int> matrix, int length, int height, int max_iter, int start_pos) {
  var max_val=List<int>.filled(length, 0); // ()int *)calloc(length, sizeof(int));
  var equal_max=List<int>.filled(length, 0); //(int *)calloc(length, sizeof(int));
  var prev_index=List<int>.filled(length, 0); //(int *)calloc(length, sizeof(int));

  bool is_correct=true;
  int check=0;
  int counter=0, prev_count=0;
  int max=0;
  int offset=(length/32.0).ceil();

  for (int kl=0;kl<max_iter;kl++) {
    max=0;
    for(int j=0;j<height;j++) {
      check=0;
      for (int i=0;i<length;i++) {
        if((((matrix[(j*offset+i/32).toInt()] >> (31-i%32)) & 1) & ((data[start_pos+i] >> 0) & 1))!=0) {
          check+=1;
        }
      }
      check=check%2;
      if(check == 0) {
        for(int k=0;k<length;k++) {
          if(((matrix[(j*offset+k/32).toInt()] >> (31-k%32)) & 1)!= 0) {
            max_val[k]++;
          }
        }
      }
    }
    //find maximal values in max_val
    bool is_used=false;
    for (int j=0;j<length;j++) {
      is_used=false;
      for(int i=0;i< prev_count;i++) {
        if(prev_index[i]==j) {
          is_used=true;
        }
      }
      if(max_val[j]>=max && !is_used) {
        if(max_val[j]!=max) {
          counter=0;
        }
        max=max_val[j];
        equal_max[counter]=j;
        counter++;
      }
      max_val[j]=0;
    }
    //flip bits
    if(max>0) {
      is_correct=false;
      if(length < 36) {
        int rand_tmp=Random().nextInt(0x7fff.toInt())~/(UINT32_MAX * counter).toDouble(); // rand()
        prev_index[0]=start_pos+equal_max[rand_tmp];
        data[start_pos+equal_max[rand_tmp]]=(data[start_pos+equal_max[rand_tmp]]+1)%2;
      } else {
        for(int j=0; j< counter;j++) {
          prev_index[j]=start_pos+equal_max[j];
          data[start_pos+equal_max[j]]=(data[start_pos+equal_max[j]]+1)%2;
        }
      }
      prev_count=counter;
      counter=0;
    } else {
      is_correct=true;
    }

    if(is_correct == false && kl+1 < max_iter) {
      is_correct=true;
    } else {
      break;
    }
  }

  return (is_correct: is_correct, success : true);
}

/*
 LDPC decoding to perform hard decision
 @param data the encoded data
 @param length the encoded data length
 @param wc the number of '1's in a column
 @param wr the number of '1's in a row
 @return the decoded data length | 0: fatal error (out of memory)
*/
int decodeLDPChd(List<int> data, int length, int wc, int wr) {
  int matrix_rank=0;
  int max_iter=25;
  int Pn;
  int Pg;
  int decoded_data_len = 0;
  if(wr > 3) {
    Pg = (wr * (length / wr)).toInt();
    Pn = Pg * (wr - wc) ~/ wr; //number of source symbols
  } else {
    Pg=length;
    Pn=length~/2;
    wc=2;
    if(Pn>36) {
      wc=3;
    }
  }
  decoded_data_len=Pn;

  //in order to speed up the ldpc encoding, sub blocks are established
  int nb_sub_blocks=0;
  for(int i=1;i<10000;i++) {
    if(Pg / i < 2700) {
      nb_sub_blocks=i;
      break;
    }
  }
  int Pg_sub_block=0;
  int Pn_sub_block=0;
  if(wr > 3) {
    Pg_sub_block=(((Pg / nb_sub_blocks) / wr) * wr).toInt();
    Pn_sub_block=Pg_sub_block * (wr-wc) ~/ wr;
  } else {
    Pg_sub_block=Pg;
    Pn_sub_block=Pn;
  }
  int decoding_iterations=nb_sub_blocks=Pg ~/ Pg_sub_block;//nb_sub_blocks;
  if(Pn_sub_block * nb_sub_blocks < Pn) {
    decoding_iterations--;
  }

  //parity check matrix
  List<int> matrixA;
  if(wr > 0) {
    matrixA = _createMatrixA(wc, wr,Pg_sub_block);
  } else {
    matrixA = _createMetadataMatrixA(wc, Pg_sub_block);
  }
  // if(matrixA == null) {
  //   return 0; //LDPC matrix could not be created in decoder.
  // }
  bool encode=false;
  var result = _GaussJordan(matrixA, wc, wr, Pg_sub_block, matrix_rank, encode);
  matrix_rank = result.matrix_rank;
  if(!result.success) {
    return 0; //Gauss Jordan Elimination in LDPC encoder failed.
  }

  int old_Pg_sub=Pg_sub_block;
  int old_Pn_sub=Pn_sub_block;
  for (int iter = 0; iter < nb_sub_blocks; iter++) {
    if(decoding_iterations != nb_sub_blocks && iter == decoding_iterations) {
      matrix_rank=0;
      Pg_sub_block=Pg - decoding_iterations * Pg_sub_block;
      Pn_sub_block=Pg_sub_block * (wr-wc) ~/ wr;
      var matrixA1 = _createMatrixA(wc, wr, Pg_sub_block);
      // if(matrixA1 == null) {
      //   return 0; //LDPC matrix could not be created in decoder.
      // }
      bool encode=false;
      var result = _GaussJordan(matrixA1, wc, wr, Pg_sub_block, matrix_rank, encode);
      matrix_rank = result.matrix_rank;
      if(!result.success) {
        return 0; //Gauss Jordan Elimination in LDPC encoder failed.
      }
      //ldpc decoding
      //first check syndrom
      bool is_correct=true;
      int offset=(Pg_sub_block/32.0).ceil();
      for (int i=0;i< matrix_rank; i++) {
        int temp=0;
        for (int j=0;j<Pg_sub_block;j++) {
          temp ^= (((matrixA1[(i*offset+j/32).toInt()] >> (31-j%32)) & 1) & ((data[iter*old_Pg_sub+j] >> 0) & 1)) << 0; //
        }
        if (temp != 0) {
          is_correct=false;//message not correct
          break;
        }
      }

      if(!is_correct) {
        int start_pos=iter*old_Pg_sub;
        var result = _decodeMessage(data, matrixA1, Pg_sub_block, matrix_rank, max_iter,start_pos);
        is_correct=result.is_correct;
        if(!result.success) {
          return 0;
        }
      }
      if(!is_correct) {
        bool is_correct=true;
        for (int i=0;i< matrix_rank; i++) {
          int temp=0;
          for (int j=0;j<Pg_sub_block;j++) {
            temp ^= (((matrixA1[(i*offset+j/32).toInt()] >> (31-j%32)) & 1) & ((data[iter*old_Pg_sub+j] >> 0) & 1)) << 0;
          }
          if (temp != 0) {
            is_correct=false;//message not correct
            break;
          }
        }
        if(!is_correct) {
          return 0;
        }
      }
    } else {
      //ldpc decoding
      //first check syndrom
      bool is_correct=true;
      int offset=(Pg_sub_block/32.0).ceil();
      for (int i=0;i< matrix_rank; i++) {
        int temp=0;
        for (int j=0;j<Pg_sub_block;j++) {
          temp ^= (((matrixA[(i*offset+j/32).toInt()] >> (31-j%32)) & 1) & ((data[iter*old_Pg_sub+j] >> 0) & 1)) << 0;
        }
        if (temp != 0) {
          is_correct=false;//message not correct
          break;
        }
      }

      if (!is_correct) {
        int start_pos=iter*old_Pg_sub;
        var result =_decodeMessage(data, matrixA, Pg_sub_block, matrix_rank, max_iter, start_pos);
        is_correct=result.is_correct;
        if(!result.success) {
          return 0;
        }

        is_correct=true;
        for (int i=0;i< matrix_rank; i++) {
          int temp=0;
          for (int j=0;j<Pg_sub_block;j++) {
            temp ^= (((matrixA[(i*offset+j/32).toInt()] >> (31-j%32)) & 1) & ((data[iter*old_Pg_sub+j] >> 0) & 1)) << 0;
          }
          if (temp != 0) {
            is_correct=false;//message not correct
            break;
          }
        }
        if(!is_correct) {
          return 0;
        }
      }
    }
    int loop=0;
    for (int i=iter*old_Pg_sub;i < iter * old_Pg_sub + Pn_sub_block; i++) {
      data[iter*old_Pn_sub+loop]=data[i+ matrix_rank];
      loop++;
    }
  }
  return decoded_data_len;
}
