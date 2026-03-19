import '../../../core/encoding/share_string.dart';
import 'weekly_bitmask.dart';

/// A person's full weekly schedule: a display name plus a 98-bit busy/free grid.
class Schedule {
  final String username;
  final WeeklyBitmask bitmask;

  const Schedule({required this.username, required this.bitmask});

  factory Schedule.empty(String username) =>
      Schedule(username: username, bitmask: WeeklyBitmask.allFree());

  /// Returns a new [Schedule] with the given slot toggled.
  Schedule toggle({required int dayIndex, required int slotIndex}) => Schedule(
        username: username,
        bitmask: bitmask.toggle(dayIndex: dayIndex, slotIndex: slotIndex),
      );

  /// Returns a new [Schedule] with the given slot explicitly set.
  Schedule withSlot({
    required int dayIndex,
    required int slotIndex,
    required bool busy,
  }) =>
      Schedule(
        username: username,
        bitmask: bitmask.withSlot(
          dayIndex: dayIndex,
          slotIndex: slotIndex,
          busy: busy,
        ),
      );

  /// Encodes this schedule into a compact, URL-safe share string.
  String toShareString() => ShareStringCodec.encodeScheduleShare(
        username: username,
        bitmaskBytes: bitmask.bytes,
      );

  /// Decodes a share string produced by [toShareString] back into a [Schedule].
  static Schedule fromShareString(String shareString) {
    final decoded = ShareStringCodec.decodeScheduleShare(shareString);
    return Schedule(
      username: decoded.username,
      bitmask: WeeklyBitmask.fromBytes(decoded.bitmaskBytes),
    );
  }

  Schedule copyWith({String? username, WeeklyBitmask? bitmask}) => Schedule(
        username: username ?? this.username,
        bitmask: bitmask ?? this.bitmask,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Schedule &&
          other.username == username &&
          other.bitmask == bitmask;

  @override
  int get hashCode => Object.hash(username, bitmask);

  @override
  String toString() => 'Schedule(username: $username, $bitmask)';
}
