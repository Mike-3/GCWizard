/*
    while (index < bytes.length) {
      print('index $index');
      result.add(SoundfileDataSectionContent(
          Meaning: 'frame',
          Bytes: bytes.sublist(index, index + 4).join(' '),
          Value: String.fromCharCodes(
              bytes.sublist(index, index + 4)))); // 4 Byte ASCII
      print(bytes.sublist(index, index + 4).join(' '));
      print(String.fromCharCodes(bytes.sublist(index, index + 4)));
      frame = String.fromCharCodes(bytes.sublist(index, index + 4));
      result.add(SoundfileDataSectionContent(
          Meaning: '',
          Bytes: ID3_FRAMES[String.fromCharCodes(bytes.sublist(index, index + 4))]
              .toString(),
          Value: '')); // 4 Byte ASCII
      index = index + 4;


      size = sizeID3(bytes.sublist(index, index + 4));
      print('size $size');

      result.add(SoundfileDataSectionContent(
          Meaning: 'size',
          Bytes: bytes.sublist(index, index + 4).join(' '),
          Value: size.toString() + ' Byte')); // 4 Bytes, special Format
      index = index + 4;

      result.add(SoundfileDataSectionContent(
          Meaning: 'flags',
          Bytes: bytes.sublist(index, index + 2).join(' '),
          Value: convertBase(bytes.sublist(index, index + 2).toString(), 10, 2) + convertBase(bytes.sublist(index + 1, index + 2).toString(), 10, 2))); // 2 Bytes, special Format
      index = index + 2;
      print(bytes.sublist(index, index + 2).join(' '));
      print(
          convertBase(bytes.sublist(index, index + 2).toString(), 10, 2) +
              convertBase(bytes.sublist(index + 1, index + 2).toString(), 10, 2)
      );

      if (ID3FrameFlags(bytes.sublist(index + 8, index + 10)) != '') {
        result.add(SoundfileDataSectionContent(
            Meaning: '',
            Bytes: ID3FrameFlags(bytes.sublist(index + 8, index + 10)),
            Value: '')); // 2 Byte ASCII}
        if (ID3_TEXT_FRAMES.contains(frame)) {
          result.add(SoundfileDataSectionContent(
              Meaning: 'encoding',
              Bytes: bytes.sublist(index + 10, index + 11).join(' '),
              Value: ID3TextEncoding[getID3TextEncoding(
                  bytes.sublist(index + 10, index + 11))]!)); // 1 Byte
//      indexText = 0;
//      while (bytes[index + 11 + indexText] != 0 && indexText < size) {
//        frameText = frameText + String.fromCharCode(bytes[indexText == 0 ? 32 : indexText]);
//        indexText++;
//      }
//      result.add(SoundfileDataSectionContent(Meaning: 'data', Bytes: bytes.sublist(index + 11, index + 11 + indexText).join(' '), Value: frameText)); // ? Byte
        } else {}
        result.add(SoundfileDataSectionContent(
            Meaning: 'data',
            Bytes: bytes.sublist(index + 11, index + 11 + size).join(' '),
            Value: String.fromCharCodes(
                bytes.sublist(index + 11, index + 11 + size)))); // 4 Byte
        index = index + 11 + size;
      }
    }
    */
