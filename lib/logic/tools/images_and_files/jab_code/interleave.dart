import 'dart:typed_data';

import 'package:gc_wizard/logic/tools/images_and_files/jab_code/pseudo_random.dart';
import 'package:gc_wizard/logic/tools/images_and_files/jab_code/pseudo_random_h.dart';

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
 * @file interleave.c
 * @brief Data interleaving
 */

// #include <stdlib.h>
// #include <string.h>
// #include "jabcode.h"
// #include "encoder.h"
// #include "pseudo_random.h"

const INTERLEAVE_SEED = 226759;

// /**
//  * @brief In-place interleaving
//  * @param data the input data to be interleaved
// */
// void interleaveData(jab_data data)
// {
//     setSeed(INTERLEAVE_SEED);
//     for (int i=0; i<data.length; i++)
//     {
//         int pos = (lcg64_temper() / UINT32_MAX * (data.length - i) ).toInt();
//         int  tmp = data.data[data.length - 1 -i];
//         data.data[data.length - 1 - i] = data.data[pos];
//         data.data[pos] = tmp;
//     }
// }

/**
 * @brief In-place deinterleaving
 * @param data the input data to be deinterleaved
*/
void deinterleaveData(jab_data data)
{
    var index = List<int>.filled(data.length, 0); //malloc(data.length * sizeof(int));
    if(index == null)
    {
        // reportError("Memory allocation for index buffer in deinterleaver failed");
        return;
    }
    for(int i=0; i<data.length; i++)
    {
		index[i] = i;
    }
    //interleave index
    setSeed(INTERLEAVE_SEED);
    for(int i=0; i<data.length; i++)
    {
		int pos = ( lcg64_temper() / UINT32_MAX * (data.length - i) ).toInt();
		int tmp = index[data.length - 1 - i];
		index[data.length - 1 -i] = index[pos];
		index[pos] = tmp;
    }
    //deinterleave data
    var tmp_data = Int8List(data.length); // (jab_char *)malloc(data.length * sizeof(jab_char));
    if(tmp_data == null)
    {
        // reportError("Memory allocation for temporary buffer in deinterleaver failed");
        return;
    }

    tmp_data.insertAll(0, data.data); //memcpy(tmp_data, data.data, data.length*sizeof(jab_char));
	for(int i=0; i<data.length; i++)
    {
        data.data[index[i]] = tmp_data[i];
    }
    // free(tmp_data);
    // free(index);
}
