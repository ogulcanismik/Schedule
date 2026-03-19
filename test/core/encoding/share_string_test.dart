import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:unisync/core/encoding/share_string.dart';
import 'package:unisync/core/encoding/bit_packing.dart';
import 'package:unisync/core/encoding/time_grid_mapper.dart';

/// Returns a bitmask [Uint8List] of 11 bytes with all bits set to 0.
Uint8List _allFreeBytes() => Uint8List(11);

/// Returns a bitmask [Uint8List] of 11 bytes with all 84 bits set to 1.
Uint8List _allBusyBytes() {
  const bitCount = 84;
  final bits = List<int>.filled(bitCount, 1);
  return BitPacking.packBits(bits, bitCount: bitCount);
}

void main() {
  group('ShareStringCodec: encode -> decode roundtrip', () {
    test('all-free schedule roundtrips correctly', () {
      const username = 'Alice';
      final bitmask = _allFreeBytes();

      final shareString =
          ShareStringCodec.encodeScheduleShare(username: username, bitmaskBytes: bitmask);
      expect(shareString, isNotEmpty);
      expect(shareString.contains('='), isFalse, reason: 'No padding chars allowed');

      final decoded = ShareStringCodec.decodeScheduleShare(shareString);
      expect(decoded.username, equals(username));
      expect(decoded.bitmaskBytes, equals(bitmask));
    });

    test('all-busy schedule roundtrips correctly', () {
      const username = 'Bob';
      final bitmask = _allBusyBytes();

      final shareString =
          ShareStringCodec.encodeScheduleShare(username: username, bitmaskBytes: bitmask);
      final decoded = ShareStringCodec.decodeScheduleShare(shareString);
      expect(decoded.username, equals(username));
      expect(decoded.bitmaskBytes, equals(bitmask));
    });

    test('unicode username roundtrips correctly', () {
      const username = 'Öğulcan';
      final bitmask = _allFreeBytes();

      final shareString =
          ShareStringCodec.encodeScheduleShare(username: username, bitmaskBytes: bitmask);
      final decoded = ShareStringCodec.decodeScheduleShare(shareString);
      expect(decoded.username, equals(username));
    });

    test('empty username roundtrips correctly', () {
      const username = '';
      final bitmask = _allFreeBytes();

      final shareString =
          ShareStringCodec.encodeScheduleShare(username: username, bitmaskBytes: bitmask);
      final decoded = ShareStringCodec.decodeScheduleShare(shareString);
      expect(decoded.username, equals(username));
    });

    test('share string contains only URL-safe characters', () {
      final shareString = ShareStringCodec.encodeScheduleShare(
        username: 'TestUser',
        bitmaskBytes: _allBusyBytes(),
      );
      final urlSafe = RegExp(r'^[A-Za-z0-9\-_]+$');
      expect(urlSafe.hasMatch(shareString), isTrue,
          reason: 'Share string must be URL-safe base64url without padding');
    });

    test('two different schedules produce different strings', () {
      final free =
          ShareStringCodec.encodeScheduleShare(username: 'X', bitmaskBytes: _allFreeBytes());
      final busy =
          ShareStringCodec.encodeScheduleShare(username: 'X', bitmaskBytes: _allBusyBytes());
      expect(free, isNot(equals(busy)));
    });
  });

  group('ShareStringCodec: string length (WhatsApp/QR friendliness)', () {
    test('all-free + short name produces <=60 character share string', () {
      final shareString = ShareStringCodec.encodeScheduleShare(
        username: 'Ali',
        bitmaskBytes: _allFreeBytes(),
      );
      // For reference: 2 header + 1 len + 3 username + 11 bitmask = 17 raw bytes
      // => ceil(19*8/6) = 26 base64url chars (raw) or shorter with zlib.
      expect(shareString.length, lessThanOrEqualTo(60),
          reason: 'Share string must be short enough for WhatsApp/QR');
    });
  });

  group('ShareStringCodec: invalid input rejection', () {
    test('empty string throws FormatException', () {
      expect(
        () => ShareStringCodec.decodeScheduleShare(''),
        throwsFormatException,
      );
    });

    test('invalid base64url characters throw FormatException', () {
      expect(
        () => ShareStringCodec.decodeScheduleShare('!!!invalid!!!'),
        throwsFormatException,
      );
    });

    test('corrupted payload throws FormatException', () {
      // Valid base64url but random bytes that can't decode as a valid payload.
      expect(
        () => ShareStringCodec.decodeScheduleShare('AAAA'),
        throwsFormatException,
      );
    });

    test('wrong version in payload throws FormatException', () {
      // Construct a payload with version byte = 99.
      final fakePayload = Uint8List(16);
      fakePayload[0] = 99; // unsupported version
      final encoded = base64Url.encode(fakePayload).replaceAll('=', '');
      expect(
        () => ShareStringCodec.decodeScheduleShare(encoded),
        throwsFormatException,
      );
    });
  });

  group('TimeGridMapper60Min', () {
    test('bitIndex for Mon slot 0 (08:00) is 0', () {
      expect(
        TimeGridMapper60Min.bitIndex(dayIndex: 0, slotIndex: 0),
        equals(0),
      );
    });

    test('bitIndex for Mon slot 11 (19:00) is 11', () {
      expect(
        TimeGridMapper60Min.bitIndex(dayIndex: 0, slotIndex: 11),
        equals(11),
      );
    });

    test('bitIndex for Sun slot 11 is 83 (last valid bit)', () {
      expect(
        TimeGridMapper60Min.bitIndex(dayIndex: 6, slotIndex: 11),
        equals(83),
      );
    });

    test('daySlotFromBitIndex is inverse of bitIndex', () {
      for (var day = 0; day < 7; day++) {
        for (var slot = 0; slot < 12; slot++) {
          final idx =
              TimeGridMapper60Min.bitIndex(dayIndex: day, slotIndex: slot);
          final reverse = TimeGridMapper60Min.daySlotFromBitIndex(idx);
          expect(reverse.dayIndex, equals(day));
          expect(reverse.slotIndex, equals(slot));
        }
      }
    });
  });
}
