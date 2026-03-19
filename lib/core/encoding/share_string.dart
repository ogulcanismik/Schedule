import 'dart:convert';
import 'dart:typed_data';

import 'share_payload_codec.dart';
import 'share_payload_types.dart';

class ShareStringCodec {
  /// Encodes [username] + [bitmaskBytes] into a URL-safe (no padding) string.
  static String encodeScheduleShare({
    required String username,
    required Uint8List bitmaskBytes,
    SlotGranularity slotGranularity = SlotGranularity.sixtyMinutes,
    int zlibLevel = 9,
  }) {
    final payloadBytes = SharePayloadCodec.encodeBinaryPayload(
      username: username,
      bitmaskBytes: bitmaskBytes,
      slotGranularity: slotGranularity,
      zlibLevel: zlibLevel,
    );

    // Base64url encoding is URL-safe; we strip `=` padding to shorten.
    final b64 = base64Url.encode(payloadBytes);
    return b64.replaceAll('=', '');
  }

  /// Decodes a share string produced by [encodeScheduleShare].
  static DecodedScheduleShare decodeScheduleShare(String shareString) {
    final payloadBytes = _decodeBase64UrlNoPadding(shareString);
    final decodedPayload = SharePayloadCodec.decodeBinaryPayload(payloadBytes);
    return DecodedScheduleShare(
      username: decodedPayload.username,
      bitmaskBytes: decodedPayload.bitmaskBytes,
      slotGranularity: decodedPayload.slotGranularity,
    );
  }

  static Uint8List _decodeBase64UrlNoPadding(String s) {
    var str = s.trim();
    if (str.isEmpty) {
      throw FormatException('Share string is empty');
    }

    // Restore '=' padding for standard base64 decoding.
    final mod = str.length % 4;
    if (mod == 1) {
      // Impossible in base64; indicates corruption.
      throw FormatException('Invalid base64url length: ${str.length}');
    }
    if (mod > 0) {
      str = str + ('=' * (4 - mod));
    }

    try {
      final decoded = base64Url.decode(str);
      return Uint8List.fromList(decoded);
    } on FormatException catch (e) {
      throw FormatException('Invalid base64url share string: $e');
    }
  }
}

