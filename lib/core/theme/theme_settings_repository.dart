import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Persists [ThemeMode] in Hive (`app_settings` box).
class ThemeSettingsRepository {
  static const String _boxName = 'app_settings';
  static const String _keyThemeMode = 'theme_mode';

  late Box<dynamic> _box;

  Future<void> init() async {
    _box = await Hive.openBox<dynamic>(_boxName);
  }

  ThemeMode loadThemeMode() {
    final raw = _box.get(_keyThemeMode);
    if (raw is! int) return ThemeMode.system;
    if (raw < 0 || raw >= ThemeMode.values.length) {
      return ThemeMode.system;
    }
    return ThemeMode.values[raw];
  }

  Future<void> saveThemeMode(ThemeMode mode) async {
    await _box.put(_keyThemeMode, mode.index);
  }
}
