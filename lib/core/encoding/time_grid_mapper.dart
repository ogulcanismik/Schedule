// Maps the weekly grid UI coordinates (day + slot) to a stable bit index.
// Phase 1 uses fixed 60-minute slots in the time window 08:00-20:00.
class TimeGridMapper60Min {
  static const int daysPerWeek = 7;
  static const int slotsPerDay = 12; // 08:00-09:00 ... 19:00-20:00
  static const int bitsPerWeek = daysPerWeek * slotsPerDay; // 84

  static const int minutesPerSlot = 60;
  static const int startHour = 8; // 08:00

  /// Maps [dayIndex] (0..6) + [slotIndex] (0..11) to a bit index (0..83).
  static int bitIndex({required int dayIndex, required int slotIndex}) {
    _validateDayIndex(dayIndex);
    _validateSlotIndex(slotIndex);
    return dayIndex * slotsPerDay + slotIndex;
  }

  /// Reverse mapping from a bit index back to (dayIndex, slotIndex).
  static ({int dayIndex, int slotIndex}) daySlotFromBitIndex(int bitIndex) {
    if (bitIndex < 0 || bitIndex >= bitsPerWeek) {
      throw RangeError.range(bitIndex, 0, bitsPerWeek - 1, 'bitIndex');
    }
    final dayIndex = bitIndex ~/ slotsPerDay;
    final slotIndex = bitIndex % slotsPerDay;
    return (dayIndex: dayIndex, slotIndex: slotIndex);
  }

  /// Returns the number of minutes since midnight for the *start* of [slotIndex].
  static int slotStartMinutes(int slotIndex) {
    _validateSlotIndex(slotIndex);
    return startHour * 60 + slotIndex * minutesPerSlot;
  }

  static void _validateDayIndex(int dayIndex) {
    if (dayIndex < 0 || dayIndex >= daysPerWeek) {
      throw RangeError.range(dayIndex, 0, daysPerWeek - 1, 'dayIndex');
    }
  }

  static void _validateSlotIndex(int slotIndex) {
    if (slotIndex < 0 || slotIndex >= slotsPerDay) {
      throw RangeError.range(slotIndex, 0, slotsPerDay - 1, 'slotIndex');
    }
  }
}
