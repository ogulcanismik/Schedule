import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/schedule.dart';
import '../infrastructure/schedule_repository_hive.dart';

/// Provides the initialised [ScheduleRepositoryHive] instance.
///
/// Must be overridden in [ProviderScope] after Hive has been initialised.
final scheduleRepositoryProvider = Provider<ScheduleRepositoryHive>((ref) {
  throw StateError(
    'ScheduleRepositoryHive must be overridden after Hive.init(). '
    'Use ProviderScope(overrides: [...]) in main.',
  );
});

/// Notifier that manages the current user's own [Schedule].
class ScheduleNotifier extends Notifier<Schedule> {
  ScheduleRepositoryHive get _repo => ref.read(scheduleRepositoryProvider);

  @override
  Schedule build() => _repo.load() ?? Schedule.empty('Me');

  Future<void> toggleSlot({
    required int dayIndex,
    required int slotIndex,
  }) async {
    state = state.toggle(dayIndex: dayIndex, slotIndex: slotIndex);
    await _repo.save(state);
  }

  Future<void> updateUsername(String username) async {
    final trimmed = username.trim();
    state = state.copyWith(username: trimmed.isEmpty ? 'Me' : trimmed);
    await _repo.save(state);
  }

  Future<void> clearSchedule() async {
    state = Schedule.empty(state.username);
    await _repo.save(state);
  }
}

final scheduleProvider =
    NotifierProvider<ScheduleNotifier, Schedule>(ScheduleNotifier.new);
