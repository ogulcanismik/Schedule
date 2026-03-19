import 'dart:typed_data';

/// 0 = raw (uncompressed), 1 = zlib-compressed body.
enum ShareCompressionType {
  raw(0),
  zlib(1);

  const ShareCompressionType(this.value);
  final int value;

  static ShareCompressionType fromValue(int v) {
    switch (v) {
      case 0:
        return ShareCompressionType.raw;
      case 1:
        return ShareCompressionType.zlib;
      default:
        throw FormatException('Unsupported compressionType=$v');
    }
  }
}

/// Phase 1 uses fixed 60-minute slots for the 08:00-20:00 window.
enum SlotGranularity {
  sixtyMinutes(0);

  const SlotGranularity(this.value);
  final int value;

  static SlotGranularity fromValue(int v) {
    switch (v) {
      case 0:
        return SlotGranularity.sixtyMinutes;
      default:
        throw FormatException('Unsupported slotGranularity=$v');
    }
  }
}

class DecodedScheduleShare {
  /// Display name included in the share string.
  final String username;

  /// Packed weekly busy/free bitmask bytes.
  ///
  /// Phase 1 (60-min slots, 08:00-20:00) => 84 bits => 11 bytes.
  final Uint8List bitmaskBytes;

  /// How the bitmask is interpreted (60min for Phase 1).
  final SlotGranularity slotGranularity;

  const DecodedScheduleShare({
    required this.username,
    required this.bitmaskBytes,
    required this.slotGranularity,
  });
}

class BinarySharePayload {
  final int version;
  final ShareCompressionType compressionType;
  final SlotGranularity slotGranularity;

  final String username;
  final Uint8List bitmaskBytes;

  const BinarySharePayload({
    required this.version,
    required this.compressionType,
    required this.slotGranularity,
    required this.username,
    required this.bitmaskBytes,
  });
}

class SharePayloadFormat {
  static const int version = 1;

  // Header:
  // byte0 = version
  // byte1 = flags:
  //   bit0 = compressionType
  //   bits1-2 = slotGranularity
  static const int flagsCompressionMask = 0x01;
  static const int flagsSlotGranularityMask = 0x06; // bits 1..2
  static const int flagsSlotGranularityShift = 1;
}

