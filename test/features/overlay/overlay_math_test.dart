import 'package:flutter_test/flutter_test.dart';
import 'package:unisync/features/overlay/domain/overlay_math.dart';
import 'package:unisync/features/schedule/domain/weekly_bitmask.dart';

/// Helper: create a non-user participant.
OverlayParticipant _p(WeeklyBitmask b, String label) =>
    OverlayParticipant(bitmask: b, label: label);

/// Helper: create the device-owner participant.
OverlayParticipant _user(WeeklyBitmask b, String label) =>
    OverlayParticipant(bitmask: b, label: label, isUser: true);

void main() {
  group('OverlayMath.computeOverlay', () {
    test('empty list returns all-free overlay', () {
      final result = OverlayMath.computeOverlay([]);
      expect(result.totalPersons, equals(0));
      expect(result.unionBusy.busyCount, equals(0));
      expect(result.commonFree.busyCount, equals(0));
    });

    test('single all-free schedule: commonFree = all slots', () {
      final result = OverlayMath.computeOverlay(
          [_user(WeeklyBitmask.allFree(), 'Solo')]);
      expect(result.commonFree.busyCount, equals(84),
          reason: 'All 84 slots are free');
      expect(result.unionBusy.busyCount, equals(0));
    });

    test('single all-busy schedule: commonFree = no slots', () {
      final result = OverlayMath.computeOverlay(
          [_user(WeeklyBitmask.allBusy(), 'Me')]);
      expect(result.commonFree.busyCount, equals(0));
      expect(result.unionBusy.busyCount, equals(84));
      // No friends → freeNamesAt returns empty list everywhere.
      expect(
        result.freeNamesAt(dayIndex: 0, slotIndex: 0),
        isEmpty,
      );
    });

    test('user free + friend busy: slot not in commonFree; no free names', () {
      final userBitmask = WeeklyBitmask.allFree();
      final friendBitmask = WeeklyBitmask.allFree()
          .withSlot(dayIndex: 0, slotIndex: 0, busy: true);

      final result = OverlayMath.computeOverlay([
        _user(userBitmask, 'Me'),
        _p(friendBitmask, 'Alice'),
      ]);

      expect(result.isUserBusy(dayIndex: 0, slotIndex: 0), isFalse);
      expect(result.commonFree.isBusy(dayIndex: 0, slotIndex: 0), isFalse);
      // Alice is busy at slot 0 → she is NOT in freeNamesAt.
      expect(
        result.freeNamesAt(dayIndex: 0, slotIndex: 0),
        isEmpty,
      );
    });

    test('user busy + friend free: freeNamesAt returns friend; isUserBusy true',
        () {
      final userBitmask = WeeklyBitmask.allFree()
          .withSlot(dayIndex: 0, slotIndex: 0, busy: true);
      final friendBitmask = WeeklyBitmask.allFree();

      final result = OverlayMath.computeOverlay([
        _user(userBitmask, 'Me'),
        _p(friendBitmask, 'Bob'),
      ]);

      expect(result.isUserBusy(dayIndex: 0, slotIndex: 0), isTrue);
      expect(
        result.freeNamesAt(dayIndex: 0, slotIndex: 0),
        equals(['Bob']),
      );
    });

    test('two friends with non-overlapping busy slots', () {
      final userBitmask = WeeklyBitmask.allFree();
      final a = WeeklyBitmask.allFree()
          .withSlot(dayIndex: 0, slotIndex: 0, busy: true);
      final b = WeeklyBitmask.allFree()
          .withSlot(dayIndex: 0, slotIndex: 1, busy: true);

      final result = OverlayMath.computeOverlay([
        _user(userBitmask, 'Me'),
        _p(a, 'Alice'),
        _p(b, 'Bob'),
      ]);

      expect(result.unionBusy.isBusy(dayIndex: 0, slotIndex: 0), isTrue);
      expect(result.unionBusy.isBusy(dayIndex: 0, slotIndex: 1), isTrue);
      expect(result.commonFree.isBusy(dayIndex: 0, slotIndex: 0), isFalse);
      expect(result.commonFree.isBusy(dayIndex: 0, slotIndex: 1), isFalse);
      expect(result.commonFree.busyCount, equals(82),
          reason: '84 - 2 busy union slots = 82 free slots');

      // At slot 0,0: Alice busy → only Bob is free.
      expect(
        result.freeNamesAt(dayIndex: 0, slotIndex: 0),
        equals(['Bob']),
      );
      // At slot 0,1: Bob busy → only Alice is free.
      expect(
        result.freeNamesAt(dayIndex: 0, slotIndex: 1),
        equals(['Alice']),
      );
    });

    test('busyCountAt returns 0 for a slot nobody is busy in', () {
      final result = OverlayMath.computeOverlay([
        _user(WeeklyBitmask.allFree(), 'Me'),
        _p(WeeklyBitmask.allFree(), 'B'),
      ]);
      expect(result.busyCountAt(dayIndex: 0, slotIndex: 0), equals(0));
    });

    test('busyCountAt returns 2 when both user and friend are busy', () {
      final a = WeeklyBitmask.allFree()
          .withSlot(dayIndex: 1, slotIndex: 5, busy: true);
      final b = WeeklyBitmask.allFree()
          .withSlot(dayIndex: 1, slotIndex: 5, busy: true);
      final result = OverlayMath.computeOverlay([
        _user(a, 'Me'),
        _p(b, 'B'),
      ]);
      expect(result.busyCountAt(dayIndex: 1, slotIndex: 5), equals(2));
      // Both busy → friend B is not free → freeNamesAt returns empty.
      expect(
        result.freeNamesAt(dayIndex: 1, slotIndex: 5),
        isEmpty,
      );
      expect(result.isUserBusy(dayIndex: 1, slotIndex: 5), isTrue);
    });

    test('commonFree padding bits are zeroed (no spurious free slots)', () {
      final result = OverlayMath.computeOverlay([
        _user(WeeklyBitmask.allBusy(), 'X'),
      ]);
      expect(result.commonFree.busyCount, equals(0));
    });
  });
}
