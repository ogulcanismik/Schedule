import 'dart:typed_data';

import 'bit_packing.dart';

/// Old format: 7×14 hourly slots (08:00–22:00) = 98 bits, 13 packed bytes.
const int _legacyBitsPerWeek = 98;
const int _legacySlotsPerDay = 14;

/// Migrates a 13-byte packed bitmask (98 bits) to the current 11-byte / 84-bit
/// format (08:00–20:00, 12 slots per day). For each day, copies the first 12
/// hourly slots; the old 20:00–22:00 pair is dropped.
Uint8List migrateLegacy13ByteBitmaskToCurrent(Uint8List legacy13) {
  if (legacy13.length != 13) {
    throw ArgumentError(
      'Legacy bitmask must be exactly 13 bytes, got ${legacy13.length}',
    );
  }
  final oldBits =
      BitPacking.unpackBits(legacy13, bitCount: _legacyBitsPerWeek);
  const newBitsPerWeek = 84;
  const newSlotsPerDay = 12;
  final newBits = List<int>.filled(newBitsPerWeek, 0);
  for (var d = 0; d < 7; d++) {
    for (var s = 0; s < newSlotsPerDay; s++) {
      newBits[d * newSlotsPerDay + s] =
          oldBits[d * _legacySlotsPerDay + s];
    }
  }
  return BitPacking.packBits(newBits, bitCount: newBitsPerWeek);
}
