import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme_settings_repository.dart';

/// Injected after [ThemeSettingsRepository.init] in [main.dart].
final themeSettingsRepositoryProvider = Provider<ThemeSettingsRepository>((ref) {
  throw StateError(
    'ThemeSettingsRepository must be overridden in ProviderScope after Hive.init().',
  );
});

class ThemeModeNotifier extends Notifier<ThemeMode> {
  ThemeSettingsRepository get _repo =>
      ref.read(themeSettingsRepositoryProvider);

  @override
  ThemeMode build() => _repo.loadThemeMode();

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _repo.saveThemeMode(mode);
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);
