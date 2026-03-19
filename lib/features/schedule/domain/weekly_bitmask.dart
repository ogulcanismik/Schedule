import 'dart:typed_data';

import '../../../core/encoding/bit_packing.dart';
import '../../../core/encoding/legacy_schedule_migration.dart';
import '../../../core/encoding/time_grid_mapper.dart';

/// Immutable 84-bit bitmask representing one person's weekly busy/free state.
///
/// Layout: bit index = dayIndex * 12 + slotIndex (08:00-20:00 hourly).
/// 1 = busy, 0 = free.
class WeeklyBitmask {
  static const int bitCount = TimeGridMapper60Min.bitsPerWeek; // 84
  static const int byteCount = (bitCount + 7) ~/ 8; // 11

  final Uint8List _bytes;

  WeeklyBitmask._(Uint8List bytes)
      : assert(bytes.length == byteCount, 'WeeklyBitmask requires $byteCount bytes'),
        _bytes = bytes;

  factory WeeklyBitmask.allFree() => WeeklyBitmask._(Uint8List(byteCount));

  factory WeeklyBitmask.allBusy() {
    final bytes = Uint8List(byteCount);
    for (var i = 0; i < byteCount - 1; i++) {
      bytes[i] = 0xFF;
    }
    final rem = bitCount % 8;
    if (rem == 0) {
      if (byteCount > 0) bytes[byteCount - 1] = 0xFF;
    } else {
      bytes[byteCount - 1] = (1 << rem) - 1;
    }
    return WeeklyBitmask._(bytes);
  }

  /// Accepts current [byteCount] bytes, or legacy 13-byte (98-bit) payloads
  /// from older app versions / share codes (migrated automatically).
  factory WeeklyBitmask.fromBytes(Uint8List bytes) {
    Uint8List normalized = bytes;
    if (bytes.length == 13 && byteCount == 11) {
      normalized = migrateLegacy13ByteBitmaskToCurrent(bytes);
    }
    if (normalized.length != byteCount) {
      throw ArgumentError(
        'Expected $byteCount bytes (or legacy 13), got ${bytes.length}',
      );
    }
    return WeeklyBitmask._(Uint8List.fromList(normalized));
  }

  /// Returns a defensive copy of the raw bytes.
  Uint8List get bytes => Uint8List.fromList(_bytes);

  bool isBusy({required int dayIndex, required int slotIndex}) {
    final idx = TimeGridMapper60Min.bitIndex(
      dayIndex: dayIndex,
      slotIndex: slotIndex,
    );
    return BitPacking.getBit(_bytes, bitIndex: idx);
  }

  bool isFree({required int dayIndex, required int slotIndex}) =>
      !isBusy(dayIndex: dayIndex, slotIndex: slotIndex);

  /// Returns a new bitmask with the given slot toggled.
  WeeklyBitmask toggle({required int dayIndex, required int slotIndex}) {
    final newBytes = Uint8List.fromList(_bytes);
    final idx = TimeGridMapper60Min.bitIndex(
      dayIndex: dayIndex,
      slotIndex: slotIndex,
    );
    BitPacking.setBit(
      newBytes,
      bitIndex: idx,
      value: !BitPacking.getBit(_bytes, bitIndex: idx),
    );
    return WeeklyBitmask._(newBytes);
  }

  /// Returns a new bitmask with the given slot set to [busy].
  WeeklyBitmask withSlot({
    required int dayIndex,
    required int slotIndex,
    required bool busy,
  }) {
    final newBytes = Uint8List.fromList(_bytes);
    final idx = TimeGridMapper60Min.bitIndex(
      dayIndex: dayIndex,
      slotIndex: slotIndex,
    );
    BitPacking.setBit(newBytes, bitIndex: idx, value: busy);
    return WeeklyBitmask._(newBytes);
  }

  /// Bitwise OR — result has 1 wherever **any** of the two schedules is busy.
  WeeklyBitmask unionBusy(WeeklyBitmask other) {
    final result = Uint8List(byteCount);
    for (var i = 0; i < byteCount; i++) {
      result[i] = _bytes[i] | other._bytes[i];
    }
    return WeeklyBitmask._(result);
  }

  /// Number of busy slots in this bitmask (max 98).
  int get busyCount {
    var count = 0;
    for (var i = 0; i < bitCount; i++) {
      if (BitPacking.getBit(_bytes, bitIndex: i)) count++;
    }
    return count;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WeeklyBitmask &&
          _bytesEqual(_bytes, other._bytes);

  @override
  int get hashCode => Object.hashAll(_bytes);

  static bool _bytesEqual(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  String toString() => 'WeeklyBitmask(busyCount: $busyCount)';
}
