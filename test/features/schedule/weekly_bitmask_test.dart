import 'package:flutter_test/flutter_test.dart';
import 'package:unisync/features/schedule/domain/weekly_bitmask.dart';

void main() {
  group('WeeklyBitmask', () {
    test('allFree: every slot is free', () {
      final bitmask = WeeklyBitmask.allFree();
      for (var day = 0; day < 7; day++) {
        for (var slot = 0; slot < 12; slot++) {
          expect(
            bitmask.isFree(dayIndex: day, slotIndex: slot),
            isTrue,
            reason: 'day=$day slot=$slot should be free',
          );
        }
      }
      expect(bitmask.busyCount, equals(0));
    });

    test('allBusy: every slot is busy', () {
      final bitmask = WeeklyBitmask.allBusy();
      for (var day = 0; day < 7; day++) {
        for (var slot = 0; slot < 12; slot++) {
          expect(
            bitmask.isBusy(dayIndex: day, slotIndex: slot),
            isTrue,
            reason: 'day=$day slot=$slot should be busy',
          );
        }
      }
      expect(bitmask.busyCount, equals(84));
    });

    test('toggle changes a free slot to busy and back', () {
      final free = WeeklyBitmask.allFree();
      final afterSet = free.toggle(dayIndex: 2, slotIndex: 5);
      expect(afterSet.isBusy(dayIndex: 2, slotIndex: 5), isTrue);
      expect(afterSet.busyCount, equals(1));

      final afterClear = afterSet.toggle(dayIndex: 2, slotIndex: 5);
      expect(afterClear.isFree(dayIndex: 2, slotIndex: 5), isTrue);
      expect(afterClear.busyCount, equals(0));
    });

    test('toggle is immutable — original unchanged', () {
      final original = WeeklyBitmask.allFree();
      original.toggle(dayIndex: 0, slotIndex: 0);
      expect(original.isFree(dayIndex: 0, slotIndex: 0), isTrue);
    });

    test('withSlot sets and clears correctly', () {
      final bitmask = WeeklyBitmask.allFree()
          .withSlot(dayIndex: 1, slotIndex: 3, busy: true);
      expect(bitmask.isBusy(dayIndex: 1, slotIndex: 3), isTrue);

      final cleared =
          bitmask.withSlot(dayIndex: 1, slotIndex: 3, busy: false);
      expect(cleared.isFree(dayIndex: 1, slotIndex: 3), isTrue);
    });

    test('unionBusy: slot is busy if either mask has it busy', () {
      final a = WeeklyBitmask.allFree()
          .withSlot(dayIndex: 0, slotIndex: 0, busy: true);
      final b = WeeklyBitmask.allFree()
          .withSlot(dayIndex: 0, slotIndex: 1, busy: true);
      final union = a.unionBusy(b);
      expect(union.isBusy(dayIndex: 0, slotIndex: 0), isTrue);
      expect(union.isBusy(dayIndex: 0, slotIndex: 1), isTrue);
      expect(union.isFree(dayIndex: 0, slotIndex: 2), isTrue);
    });

    test('bytes roundtrip via fromBytes preserves bitmask', () {
      final bitmask = WeeklyBitmask.allFree()
          .toggle(dayIndex: 3, slotIndex: 7)
          .toggle(dayIndex: 6, slotIndex: 11);
      final restored = WeeklyBitmask.fromBytes(bitmask.bytes);
      expect(restored, equals(bitmask));
    });

    test('equality: two allFree bitmasks are equal', () {
      expect(WeeklyBitmask.allFree(), equals(WeeklyBitmask.allFree()));
    });

    test('equality: allFree != allBusy', () {
      expect(WeeklyBitmask.allFree(), isNot(equals(WeeklyBitmask.allBusy())));
    });
  });
}
