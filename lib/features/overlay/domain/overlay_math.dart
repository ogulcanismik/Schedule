import 'dart:typed_data';

import '../../schedule/domain/weekly_bitmask.dart';
import '../../../core/encoding/time_grid_mapper.dart';

/// One person included in an overlay comparison.
///
/// Set [isUser] to `true` for the device owner's schedule so that their
/// busy state can be distinguished from friends' busy state.
class OverlayParticipant {
  final WeeklyBitmask bitmask;
  final String label;

  /// Whether this participant is the device owner (not a friend).
  final bool isUser;

  const OverlayParticipant({
    required this.bitmask,
    required this.label,
    this.isUser = false,
  });
}

/// The result of computing a schedule overlay across multiple people.
class OverlayResult {
  /// 1 = at least one person is busy in this slot.
  final WeeklyBitmask unionBusy;

  /// 1 = every selected person is free in this slot (highlight green).
  final WeeklyBitmask commonFree;

  /// Per-slot busy count across ALL participants (0..totalPersons).
  final List<int> busyCountPerSlot;

  /// Per-slot list of **friend** names who are **free** in that slot.
  /// The user's name is never included here.
  final List<List<String>> freeNamesPerSlot;

  /// Per-slot flag: true when the device owner (isUser) is busy.
  final List<bool> userBusyPerSlot;

  /// Number of schedules included in this overlay.
  final int totalPersons;

  const OverlayResult({
    required this.unionBusy,
    required this.commonFree,
    required this.busyCountPerSlot,
    required this.freeNamesPerSlot,
    required this.userBusyPerSlot,
    required this.totalPersons,
  });

  bool isCommonFree({required int dayIndex, required int slotIndex}) =>
      commonFree.isBusy(dayIndex: dayIndex, slotIndex: slotIndex);

  int busyCountAt({required int dayIndex, required int slotIndex}) {
    final idx =
        TimeGridMapper60Min.bitIndex(dayIndex: dayIndex, slotIndex: slotIndex);
    return busyCountPerSlot[idx];
  }

  /// Friend names who are **free** in this slot (never includes the user).
  List<String> freeNamesAt({required int dayIndex, required int slotIndex}) {
    final idx =
        TimeGridMapper60Min.bitIndex(dayIndex: dayIndex, slotIndex: slotIndex);
    return freeNamesPerSlot[idx];
  }

  /// Whether the device owner is busy in this slot.
  bool isUserBusy({required int dayIndex, required int slotIndex}) {
    final idx =
        TimeGridMapper60Min.bitIndex(dayIndex: dayIndex, slotIndex: slotIndex);
    return userBusyPerSlot[idx];
  }
}

class OverlayMath {
  /// Computes the overlay for [participants].
  ///
  /// Exactly one participant should have [OverlayParticipant.isUser] == true
  /// (the device owner). All others are treated as friends.
  ///
  /// - [OverlayResult.commonFree]: slots where ALL people are free.
  /// - [OverlayResult.freeNamesPerSlot]: friend names free per slot.
  /// - [OverlayResult.userBusyPerSlot]: whether the user is busy per slot.
  static OverlayResult computeOverlay(List<OverlayParticipant> participants) {
    final bitCount = TimeGridMapper60Min.bitsPerWeek;

    if (participants.isEmpty) {
      return OverlayResult(
        unionBusy: WeeklyBitmask.allFree(),
        commonFree: WeeklyBitmask.allFree(),
        busyCountPerSlot: List<int>.filled(bitCount, 0),
        freeNamesPerSlot: List.generate(bitCount, (_) => <String>[]),
        userBusyPerSlot: List<bool>.filled(bitCount, false),
        totalPersons: 0,
      );
    }

    final byteCount = WeeklyBitmask.byteCount;

    final unionBytes = Uint8List(byteCount);
    final countPerSlot = List<int>.filled(bitCount, 0);
    final freeNamesPerSlot = List.generate(bitCount, (_) => <String>[]);
    final userBusyPerSlot = List<bool>.filled(bitCount, false);

    // Separate user from friends.
    final userParticipant =
        participants.where((p) => p.isUser).firstOrNull;
    final friends = participants.where((p) => !p.isUser).toList();

    // Build union-busy and count across ALL participants.
    for (final participant in participants) {
      final b = participant.bitmask.bytes;
      for (var i = 0; i < byteCount; i++) {
        unionBytes[i] |= b[i];
      }
      for (var bit = 0; bit < bitCount; bit++) {
        if ((b[bit ~/ 8] >> (bit % 8)) & 0x01 == 1) {
          countPerSlot[bit]++;
        }
      }
    }

    // Per-slot: record user busy state.
    if (userParticipant != null) {
      final ub = userParticipant.bitmask.bytes;
      for (var bit = 0; bit < bitCount; bit++) {
        if ((ub[bit ~/ 8] >> (bit % 8)) & 0x01 == 1) {
          userBusyPerSlot[bit] = true;
        }
      }
    }

    // Per-slot: record which friends are FREE (not busy).
    for (final friend in friends) {
      final fb = friend.bitmask.bytes;
      for (var bit = 0; bit < bitCount; bit++) {
        final isBusy = (fb[bit ~/ 8] >> (bit % 8)) & 0x01 == 1;
        if (!isBusy) {
          freeNamesPerSlot[bit].add(friend.label);
        }
      }
    }

    // commonFree = NOT unionBusy (masked to valid weekly bit range).
    final commonFreeBytes = Uint8List(byteCount);
    for (var i = 0; i < byteCount; i++) {
      commonFreeBytes[i] = (~unionBytes[i]) & 0xFF;
    }
    // Zero out unused padding bits in the last packed byte.
    final usedBitsInLastByte = bitCount % 8;
    if (usedBitsInLastByte != 0) {
      final mask = (1 << usedBitsInLastByte) - 1;
      commonFreeBytes[byteCount - 1] &= mask;
    }

    return OverlayResult(
      unionBusy: WeeklyBitmask.fromBytes(unionBytes),
      commonFree: WeeklyBitmask.fromBytes(commonFreeBytes),
      busyCountPerSlot: countPerSlot,
      freeNamesPerSlot: freeNamesPerSlot,
      userBusyPerSlot: userBusyPerSlot,
      totalPersons: participants.length,
    );
  }
}
