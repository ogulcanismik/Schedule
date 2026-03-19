import 'dart:convert';
import 'dart:typed_data';

import 'package:hive_flutter/hive_flutter.dart';

import '../domain/schedule.dart';
import '../domain/weekly_bitmask.dart';

/// Persists the user's own [Schedule] in a local Hive box as a JSON string.
///
/// Only one record is stored (the user's own schedule), keyed by [_key].
class ScheduleRepositoryHive {
  static const String _boxName = 'my_schedule';
  static const String _key = 'v1';

  late Box<String> _box;

  Future<void> init() async {
    _box = await Hive.openBox<String>(_boxName);
  }

  /// Returns the persisted [Schedule], or `null` if none has been saved yet.
  Schedule? load() {
    final raw = _box.get(_key);
    if (raw == null) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final bytes =
          Uint8List.fromList(base64Url.decode(map['bitmaskB64'] as String));
      return Schedule(
        username: map['username'] as String,
        bitmask: WeeklyBitmask.fromBytes(bytes),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> save(Schedule schedule) async {
    final map = {
      'username': schedule.username,
      'bitmaskB64': base64Url.encode(schedule.bitmask.bytes),
    };
    await _box.put(_key, jsonEncode(map));
  }
}
