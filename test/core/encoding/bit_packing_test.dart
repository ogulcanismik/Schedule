import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:unisync/core/encoding/bit_packing.dart';

void main() {
  group('BitPacking.packBits / unpackBits roundtrip', () {
    test('all-free (all zeros) roundtrips correctly', () {
      const bitCount = 84;
      final bits = List<int>.filled(bitCount, 0);
      final packed = BitPacking.packBits(bits, bitCount: bitCount);
      expect(packed.length, equals(11));
      expect(packed.every((b) => b == 0), isTrue);

      final unpacked = BitPacking.unpackBits(packed, bitCount: bitCount);
      expect(unpacked, equals(bits));
    });

    test('all-busy (all ones) roundtrips correctly', () {
      const bitCount = 84;
      final bits = List<int>.filled(bitCount, 1);
      final packed = BitPacking.packBits(bits, bitCount: bitCount);
      expect(packed.length, equals(11));

      final unpacked = BitPacking.unpackBits(packed, bitCount: bitCount);
      expect(unpacked, equals(bits));
    });

    test('single bit set at index 0 roundtrips', () {
      const bitCount = 84;
      final bits = List<int>.filled(bitCount, 0)..[0] = 1;
      final packed = BitPacking.packBits(bits, bitCount: bitCount);
      expect(packed[0], equals(0x01));

      final unpacked = BitPacking.unpackBits(packed, bitCount: bitCount);
      expect(unpacked, equals(bits));
    });

    test('single bit set at index 83 (last valid bit) roundtrips', () {
      const bitCount = 84;
      final bits = List<int>.filled(bitCount, 0)..[83] = 1;
      final packed = BitPacking.packBits(bits, bitCount: bitCount);

      final unpacked = BitPacking.unpackBits(packed, bitCount: bitCount);
      expect(unpacked, equals(bits));
    });

    test('alternating bits roundtrip', () {
      const bitCount = 98;
      final bits = List<int>.generate(bitCount, (i) => i % 2);
      final packed = BitPacking.packBits(bits, bitCount: bitCount);
      final unpacked = BitPacking.unpackBits(packed, bitCount: bitCount);
      expect(unpacked, equals(bits));
    });

    test('LSB-first: bit 0 maps to byte[0] bit 0', () {
      const bitCount = 8;
      final bits = [1, 0, 0, 0, 0, 0, 0, 0];
      final packed = BitPacking.packBits(bits, bitCount: bitCount);
      expect(packed[0], equals(0x01));
    });

    test('LSB-first: bit 7 maps to byte[0] bit 7', () {
      const bitCount = 8;
      final bits = [0, 0, 0, 0, 0, 0, 0, 1];
      final packed = BitPacking.packBits(bits, bitCount: bitCount);
      expect(packed[0], equals(0x80));
    });

    test('throws when bits list length != bitCount', () {
      expect(
        () => BitPacking.packBits([1, 0], bitCount: 5),
        throwsArgumentError,
      );
    });

    test('throws when bytes length is wrong for unpack', () {
      expect(
        () => BitPacking.unpackBits(Uint8List(5), bitCount: 84),
        throwsArgumentError,
      );
    });

    test('throws on invalid bit value', () {
      expect(
        () => BitPacking.packBits([2], bitCount: 1),
        throwsArgumentError,
      );
    });
  });

  group('BitPacking.getBit / setBit', () {
    test('getBit returns false on zeroed bytes', () {
      final bytes = Uint8List(13);
      expect(BitPacking.getBit(bytes, bitIndex: 0), isFalse);
      expect(BitPacking.getBit(bytes, bitIndex: 97), isFalse);
    });

    test('setBit true then getBit returns true', () {
      final bytes = Uint8List(13);
      BitPacking.setBit(bytes, bitIndex: 10, value: true);
      expect(BitPacking.getBit(bytes, bitIndex: 10), isTrue);
    });

    test('setBit false clears a previously set bit', () {
      final bytes = Uint8List(11);
      BitPacking.setBit(bytes, bitIndex: 10, value: true);
      BitPacking.setBit(bytes, bitIndex: 10, value: false);
      expect(BitPacking.getBit(bytes, bitIndex: 10), isFalse);
    });
  });
}
