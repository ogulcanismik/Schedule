import 'dart:typed_data';

class BitPacking {
  /// Packs a fixed-length list of bits into bytes.
  ///
  /// [bits] must have length [bitCount] and each element must be 0 or 1.
  static Uint8List packBits(List<int> bits, {required int bitCount}) {
    if (bits.length != bitCount) {
      throw ArgumentError(
        'bits.length must equal bitCount (got ${bits.length}, expected $bitCount)',
      );
    }
    final byteLen = (bitCount + 7) ~/ 8;
    final out = Uint8List(byteLen);

    for (var bitIndex = 0; bitIndex < bitCount; bitIndex++) {
      final v = bits[bitIndex];
      if (v != 0 && v != 1) {
        throw ArgumentError('bits[$bitIndex] must be 0 or 1 (got $v)');
      }
      if (v == 1) {
        final byteIndex = bitIndex ~/ 8;
        final bitOffset = bitIndex % 8;
        out[byteIndex] |= (1 << bitOffset);
      }
    }
    return out;
  }

  /// Unpacks bytes into a fixed-length list of bits (0/1).
  static List<int> unpackBits(Uint8List bytes, {required int bitCount}) {
    final expectedByteLen = (bitCount + 7) ~/ 8;
    if (bytes.length != expectedByteLen) {
      throw ArgumentError(
        'bytes.length must equal expectedByteLen (got ${bytes.length}, expected $expectedByteLen)',
      );
    }

    final out = List<int>.filled(bitCount, 0);
    for (var bitIndex = 0; bitIndex < bitCount; bitIndex++) {
      final byteIndex = bitIndex ~/ 8;
      final bitOffset = bitIndex % 8;
      out[bitIndex] = ((bytes[byteIndex] >> bitOffset) & 0x01);
    }
    return out;
  }

  static bool getBit(Uint8List bytes, {required int bitIndex}) {
    final byteIndex = bitIndex ~/ 8;
    final bitOffset = bitIndex % 8;
    if (byteIndex < 0 || byteIndex >= bytes.length) {
      throw RangeError.range(bitIndex, 0, bytes.length * 8 - 1, 'bitIndex');
    }
    return ((bytes[byteIndex] >> bitOffset) & 0x01) == 1;
  }

  static void setBit(
    Uint8List bytes, {
    required int bitIndex,
    required bool value,
  }) {
    final byteIndex = bitIndex ~/ 8;
    final bitOffset = bitIndex % 8;
    if (byteIndex < 0 || byteIndex >= bytes.length) {
      throw RangeError.range(bitIndex, 0, bytes.length * 8 - 1, 'bitIndex');
    }

    if (value) {
      bytes[byteIndex] |= (1 << bitOffset);
    } else {
      bytes[byteIndex] &= ~(1 << bitOffset);
    }
  }
}

