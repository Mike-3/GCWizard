/**
 * libjabcode - JABCode Encoding/Decoding Library
 *
 * Copyright 2016 by Fraunhofer SIT. All rights reserved.
 * See LICENSE file for full terms of use and distribution.
 *
 * Contact: Huajian Liu <liu@sit.fraunhofer.de>
 *			Waldemar Berchtold <waldemar.berchtold@sit.fraunhofer.de>
 *
 * @file ldpc.c
 * @brief LDPC encoder and decoder
 */

// #include <stdlib.h>
// #include <math.h>
// #include "jabcode.h"
// #include "ldpc.h"
// #include <string.h>
// #include <stdio.h>
// #include "detector.h"
// #include "pseudo_random.h"

import 'dart:core';
import 'dart:typed_data';

import 'package:gc_wizard/logic/tools/images_and_files/jab_code/pseudo_random.dart';
import 'package:gc_wizard/logic/tools/images_and_files/jab_code/pseudo_random_h.dart';

import 'ldpc_h.dart';

/**
 * @brief Create matrix A for message data
 * @param wc the number of '1's in a column
 * @param wr the number of '1's in a row
 * @param capacity the number of columns of the matrix
 * @return the matrix A | null if failed (out of memory)
*/
List<int> createMatrixA(int wc, int wr, int capacity)
{
    int nb_pcb;
    if(wr<4)
        nb_pcb=(capacity/2).toInt();
    else
        nb_pcb=(capacity/wr*wc).toInt();

    int effwidth=(capacity/32.0).ceil()*32;
    int offset=(capacity/32.0).ceil();
    //create a matrix with '0' entries
    var matrixA=List<int>.filled(((capacity/32.0).ceil())*nb_pcb, 0);
    if(matrixA == null)
    {
        // reportError("Memory allocation for matrix in LDPC failed");
        return null;
    }
    var permutation=List<int>.filled(capacity, 0); //calloc(, sizeof(int)); //(int *)calloc
    if(permutation == null)
    {
        // reportError("Memory allocation for matrix in LDPC failed");
        // free(matrixA);
        return null;
    }
    for (int i=0;i<capacity;i++)
        permutation[i]=i;

    //Fill the first set with consecutive ones in each row
    for (int i=0;i<capacity/wr;i++)
    {
        for (int j=0;j<wr;j++)
            matrixA[((i*(effwidth+wr)+j)/32).toInt()] |= 1 << (31 - ((i*(effwidth+wr)+j)%32));
    }
    //Permutate the columns and fill the remaining matrix
    //generate matrixA by following Gallagers algorithm
    setSeed(LPDC_MESSAGE_SEED);
    for (int i=1; i<wc; i++)
    {
        int off_index=i*(capacity/wr).toInt();
        for (int j=0;j<capacity;j++)
        {
            int pos = ( lcg64_temper() / UINT32_MAX * (capacity - j) ).toInt();
            for (int k=0;k<capacity/wr;k++)
                matrixA[((off_index+k)*offset+j/32).toInt()] |= ((matrixA[(permutation[pos]/32+k*offset).toInt()] >> (31-permutation[pos]%32)) & 1) << (31-j%32);
            int  tmp = permutation[capacity - 1 -j];
            permutation[capacity - 1 - j] = permutation[pos];
            permutation[pos] = tmp;
        }
    }
    // free(permutation);
    return matrixA;
}

/**
 * @brief Gauss Jordan elimination algorithm
 * @param matrixA the matrix
 * @param wc the number of '1's in a column
 * @param wr the number of '1's in a row
 * @param capacity the number of columns of the matrix
 * @param matrix_rank the rank of the matrix
 * @param encode specifies if function is called by the encoder or decoder
 * @return 0: success | 1: fatal error (out of memory)
*/
int GaussJordan(List<int> matrixA, int wc, int wr, int capacity, bool encode)
{
    int loop=0;
    int nb_pcb;
    if(wr<4)
        nb_pcb=(capacity/2).toInt();
    else
        nb_pcb=(capacity/wr*wc).toInt();

    int offset=(capacity/32.0).ceil();

    var matrixH=List<int>.filled(offset*nb_pcb, 0);// (int *)calloc(offset*nb_pcb,sizeof(int));
    if(matrixH == null)
    {
        // reportError("Memory allocation for matrix in LDPC failed");
        return 1;
    }
    matrixH.setRange(0, offset*nb_pcb, matrixA);// memcpy(matrixH,matrixA,offset*nb_pcb*sizeof(int));

    var column_arrangement=List<int>.filled(capacity, 0);
    if(column_arrangement == null)
    {
        // reportError("Memory allocation for matrix in LDPC failed");
        // free(matrixH);
        return 1;
    }
    var processed_column=List<bool>.filled(capacity, false);
    if(processed_column == null)
    {
        // reportError("Memory allocation for matrix in LDPC failed");
        // free(matrixH);
        // free(column_arrangement);
        return 1;
    }
    var zero_lines_nb=List<int>.filled(nb_pcb, 0);
    if(zero_lines_nb == null)
    {
        // reportError("Memory allocation for matrix in LDPC failed");
        // free(matrixH);
        // free(column_arrangement);
        // free(processed_column);
        return 1;
    }
    var swap_col=List<int>.filled(2*capacity, 0);
    if(swap_col == null)
    {
        // reportError("Memory allocation for matrix in LDPC failed");
        // free(matrixH);
        // free(column_arrangement);
        // free(processed_column);
        // free(zero_lines_nb);
        return 1;
    }

    int zero_lines=0;

    for (int i=0; i<nb_pcb; i++)
    {
        int pivot_column=capacity+1;
        for (int j=0; j<capacity; j++)
        {
            if(((matrixH[((offset*32*i+j)/32).toInt()] >> (31-(offset*32*i+j)%32)) & 1) != 0)
            {
                pivot_column=j;
                break;
            }
        }
        if(pivot_column < capacity)
        {
            processed_column[pivot_column]=1;
            column_arrangement[pivot_column]=i;
            if (pivot_column>=nb_pcb)
            {
                swap_col[2*loop]=pivot_column;
                loop++;
            }

            int off_index=(pivot_column/32).toInt();
            int off_index1=pivot_column%32;
            for (int j=0; j<nb_pcb; j++)
            {
                if ((((matrixH[(off_index+j*offset).toInt()] >> (31-off_index1)) & 1) && j) != i)
                {
                    //subtract pivot row GF(2)
                    for (int k=0;k<offset;k++)
                        matrixH[k+offset*j] ^= matrixH[k+offset*i];
                }
            }
        }
        else //zero line
        {
            zero_lines_nb[zero_lines]=i;
            zero_lines++;
        }
    }

    var matrix_rank=nb_pcb-zero_lines;
    int loop2=0;
    for(int i= matrix_rank;i<nb_pcb;i++)
    {
        if(column_arrangement[i] > 0)
        {
            for (int j=0;j < nb_pcb;j++)
            {
                if (processed_column[j] == 0)
                {
                    column_arrangement[j]=column_arrangement[i];
                    column_arrangement[i]=0;
                    processed_column[j]=true;
                    processed_column[i]=false;
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
    for (int kl=0;kl< nb_pcb;kl++)
    {
        if(processed_column[kl] == 0 && loop1 < loop-loop2)
        {
            column_arrangement[kl]=column_arrangement[swap_col[2*loop1]];
            processed_column[kl]=true;
            swap_col[2*loop1+1]=kl;
            loop1++;
        }
    }

    loop1=0;
    for (int kl=0;kl< nb_pcb;kl++)
    {
        if(processed_column[kl]==0)
        {
            column_arrangement[kl]=zero_lines_nb[loop1];
            loop1++;
        }
    }
    //rearrange matrixH if encoder and store it in matrixA
    //rearrange matrixA if decoder
    if(encode)
    {
        for(int i=0;i< nb_pcb;i++)
            matrixA.setRange(i*offset, end, iterable); //memcpy(matrixA+i*offset,matrixH+column_arrangement[i]*offset,offset*sizeof(int));

        //swap columns
        int tmp=0;
        for(int i=0;i<loop;i++)
        {
            for (int j=0;j<nb_pcb;j++)
            {
                tmp ^= (-((matrixA[(swap_col[2*i]/32+j*offset).toInt()] >> (31-swap_col[2*i]%32)) & 1) ^ tmp) & (1 << 0);
                matrixA[(swap_col[2*i]/32+j*offset).toInt()]   ^= (-((matrixA[(swap_col[2*i+1]/32+j*offset).toInt()] >> (31-swap_col[2*i+1]%32)) & 1) ^ matrixA[(swap_col[2*i]/32+j*offset).toInt()]) & (1 << (31-swap_col[2*i]%32));
                matrixA[(swap_col[2*i+1]/32+offset*j).toInt()] ^= (-((tmp >> 0) & 1) ^ matrixA[(swap_col[2*i+1]/32+offset*j).toInt()]) & (1 << (31-swap_col[2*i+1]%32));
            }
        }
    }
    else
    {
    //    memcpy(matrixH,matrixA,offset*nb_pcb*sizeof(int));
        for(int i=0;i< nb_pcb;i++)
             memcpy(matrixH+i*offset,matrixA+column_arrangement[i]*offset,offset*sizeof(int));

        //swap columns
        int tmp=0;
        for(int i=0;i<loop;i++)
        {
            for (int j=0;j<nb_pcb;j++)
            {
                tmp ^= (-((matrixH[(swap_col[2*i]/32+j*offset).toInt()] >> (31-swap_col[2*i]%32)) & 1) ^ tmp) & (1 << 0);
                matrixH[(swap_col[2*i]/32+j*offset).toInt()]   ^= (-((matrixH[(swap_col[2*i+1]/32+j*offset).toInt()] >> (31-swap_col[2*i+1]%32)) & 1) ^ matrixH[(swap_col[2*i]/32+j*offset).toInt()]) & (1 << (31-swap_col[2*i]%32));
                matrixH[(swap_col[2*i+1]/32+offset*j).toInt()] ^= (-((tmp >> 0) & 1) ^ matrixH[(swap_col[2*i+1]/32+offset*j).toInt()]) & (1 << (31-swap_col[2*i+1]%32));
            }
        }
        matrixA.setRange(0, offset*nb_pcb, matrixH); //memcpy(,,offset*nb_pcb*sizeof(int));
    }

    // free(column_arrangement);
    // free(processed_column);
    // free(zero_lines_nb);
    // free(swap_col);
    // free(matrixH);
    return 0;
}
//
/**
 * @brief Create the error correction matrix for the metadata
 * @param wc the number of '1's in a column
 * @param capacity the number of columns of the matrix
 * @return the error correction matrix | null if failed
*/
List<int> createMetadataMatrixA(int wc, int capacity)
{
    int nb_pcb=(capacity/2).toInt();
    int offset=(capacity/32.0).ceil();
    //create a matrix with '0' entries
    var matrixA = List<int>.filled(offset*nb_pcb, 0); //(int *)calloc(offset*nb_pcb,sizeof(int));
    if(matrixA == null)
    {
        // reportError("Memory allocation for matrix in LDPC failed");
        return null;
    }
    var permutation = List<int>.filled(capacity, 0); //calloc(, sizeof(int));
    if(permutation == null)
    {
        // reportError("Memory allocation for matrix in LDPC failed");
        // free(matrixA);
        return null;
    }
    for (int i=0;i<capacity;i++)
        permutation[i]=i;
    setSeed(LPDC_METADATA_SEED);
    int nb_once=(capacity*nb_pcb/wc+3.0).toInt();
    nb_once=(nb_once/nb_pcb).toInt();
    //Fill matrix randomly
    for (int i=0;i<nb_pcb;i++)
    {
        for (int j=0; j< nb_once; j++)
        {
            int pos = ( lcg64_temper() / UINT32_MAX * (capacity-j) ).toInt();
            matrixA[(i*offset+permutation[pos]/32).toInt()] |= 1 << (31-permutation[pos]%32);
            int  tmp = permutation[capacity - 1 -j];
            permutation[capacity - 1 -j] = permutation[pos];
            permutation[pos] = tmp;
        }
    }
    // free(permutation);
    return matrixA;
}
//
// /**
//  * @brief Create the generator matrix to encode messages
//  * @param matrixA the error correction matrix
//  * @param capacity the number of columns of the matrix
//  * @param Pn the number of net message bits
//  * @return the generator matrix | null if failed (out of memory)
// */
// int *createGeneratorMatrix(int* matrixA, int capacity, int Pn)
// {
//     int effwidth=ceil(Pn/(jab_float)32)*32;
//     int offset=ceil(Pn/(jab_float)32);
//     int offset_cap=ceil(capacity/(jab_float)32);
//     //create G [I C]
//     //remember matrixA is now A = [I CT], now use it and create G=[CT
//                 //                                                 I ]
//     int* G=(int *)calloc(offset*capacity, sizeof(int));
//     if(G == null)
//     {
//         reportError("Memory allocation for matrix in LDPC failed");
//         return null;
//     }
//
//     //fill identity matrix
//     for (int i=0; i< Pn; i++)
//         G[(capacity-Pn+i) * offset+i/32] |= 1 << (31-i%32);
//
//     //copy CT matrix from A to G
//     int matrix_index=capacity-Pn;
//     int loop=0;
//
//     for (int i=0; i<(capacity-Pn)*effwidth; i++)
//     {
//         if(matrix_index >= capacity)
//         {
//             loop++;
//             matrix_index=capacity-Pn;
//         }
//         if(i % effwidth < Pn)
//         {
//             G[i/32] ^= (-((matrixA[matrix_index/32+offset_cap*loop] >> (31-matrix_index%32)) & 1) ^ G[i/32]) & (1 << (31-i%32));
//             matrix_index++;
//         }
//     }
//     return G;
// }
//
// /**
//  * @brief LDPC encoding
//  * @param data the data to be encoded
//  * @param coderate_params the two code rate parameter wc and wr indicating how many '1' in a column (Wc) and how many '1' in a row of the parity check matrix
//  * @return the encoded data | null if failed
// */
// jab_data *encodeLDPC(jab_data* data, int* coderate_params)
// {
//     int matrix_rank=0;
//     int wc, wr, Pg, Pn;       //number of '1' in column //number of '1' in row //gross message length //number of parity check symbols //calculate required parameters
//     wc=coderate_params[0];
//     wr=coderate_params[1];
//     Pn=data->length;
//     if(wr > 0)
//     {
//         Pg=ceil((Pn*wr)/(jab_float)(wr-wc));
//         Pg = wr * (ceil(Pg / (jab_float)wr));
//     }
//     else
//         Pg=Pn*2;
//
// #if TEST_MODE
// 	JAB_REPORT_INFO(("wc: %d, wr: %d\tPg: %d, Pn: %d", wc, wr, Pg, Pn))
// #endif // TEST_MODE
//
//     //in order to speed up the ldpc encoding, sub blocks are established
//     int nb_sub_blocks=0;
//     for(int i=1;i<10000;i++)
//     {
//         if(Pg / i < 2700)
//         {
//             nb_sub_blocks=i;
//             break;
//         }
//     }
//     int Pg_sub_block=0;
//     int Pn_sub_block=0;
//     if(wr > 0)
//     {
//         Pg_sub_block=((Pg / nb_sub_blocks) / wr) * wr;
//         Pn_sub_block=Pg_sub_block * (wr-wc) / wr;
//     }
//     else
//     {
//         Pg_sub_block=Pg;
//         Pn_sub_block=Pn;
//     }
//     int encoding_iterations=nb_sub_blocks=Pg / Pg_sub_block;//nb_sub_blocks;
//     if(Pn_sub_block * nb_sub_blocks < Pn)
//         encoding_iterations--;
//     int* matrixA;
//     //Matrix A
//     if(wr > 0)
//         matrixA = createMatrixA(wc, wr, Pg_sub_block);
//     else
//         matrixA = createMetadataMatrixA(wc, Pg_sub_block);
//     if(matrixA == null)
//     {
//         reportError("Generator matrix could not be created in LDPC encoder.");
//         return null;
//     }
//     jab_boolean encode=1;
//     if(GaussJordan(matrixA, wc, wr, Pg_sub_block, &matrix_rank,encode))
//     {
//         reportError("Gauss Jordan Elimination in LDPC encoder failed.");
//         free(matrixA);
//         return null;
//     }
//     //Generator Matrix
//     int* G = createGeneratorMatrix(matrixA, Pg_sub_block, Pg_sub_block - matrix_rank);
//     if(G == null)
//     {
//         reportError("Generator matrix could not be created in LDPC encoder.");
//         free(matrixA);
//         return null;
//     }
//     free(matrixA);
//
//     jab_data* ecc_encoded_data = (jab_data *)malloc(sizeof(jab_data) + Pg*sizeof(jab_char));
//     if(ecc_encoded_data == null)
//     {
//         reportError("Memory allocation for LDPC encoded data failed");
//         free(G);
//         return null;
//     }
//
//     ecc_encoded_data->length = Pg;
//     int temp,loop;
//     int offset=ceil((Pg_sub_block - matrix_rank)/(jab_float)32);
//     //G * message = ecc_encoded_Data
//     for(int iter=0; iter < encoding_iterations; iter++)
//     {
//         for (int i=0;i<Pg_sub_block;i++)
//         {
//             temp=0;
//             loop=0;
//             int offset_index=offset*i;
//             for (int j=iter*Pn_sub_block; j < (iter+1)*Pn_sub_block; j++)
//             {
//                 temp ^= (((G[offset_index + loop/32] >> (31-loop%32)) & 1) & ((data->data[j] >> 0) & 1)) << 0;
//                 loop++;
//             }
//             ecc_encoded_data->data[i+iter*Pg_sub_block]=(jab_char) ((temp >> 0) & 1);
//         }
//     }
//     free(G);
//     if(encoding_iterations != nb_sub_blocks)
//     {
//         int start=encoding_iterations*Pn_sub_block;
//         int last_index=encoding_iterations*Pg_sub_block;
//         matrix_rank=0;
//         Pg_sub_block=Pg - encoding_iterations * Pg_sub_block;
//         Pn_sub_block=Pg_sub_block * (wr-wc) / wr;
//         int* matrixA = createMatrixA(wc, wr, Pg_sub_block);
//         if(matrixA == null)
//         {
//             reportError("Generator matrix could not be created in LDPC encoder.");
//             return null;
//         }
//         if(GaussJordan(matrixA, wc, wr, Pg_sub_block, &matrix_rank,encode))
//         {
//             reportError("Gauss Jordan Elimination in LDPC encoder failed.");
//             free(matrixA);
//             return null;
//         }
//         int* G = createGeneratorMatrix(matrixA, Pg_sub_block, Pg_sub_block - matrix_rank);
//         if(G == null)
//         {
//             reportError("Generator matrix could not be created in LDPC encoder.");
//             free(matrixA);
//             return null;
//         }
//         free(matrixA);
//         offset=ceil((Pg_sub_block - matrix_rank)/(jab_float)32);
//         for (int i=0;i<Pg_sub_block;i++)
//         {
//             temp=0;
//             loop=0;
//             int offset_index=offset*i;
//             for (int j=start; j < data->length; j++)
//             {
//                 temp ^= (((G[offset_index + loop/32] >> (31-loop%32)) & 1) & ((data->data[j] >> 0) & 1)) << 0;
//                 loop++;
//             }
//             ecc_encoded_data->data[i+last_index]=(jab_char) ((temp >> 0) & 1);
//         }
//         free(G);
//     }
//     return ecc_encoded_data;
// }
//
// /**
//  * @brief Iterative hard decision error correction decoder
//  * @param data the received data
//  * @param matrix the parity check matrix
//  * @param length the encoded data length
//  * @param height the number of check bits
//  * @param max_iter the maximal number of iterations
//  * @param is_correct indicating if decodedMessage function could correct all errors
//  * @param start_pos indicating the position to start reading in data array
//  * @return 1: error correction succeeded | 0: fatal error (out of memory)
// */
// int decodeMessage(jab_byte* data, int* matrix, int length, int height, int max_iter, jab_boolean *is_correct, int start_pos)
// {
//     int* max_val=(int *)calloc(length, sizeof(int));
//     if(max_val == null)
//     {
//         reportError("Memory allocation for LDPC decoder failed");
//
//         return 0;
//     }
//     int* equal_max=(int *)calloc(length, sizeof(int));
//     if(equal_max == null)
//     {
//         reportError("Memory allocation for LDPC decoder failed");
//         free(max_val);
//         return 0;
//     }
//     int* prev_index=(int *)calloc(length, sizeof(int));
//     if(prev_index == null)
//     {
//         reportError("Memory allocation for LDPC decoder failed");
//         free(max_val);
//         free(equal_max);
//         return 0;
//     }
//
//     *is_correct=(jab_boolean)1;
//     int check=0;
//     int counter=0, prev_count=0;
//     int max=0;
//     int offset=ceil(length/(jab_float)32);
//
//     for (int kl=0;kl<max_iter;kl++)
//     {
//         max=0;
//         for(int j=0;j<height;j++)
//         {
//             check=0;
//             for (int i=0;i<length;i++)
//             {
//                 if(((matrix[j*offset+i/32] >> (31-i%32)) & 1) & ((data[start_pos+i] >> 0) & 1))
//                     check+=1;
//             }
//             check=check%2;
//             if(check)
//             {
//                 for(int k=0;k<length;k++)
//                 {
//                     if(((matrix[j*offset+k/32] >> (31-k%32)) & 1))
//                         max_val[k]++;
//                 }
//             }
//         }
//         //find maximal values in max_val
//         jab_boolean is_used=0;
//         for (int j=0;j<length;j++)
//         {
//             is_used=(jab_boolean)0;
//             for(int i=0;i< prev_count;i++)
//             {
//                 if(prev_index[i]==j)
//                     is_used=(jab_boolean)1;
//             }
//             if(max_val[j]>=max && !is_used)
//             {
//                 if(max_val[j]!=max)
//                     counter=0;
//                 max=max_val[j];
//                 equal_max[counter]=j;
//                 counter++;
//             }
//             max_val[j]=0;
//         }
//         //flip bits
//         if(max>0)
//         {
//             *is_correct=(jab_boolean) 0;
//             if(length < 36)
//             {
//                 int rand_tmp=(int)(rand()/(jab_float)UINT32_MAX * counter);
//                 prev_index[0]=start_pos+equal_max[rand_tmp];
//                 data[start_pos+equal_max[rand_tmp]]=(data[start_pos+equal_max[rand_tmp]]+1)%2;
//             }
//             else
//             {
//                 for(int j=0; j< counter;j++)
//                 {
//                     prev_index[j]=start_pos+equal_max[j];
//                     data[start_pos+equal_max[j]]=(data[start_pos+equal_max[j]]+1)%2;
//                 }
//             }
//             prev_count=counter;
//             counter=0;
//         }
//         else
//             *is_correct=(jab_boolean) 1;
//
//         if(*is_correct == 0 && kl+1 < max_iter)
//             *is_correct=(jab_boolean)1;
//         else
//             break;
//     }
// #if TEST_MODE
//     JAB_REPORT_INFO(("start position:%d, stop position:%d, correct:%d", start_pos, start_pos+length,(int)*is_correct))
// #endif
//     free(prev_index);
//     free(equal_max);
//     free(max_val);
//     return 1;
// }

/**
 * @brief LDPC decoding to perform hard decision
 * @param data the encoded data
 * @param length the encoded data length
 * @param wc the number of '1's in a column
 * @param wr the number of '1's in a row
 * @return the decoded data length | 0: fatal error (out of memory)
*/
int decodeLDPChd(Uint8List data, int length, int wc, int wr)
{
    int matrix_rank=0;
    int max_iter=25;
    int Pn; 
        int Pg;
    int decoded_data_len = 0;
    if(wr > 3)
    {
        Pg = (wr * (length / wr)).toInt();
        Pn = (Pg * (wr - wc) / wr).toInt();                //number of source symbols
    }
    else
    {
        Pg=length;
        Pn=(length/2).toInt();
        wc=2;
        if(Pn>36)
            wc=3;
    }
    decoded_data_len=Pn;

    //in order to speed up the ldpc encoding, sub blocks are established
    int nb_sub_blocks=0;
    for(int i=1;i<10000;i++)
    {
        if(Pg / i < 2700)
        {
            nb_sub_blocks=i;
            break;
        }
    }
    int Pg_sub_block=0;
    int Pn_sub_block=0;
    if(wr > 3)
    {
        Pg_sub_block=(((Pg / nb_sub_blocks) / wr) * wr).toInt();
        Pn_sub_block=(Pg_sub_block * (wr-wc) / wr).toInt();
    }
    else
    {
        Pg_sub_block=Pg;
        Pn_sub_block=Pn;
    }
    int decoding_iterations=nb_sub_blocks=(Pg / Pg_sub_block).toInt();//nb_sub_blocks;
    if(Pn_sub_block * nb_sub_blocks < Pn)
        decoding_iterations--;

    //parity check matrix
    List<int> matrixA;
    if(wr > 0)
        matrixA = createMatrixA(wc, wr,Pg_sub_block);
    else
        matrixA = createMetadataMatrixA(wc, Pg_sub_block);
    if(matrixA == null)
    {
        // reportError("LDPC matrix could not be created in decoder.");
        return 0;
    }
    bool encode=false;
    if(GaussJordan(matrixA, wc, wr, Pg_sub_block,encode) != 0) // &matrix_rank,encode
    {
        // reportError("Gauss Jordan Elimination in LDPC encoder failed.");
        // free(matrixA);
        return 0;
    }

    int old_Pg_sub=Pg_sub_block;
    int old_Pn_sub=Pn_sub_block;
    for (int iter = 0; iter < nb_sub_blocks; iter++)
    {
        if(decoding_iterations != nb_sub_blocks && iter == decoding_iterations)
        {
            matrix_rank=0;
            Pg_sub_block=Pg - decoding_iterations * Pg_sub_block;
            Pn_sub_block=(Pg_sub_block * (wr-wc) / wr).toInt();
            var matrixA1 = createMatrixA(wc, wr, Pg_sub_block);
            if(matrixA1 == null)
            {
                // reportError("LDPC matrix could not be created in decoder.");
                return 0;
            }
            bool encode=false;
            if(GaussJordan(matrixA1, wc, wr, Pg_sub_block, encode)!= 0) //, &matrix_rank,encode
            {
                // reportError("Gauss Jordan Elimination in LDPC encoder failed.");
                // free(matrixA1);
                return 0;
            }
            //ldpc decoding
            //first check syndrom
            bool is_correct=true;
            int offset=(Pg_sub_block/32.0).ceil();
            for (int i=0;i< matrix_rank; i++)
            {
                int temp=0;
                for (int j=0;j<Pg_sub_block;j++)
                    temp ^= (((matrixA1[(i*offset+j/32).toInt()] >> (31-j%32)) & 1) & ((data[iter*old_Pg_sub+j] >> 0) & 1)) << 0; //
                if (temp != 0)
                {
                    is_correct=false;//message not correct
                    break;
                }
            }

            if(is_correct==0)
            {
                int start_pos=iter*old_Pg_sub;
                int success=decodeMessage(data, matrixA1, Pg_sub_block, matrix_rank, max_iter, &is_correct,start_pos);
                if(success == 0)
                {
                    // reportError("LDPC decoder error.");
                    // free(matrixA1);
                    return 0;
                }
            }
            if(is_correct==0)
            {
                bool is_correct=true;
                for (int i=0;i< matrix_rank; i++)
                {
                    int temp=0;
                    for (int j=0;j<Pg_sub_block;j++)
                        temp ^= (((matrixA1[(i*offset+j/32).toInt()] >> (31-j%32)) & 1) & ((data[iter*old_Pg_sub+j] >> 0) & 1)) << 0;
                    if (temp != 0)
                    {
                        is_correct=false;//message not correct
                        break;
                    }
                }
                if(is_correct==0)
                {
                    // reportError("Too many errors in message. LDPC decoding failed.");
                    // free(matrixA1);
                    return 0;
                }
            }
            // free(matrixA1);
        }
        else
        {
            //ldpc decoding
            //first check syndrom
            bool is_correct=true;
            int offset=(Pg_sub_block/32.0).ceil();
            for (int i=0;i< matrix_rank; i++)
            {
                int temp=0;
                for (int j=0;j<Pg_sub_block;j++)
                    temp ^= (((matrixA[(i*offset+j/32).toInt()] >> (31-j%32)) & 1) & ((data[iter*old_Pg_sub+j] >> 0) & 1)) << 0;
                if (temp != 0)
                {
                    is_correct=false;//message not correct
                    break;
                }
            }

            if(is_correct==0)
            {
                int start_pos=iter*old_Pg_sub;
                int success=decodeMessage(data, matrixA, Pg_sub_block, matrix_rank, max_iter, &is_correct, start_pos);
                if(success == 0)
                {
                    // reportError("LDPC decoder error.");
                    // free(matrixA);
                    return 0;
                }
                is_correct=1;
                for (int i=0;i< matrix_rank; i++)
                {
                    int temp=0;
                    for (int j=0;j<Pg_sub_block;j++)
                        temp ^= (((matrixA[(i*offset+j/32).toInt()] >> (31-j%32)) & 1) & ((data[iter*old_Pg_sub+j] >> 0) & 1)) << 0;
                    if (temp != 0)
                    {
                        is_correct=false;//message not correct
                        break;
                    }
                }
                if(is_correct==0)
                {
                    // reportError("Too many errors in message. LDPC decoding failed.");
                    // free(matrixA);
                    return 0;
                }
            }
        }
        int loop=0;
        for (int i=iter*old_Pg_sub;i < iter * old_Pg_sub + Pn_sub_block; i++)
        {
            data[iter*old_Pn_sub+loop]=data[i+ matrix_rank];
            loop++;
        }
    }
    // free(matrixA);
    return decoded_data_len;
}

// /**
//  * @brief LDPC Iterative Log Likelihood decoding algorithm for binary codes
//  * @param enc the received reliability value for each bit
//  * @param matrix the error correction decoding matrix
//  * @param length the encoded data length
//  * @param checkbits the rank of the matrix
//  * @param height the number of check bits
//  * @param max_iter the maximal number of iterations
//  * @param is_correct indicating if decodedMessage function could correct all errors
//  * @param start_pos indicating the position to start reading in enc array
//  * @param dec is the tentative decision after each decoding iteration
//  * @return 1: success | 0: fatal error (out of memory)
// */
// int decodeMessageILL(jab_float* enc, int* matrix, int length, int checkbits, int height, int max_iter, jab_boolean *is_correct, int start_pos, jab_byte* dec)
// {
//     jab_double* lambda=(jab_double *)malloc(length * sizeof(jab_double));
//     if(lambda == null)
//     {
//         reportError("Memory allocation for Lambda in LDPC decoder failed");
//         return 0;
//     }
//     jab_double* old_nu_row=(jab_double *)malloc(length * sizeof(jab_double));
//     if(old_nu_row == null)
//     {
//         reportError("Memory allocation for Lambda in LDPC decoder failed");
//         free(lambda);
//         return 0;
//     }
//     jab_double* nu=(jab_double *)malloc(length*height * sizeof(jab_double));
//     if(nu == null)
//     {
//         reportError("Memory allocation for nu in LDPC decoder failed");
//         free(old_nu_row);
//         free(lambda);
//         return 0;
//     }
//     memset(nu,0,length*height *sizeof(jab_double));
//     int* index=(int *)malloc(length * sizeof(int));
//     if(index == null)
//     {
//         reportError("Memory allocation for index in LDPC decoder failed");
//         free(old_nu_row);
//         free(lambda);
//         free(nu);
//         return 0;
//     }
//     int offset=ceil(length/(jab_float)32);
//     jab_double product=1.0;
//
//     //set last bits
//     for (int i=length-1;i >= length-(height-checkbits);i--)
//     {
//         enc[start_pos+i]=1.0;
//         dec[start_pos+i]=0;
//     }
//     jab_double meansum=0.0;
//     for (int i=0;i<length;i++)
//         meansum+=enc[start_pos+i];
//
//     //calc variance
//     meansum/=length;
//     jab_double var=0.0;
//     for (int i=0;i<length;i++)
//         var+=(enc[start_pos+i]-meansum)*(enc[start_pos+i]-meansum);
//     var/=(length-1);
//
//     //initialize lambda
//     for (int i=0;i<length;i++)
//     {
//         if(dec[start_pos+i])
//             enc[start_pos+i]=-enc[start_pos+i];
//         lambda[i]=(jab_double)2.0*enc[start_pos+i]/var;
//     }
//
//     //check node update
//     int count;
//     for (int kl=0;kl<max_iter;kl++)
//     {
//         for(int j=0;j<height;j++)
//         {
//             product=1.0;
//             count=0;
//             for (int i=0;i<length;i++)
//             {
//                 if((matrix[j*offset+i/32] >> (31-i%32)) & 1)
//                 {
//                     product*=tanh(-(lambda[i]-nu[j*length+i])*0.5);
//                     index[count]=i;
//                     ++count;
//                 }
//                 old_nu_row[i]=nu[j*length+i];
//             }
//             //update nu
//             for (int i=0;i<count;i++)
//             {
//                 if(((matrix[j*offset+index[i]/32] >> (31-index[i]%32)) & 1) && tanh(-(lambda[index[i]]-old_nu_row[index[i]])*0.5) != 0.0)
//                     nu[j*length+index[i]]=-2*atanh(product/tanh(-(lambda[index[i]]-old_nu_row[index[i]])*0.5));
//                 else
//                     nu[j*length+index[i]]=-2*atanh(product);
//             }
//         }
//         //update lambda
//         jab_double sum;
//         for (int i=0;i<length;i++)
//         {
//             sum=0.0;
//             for(int k=0;k<height;k++)
//                 sum+=nu[k*length+i];
//             lambda[i]=(jab_double)2.0*enc[start_pos+i]/var+sum;
//             if(lambda[i]<0)
//                 dec[start_pos+i]=1;
//             else
//                 dec[start_pos+i]=0;
//         }
//         //check matrix times dec
//         *is_correct=(jab_boolean) 1;
//         for (int i=0;i< height; i++)
//         {
//             int temp=0;
//             for (int j=0;j<length;j++)
//                 temp ^= (((matrix[i*offset+j/32] >> (31-j%32)) & 1) & ((dec[start_pos+j] >> 0) & 1)) << 0;
//             if (temp)
//             {
//                 *is_correct=(jab_boolean) 0;
//                 break;//message not correct
//             }
//         }
//         if(!*is_correct && kl<max_iter-1)
//             *is_correct=(jab_boolean) 1;
//         else
//             break;
//     }
// #if TEST_MODE
//     JAB_REPORT_INFO(("start position:%d, stop position:%d, correct:%d", start_pos, start_pos+length,(int)*is_correct))
// #endif
//     free(lambda);
//     free(nu);
//     free(old_nu_row);
//     free(index);
//     return 1;
// }
//
//
// /**
//  * @brief LDPC Iterative belief propagation decoding algorithm for binary codes
//  * @param enc the received reliability value for each bit
//  * @param matrix the decoding matrixreliability value for each bit
//  * @param length the encoded data length
//  * @param checkbits the rank of the matrix
//  * @param height the number of check bits
//  * @param max_iter the maximal number of iterations
//  * @param is_correct indicating if decodedMessage function could correct all errors
//  * @param start_pos indicating the position to start reading in enc array
//  * @param dec is the tentative decision after each decoding iteration
//  * @return 1: error correction succeded | 0: decoding failed
// */
// int decodeMessageBP(jab_float* enc, int* matrix, int length, int checkbits, int height, int max_iter, jab_boolean *is_correct, int start_pos, jab_byte* dec)
// {
//     jab_double* lambda=(jab_double *)malloc(length * sizeof(jab_double));
//     if(lambda == null)
//     {
//         reportError("Memory allocation for Lambda in LDPC decoder failed");
//         return 0;
//     }
//     jab_double* old_nu_row=(jab_double *)malloc(length * sizeof(jab_double));
//     if(old_nu_row == null)
//     {
//         reportError("Memory allocation for Lambda in LDPC decoder failed");
//         free(lambda);
//         return 0;
//     }
//     jab_double* nu=(jab_double *)malloc(length*height * sizeof(jab_double));
//     if(nu == null)
//     {
//         reportError("Memory allocation for nu in LDPC decoder failed");
//         free(old_nu_row);
//         free(lambda);
//         return 0;
//     }
//     memset(nu,0,length*height *sizeof(jab_double));
//     int* index=(int *)malloc(length * sizeof(int));
//     if(index == null)
//     {
//         reportError("Memory allocation for index in LDPC decoder failed");
//         free(old_nu_row);
//         free(lambda);
//         free(nu);
//         return 0;
//     }
//     int offset=ceil(length/(jab_float)32);
//     jab_double product=1.0;
//
//     //set last bits
//     for (int i=length-1;i >= length-(height-checkbits);i--)
//     {
//         enc[start_pos+i]=1.0;
//         dec[start_pos+i]=0;
//     }
//
//     jab_double meansum=0.0;
//     for (int i=0;i<length;i++)
//         meansum+=enc[start_pos+i];
//
//     //calc variance
//     meansum/=length;
//     jab_double var=0.0;
//     for (int i=0;i<length;i++)
//         var+=(enc[start_pos+i]-meansum)*(enc[start_pos+i]-meansum);
//     var/=(length-1);
//
//     //initialize lambda
//     for (int i=0;i<length;i++)
//     {
//         if(dec[start_pos+i])
//             enc[start_pos+i]=-enc[start_pos+i];
//         lambda[i]=(jab_double)2.0*enc[start_pos+i]/var;
//     }
//
//     //check node update
//     int count;
//     for (int kl=0;kl<max_iter;kl++)
//     {
//         for(int j=0;j<height;j++)
//         {
//             product=1.0;
//             count=0;
//             for (int i=0;i<length;i++)
//             {
//                 if((matrix[j*offset+i/32] >> (31-i%32)) & 1)
//                 {
//                     if (kl==0)
//                         product*=tanh(lambda[i]*0.5);
//                     else
//                         product*=tanh(nu[j*length+i]*0.5);
//                     index[count]=i;
//                     ++count;
//                 }
//             }
//             //update nu
//             jab_double num=0.0, denum=0.0;
//             for (int i=0;i<count;i++)
//             {
//                 if(((matrix[j*offset+index[i]/32] >> (31-index[i]%32)) & 1) && tanh(nu[j*length+index[i]]*0.5) != 0.0 && kl>0)// && tanh(-(lambda[index[i]]-old_nu_row[index[i]])/2) != 0.0)
//                 {
//                     num     = 1 + product / tanh(nu[j*length+index[i]]*0.5);
//                     denum   = 1 - product / tanh(nu[j*length+index[i]]*0.5);
//                 }
//                 else if(((matrix[j*offset+index[i]/32] >> (31-index[i]%32)) & 1) && tanh(lambda[index[i]]*0.5) != 0.0 && kl==0)// && tanh(-(lambda[index[i]]-old_nu_row[index[i]])/2) != 0.0)
//                 {
//                     num     = 1 + product / tanh(lambda[index[i]]*0.5);
//                     denum   = 1 - product / tanh(lambda[index[i]]*0.5);
//                 }
//                 else
//                 {
//                     num     = 1 + product;
//                     denum   = 1 - product;
//                 }
//                 if (num == 0.0)
//                     nu[j*length+index[i]]=-1;
//                 else if(denum == 0.0)
//                     nu[j*length+index[i]]= 1;
//                 else
//                     nu[j*length+index[i]]= log(num / denum);
//             }
//         }
//         //update lambda
//         jab_double sum;
//         for (int i=0;i<length;i++)
//         {
//             sum=0.0;
//             for(int k=0;k<height;k++)
//             {
//                 sum+=nu[k*length+i];
//                 old_nu_row[k]=nu[k*length+i];
//             }
//             for(int k=0;k<height;k++)
//             {
//                 if((matrix[k*offset+i/32] >> (31-i%32)) & 1)
//                     nu[k*length+i]=lambda[i]+(sum-old_nu_row[k]);
//             }
//             lambda[i]=2.0*enc[start_pos+i]/var+sum;
//             if(lambda[i]<0)
//                 dec[start_pos+i]=1;
//             else
//                 dec[start_pos+i]=0;
//         }
//         //check matrix times dec
//         *is_correct=(jab_boolean) 1;
//         for (int i=0;i< height; i++)
//         {
//             int temp=0;
//             for (int j=0;j<length;j++)
//                 temp ^= (((matrix[i*offset+j/32] >> (31-j%32)) & 1) & ((dec[start_pos+j] >> 0) & 1)) << 0;
//             if (temp)
//             {
//                 *is_correct=(jab_boolean) 0;
//                 break;//message not correct
//             }
//         }
//         if(!*is_correct && kl<max_iter-1)
//             *is_correct=(jab_boolean) 1;
//         else
//             break;
//     }
// #if TEST_MODE
//     JAB_REPORT_INFO(("start position:%d, stop position:%d, correct:%d", start_pos, start_pos+length,(int)*is_correct))
// #endif
//     free(lambda);
//     free(nu);
//     free(old_nu_row);
//     free(index);
//     return 1;
// }
//
// /**
//  * @brief LDPC decoding to perform soft decision
//  * @param enc the probability value for each bit position
//  * @param length the encoded data length
//  * @param wc the number of '1's in each column
//  * @param wr the number of '1's in each row
//  * @param dec the decoded data
//  * @return the decoded data length | 0: decoding error
// */
// int decodeLDPC(jab_float* enc, int length, int wc, int wr, jab_byte* dec)
// {
//     int matrix_rank=0;
//     int max_iter=25;
//     int Pn, Pg, decoded_data_len = 0;
//     if(wr > 3)
//     {
//         Pg = wr * (length / wr);
//         Pn = Pg * (wr - wc) / wr; //number of source symbols
//     }
//     else
//     {
//         Pg=length;
//         Pn=length/2;
//         wc=2;
//         if(Pn>36)
//             wc=3;
//     }
//     decoded_data_len=Pn;
//
//     //in order to speed up the ldpc encoding, sub blocks are established
//     int nb_sub_blocks=0;
//     for(int i=1;i<10000;i++)
//     {
//         if(Pg / i < 2700)
//         {
//             nb_sub_blocks=i;
//             break;
//         }
//     }
//     int Pg_sub_block=0;
//     int Pn_sub_block=0;
//     if(wr > 3)
//     {
//         Pg_sub_block=((Pg / nb_sub_blocks) / wr) * wr;
//         Pn_sub_block=Pg_sub_block * (wr-wc) / wr;
//     }
//     else
//     {
//         Pg_sub_block=Pg;
//         Pn_sub_block=Pn;
//     }
//     int decoding_iterations=nb_sub_blocks=Pg / Pg_sub_block;//nb_sub_blocks;
//     if(Pn_sub_block * nb_sub_blocks < Pn)
//         decoding_iterations--;
//
//     //parity check matrix
//     int* matrixA;
//     if(wr > 0)
//         matrixA = createMatrixA(wc, wr,Pg_sub_block);
//     else
//         matrixA = createMetadataMatrixA(wc, Pg_sub_block);
//     if(matrixA == null)
//     {
//         reportError("LDPC matrix could not be created in decoder.");
//         return 0;
//     }
//
//     jab_boolean encode=0;
//     if(GaussJordan(matrixA, wc, wr, Pg_sub_block, &matrix_rank,encode))
//     {
//         reportError("Gauss Jordan Elimination in LDPC encoder failed.");
//         free(matrixA);
//         return 0;
//     }
// #if TEST_MODE
// 	//JAB_REPORT_INFO(("GaussJordan matrix done"))
// #endif
//     int old_Pg_sub=Pg_sub_block;
//     int old_Pn_sub=Pn_sub_block;
//     for (int iter = 0; iter < nb_sub_blocks; iter++)
//     {
//         if(decoding_iterations != nb_sub_blocks && iter == decoding_iterations)
//         {
//             matrix_rank=0;
//             Pg_sub_block=Pg - decoding_iterations * Pg_sub_block;
//             Pn_sub_block=Pg_sub_block * (wr-wc) / wr;
//             int* matrixA1 = createMatrixA(wc, wr, Pg_sub_block);
//             if(matrixA1 == null)
//             {
//                 reportError("LDPC matrix could not be created in decoder.");
//                 return 0;
//             }
//             jab_boolean encode=0;
//             if(GaussJordan(matrixA1, wc, wr, Pg_sub_block, &matrix_rank,encode))
//             {
//                 reportError("Gauss Jordan Elimination in LDPC encoder failed.");
//                 free(matrixA1);
//                 return 0;
//             }
//             //ldpc decoding
//             //first check syndrom
//             jab_boolean is_correct=1;
//             int offset=ceil(Pg_sub_block/(jab_float)32);
//             for (int i=0;i< matrix_rank; i++)
//             {
//                 int temp=0;
//                 for (int j=0;j<Pg_sub_block;j++)
//                     temp ^= (((matrixA1[i*offset+j/32] >> (31-j%32)) & 1) & ((dec[iter*old_Pg_sub+j] >> 0) & 1)) << 0; //
//                 if (temp)
//                 {
//                     is_correct=(jab_boolean) 0; //message not correct
//                     break;
//                 }
//             }
//
//             if(is_correct==0)
//             {
//                 int start_pos=iter*old_Pg_sub;
//                 int success=decodeMessageBP(enc, matrixA1, Pg_sub_block, matrix_rank, wr<4 ? Pg_sub_block/2 : Pg_sub_block/wr*wc, max_iter, &is_correct,start_pos,dec);
//                 if(success == 0)
//                 {
//                     reportError("LDPC decoder error.");
//                     free(matrixA1);
//                     return 0;
//                 }
//             }
//             if(is_correct==0)
//             {
//                 jab_boolean is_correct=1;
//                 for (int i=0;i< matrix_rank; i++)
//                 {
//                     int temp=0;
//                     for (int j=0;j<Pg_sub_block;j++)
//                         temp ^= (((matrixA1[i*offset+j/32] >> (31-j%32)) & 1) & ((dec[iter*old_Pg_sub+j] >> 0) & 1)) << 0;
//                     if (temp)
//                     {
//                         is_correct=(jab_boolean) 0;//message not correct
//                         break;
//                     }
//                 }
//                 if(is_correct==0)
//                 {
//  //                   reportError("Too many errors in message. LDPC decoding failed.");
//                     free(matrixA1);
//                     return 0;
//                 }
//             }
//             free(matrixA1);
//         }
//         else
//         {
//             //ldpc decoding
//             //first check syndrom
//             jab_boolean is_correct=1;
//             int offset=ceil(Pg_sub_block/(jab_float)32);
//             for (int i=0;i< matrix_rank; i++)
//             {
//                 int temp=0;
//                 for (int j=0;j<Pg_sub_block;j++)
//                     temp ^= (((matrixA[i*offset+j/32] >> (31-j%32)) & 1) & ((dec[iter*old_Pg_sub+j] >> 0) & 1)) << 0;
//                 if (temp)
//                 {
//                     is_correct=(jab_boolean) 0;//message not correct
//                     break;
//                 }
//             }
//
//             if(is_correct==0)
//             {
//                 int start_pos=iter*old_Pg_sub;
//                 int success=decodeMessageBP(enc, matrixA, Pg_sub_block, matrix_rank, wr<4 ? Pg_sub_block/2 : Pg_sub_block/wr*wc, max_iter, &is_correct, start_pos,dec);
//                 if(success == 0)
//                 {
//                     reportError("LDPC decoder error.");
//                     free(matrixA);
//                     return 0;
//                 }
//                 is_correct=1;
//                 for (int i=0;i< matrix_rank; i++)
//                 {
//                     int temp=0;
//                     for (int j=0;j<Pg_sub_block;j++)
//                         temp ^= (((matrixA[i*offset+j/32] >> (31-j%32)) & 1) & ((dec[iter*old_Pg_sub+j] >> 0) & 1)) << 0;
//                     if (temp)
//                     {
//                         is_correct=(jab_boolean)0;//message not correct
//                         break;
//                     }
//                 }
//                 if(is_correct==0)
//                 {
//        //             reportError("Too many errors in message. LDPC decoding failed.");
//                     free(matrixA);
//                     return 0;
//                 }
//             }
//         }
//
//         int loop=0;
//         for (int i=iter*old_Pg_sub;i < iter * old_Pg_sub + Pn_sub_block; i++)
//         {
//             dec[iter*old_Pn_sub+loop]=dec[i+ matrix_rank];
//             loop++;
//         }
//     }
//     free(matrixA);
//     return decoded_data_len;
// }
