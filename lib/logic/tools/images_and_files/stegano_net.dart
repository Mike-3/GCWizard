// // source: https://github.com/kernelENREK/SteganoNET
//
//
// import 'dart:typed_data';
// import 'package:image/image.dart' as Image;
// import 'package:gc_wizard/widgets/utils/gcw_file.dart';
//
// /// Header for hiding a text
// const String HEADER_SECRET_TEXT = "0x29a";
//
// /// Header for attach a file of any type
// const String HEADER_SECRET_FILE = "0x666";
//
// /// Split character for header
// const String HEADER_SPLIT_DATA = Strings.Chr(28);
//
// /// <summary>
// ///  Function for decode steganography from image
// /// <param name="sourceFile">image source file. The image should be png, jpg and bmp format. Can be any bpp</param>
// /// <param name="steganoInfo">Information decoded from the sourceFile</param>
// /// <param name="bytesAttach">Byte for file to hide in the sourceFile. This file can be any file type</param>
// /// <returns></returns>
// bool GetStegano(GCWFile sourceFile, SteganoInfo steganoInfo, Uint8List bytesAttach) {
//   var bmpData = Image.decodeImage(sourceFile.bytes);
//
//   int bmpTotalBytes = bmpData.width * bmpData.height;
//   var bmpBytes =  Uint8List(bmpTotalBytes - 1 + 1);
//
//
//
//   String binaryString = "";
//   String octetString = "";
//   int state = 0;
//   String header = "";
//   String strTotalAttachedBytes = "";
//   int totalAttachedBytes = 0;
//
//   ArrayList attachedBytes = null/* TODO Change to default(_) if this is not a reference type */;
//
//   if (steganoInfo = null)
//   steganoInfo = new SteganoInfo();
//
//   for (int i = 0; i <= bmpBytes.Length - 1; i++) {
//     binaryString = Convert.ToString(bmpBytes[i], 2);
//     octetString += binaryString.Substring(binaryString.Length - 1, 1);
//
//     if ((octetString.length == 8)) {
//       switch (state) {
//         case 0:
//           header += Strings.Chr(Convert.ToInt32(octetString, 2));
//           if ((header.length == HEADER_SECRET_TEXT.Length)) {
//             if ((header == HEADER_SECRET_TEXT)) {
//               steganoInfo.SecretText = "";
//               state = 1;
//             } else
//               state = 2;
//             header = "";
//           }
//           break;
//
//         case 1: // decode text
//           int ascii = Convert.ToInt32(octetString, 2);
//           if ((ascii == Asc(HEADER_SPLIT_DATA)))
//             state = 2;
//           else
//             steganoInfo.SecretText += Strings.Chr(ascii);
//           break;
//
//         case 2: // check for attached file
//           header += Strings.Chr(Convert.ToInt32(octetString, 2));
//           if ((header.length == HEADER_SECRET_TEXT.length)) {
//             if ((header == HEADER_SECRET_FILE)) {
//               steganoInfo.SecretFile = "";
//               state = 3; // get filename for attached file
//             } else
//               break;
//             header = "";
//           }
//           break;
//
//         case 3: // get filename for attached file
//           int ascii = Convert.ToInt32(octetString, 2);
//           if ((ascii == Asc(HEADER_SPLIT_DATA)))
//             state = 4; // get total bytes for attached file
//           else
//             steganoInfo.SecretFile += Strings.Chr(ascii);
//           break;
//
//
//         case 4: // get total bytes attached file
//           int ascii = Convert.ToInt32(octetString, 2);
//           if ((ascii == Asc(HEADER_SPLIT_DATA))) {
//             totalAttachedBytes = Convert.ToInt32(strTotalAttachedBytes);
//             attachedBytes = new ArrayList();
//             state = 5; // get bytes for attached file
//           }
//           else
//             strTotalAttachedBytes += Strings.Chr(ascii);
//           break;
//
//         case 5: // get bytes
//           attachedBytes.Add(Convert.ToByte(octetString, 2));
//           if ((attachedBytes.Count == totalAttachedBytes)) {
//             bytesAttach = (byte[])attachedBytes.ToArray(typeof(byte));
//             break;
//           }
//           break;
//
//       }
//
//       octetString = "";
//     }
//   }
//
//   return (!String.IsNullOrEmpty(steganoInfo.SecretText) | !Information.IsNothing(bytesAttach));
// }
//
// class SteganoInfo {
//   String SecretText;
//   String SecretFile;
// }