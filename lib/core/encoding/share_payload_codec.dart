import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import 'bit_packing.dart';
import 'legacy_schedule_migration.dart';
import 'share_payload_types.dart';
import 'time_grid_mapper.dart';

class SharePayloadCodec {
  /// Encodes a share payload to bytes (header + chosen raw/zlib body).
  static Uint8List encodeBinaryPayload({
    required String username,
    required Uint8List bitmaskBytes,
    SlotGranularity slotGranularity = SlotGranularity.sixtyMinutes,
    int version = SharePayloadFormat.version,
    int zlibLevel = 9,
  }) {
    if (version != SharePayloadFormat.version) {
      throw ArgumentError.value(
        version,
        'version',
        'Only version ${SharePayloadFormat.version} is supported in Phase 1',
      );
    }

    final usernameBytes = utf8.encode(username);
    if (usernameBytes.length > 255) {
      throw ArgumentError.value(
        usernameBytes.length,
        'username',
        'Username UTF-8 length must be <= 255 for compact encoding',
      );
    }

    // Phase 1: 84 bits (08:00-20:00) => 11 bytes.
    final expectedBitmaskByteLen =
        (TimeGridMapper60Min.bitsPerWeek + 7) ~/ 8;
    if (bitmaskBytes.length != expectedBitmaskByteLen) {
      throw ArgumentError.value(
        bitmaskBytes.length,
        'bitmaskBytes',
        'Expected $expectedBitmaskByteLen bytes for 60-minute slots',
      );
    }

    // Body (uncompressed):
    // usernameLen (u8) + usernameBytes (UTF-8) + fixed bitmask bytes.
    final usernameLen = usernameBytes.length;
    final core = Uint8List(
      1 + usernameLen + expectedBitmaskByteLen,
    )..[0] = usernameLen;
    core.setRange(1, 1 + usernameLen, usernameBytes);
    core.setRange(
      1 + usernameLen,
      1 + usernameLen + expectedBitmaskByteLen,
      bitmaskBytes,
    );

    final zlibBody = ZLibEncoder().encodeBytes(core, level: zlibLevel);
    final compressionType = zlibBody.length < core.length
        ? ShareCompressionType.zlib
        : ShareCompressionType.raw;
    final body = compressionType == ShareCompressionType.zlib ? zlibBody : core;

    final header0 = version & 0xFF;
    final flags = (compressionType.value & SharePayloadFormat.flagsCompressionMask) |
        ((slotGranularity.value << SharePayloadFormat.flagsSlotGranularityShift) &
            SharePayloadFormat.flagsSlotGranularityMask);
    final payload = Uint8List(2 + body.length);
    payload[0] = header0;
    payload[1] = flags;
    payload.setRange(2, 2 + body.length, body);
    return payload;
  }

  /// Decodes a binary payload created by [encodeBinaryPayload].
  static BinarySharePayload decodeBinaryPayload(Uint8List payloadBytes) {
    if (payloadBytes.length < 2) {
      throw FormatException('Payload too short: ${payloadBytes.length} bytes');
    }

    final version = payloadBytes[0];
    if (version != SharePayloadFormat.version) {
      throw FormatException('Unsupported version=$version');
    }

    final flags = payloadBytes[1];
    final compressionType = ShareCompressionType.fromValue(
      flags & SharePayloadFormat.flagsCompressionMask,
    );

    final slotGranularityValue = (flags & SharePayloadFormat.flagsSlotGranularityMask) >>
        SharePayloadFormat.flagsSlotGranularityShift;
    final slotGranularity = SlotGranularity.fromValue(slotGranularityValue);

    final bodyBytes = payloadBytes.sublist(2);
    final core = compressionType == ShareCompressionType.zlib
        ? ZLibDecoder().decodeBytes(bodyBytes, verify: false)
        : Uint8List.fromList(bodyBytes);

    if (core.isEmpty) {
      throw FormatException('Decompressed body is empty');
    }

    final usernameLen = core[0];
    final expectedBitmaskByteLen =
        (TimeGridMapper60Min.bitsPerWeek + 7) ~/ 8;
    const legacyBitmaskByteLen = 13;
    final expectedTotalLen = 1 + usernameLen + expectedBitmaskByteLen;
    final legacyTotalLen = 1 + usernameLen + legacyBitmaskByteLen;

    if (core.length != expectedTotalLen && core.length != legacyTotalLen) {
      throw FormatException(
        'Invalid core length. Got ${core.length}, expected $expectedTotalLen '
        'or legacy $legacyTotalLen '
        '(usernameLen=$usernameLen)',
      );
    }

    final usernameStart = 1;
    final usernameEnd = usernameStart + usernameLen;
    final usernameBytes = core.sublist(usernameStart, usernameEnd);

    final bitmaskStart = usernameEnd;
    final rawBitmaskEnd = core.length;
    var bitmaskBytes =
        Uint8List.fromList(core.sublist(bitmaskStart, rawBitmaskEnd));
    if (bitmaskBytes.length == legacyBitmaskByteLen) {
      bitmaskBytes = migrateLegacy13ByteBitmaskToCurrent(bitmaskBytes);
    }

    late final String username;
    try {
      username = utf8.decode(usernameBytes);
    } on FormatException catch (e) {
      throw FormatException('Invalid UTF-8 username bytes: $e');
    }

    return BinarySharePayload(
      version: version,
      compressionType: compressionType,
      slotGranularity: slotGranularity,
      username: username,
      bitmaskBytes: bitmaskBytes,
    );
  }

  // Helper for later integration with WeeklyBitmask domain models.
  static List<int> unpackBitmaskToBits(Uint8List bitmaskBytes) {
    final bitCount = TimeGridMapper60Min.bitsPerWeek;
    return BitPacking.unpackBits(bitmaskBytes, bitCount: bitCount);
  }
}

