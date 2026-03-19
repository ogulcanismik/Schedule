import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app/app.dart';
import 'core/theme/theme_mode_provider.dart';
import 'core/theme/theme_settings_repository.dart';
import 'features/friends/application/friends_controller.dart';
import 'features/friends/infrastructure/friends_repository_hive.dart';
import 'features/schedule/application/schedule_notifier.dart';
import 'features/schedule/infrastructure/schedule_repository_hive.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  final friendsRepo = FriendsRepositoryHive();
  await friendsRepo.init();

  final scheduleRepo = ScheduleRepositoryHive();
  await scheduleRepo.init();

  final themeSettingsRepo = ThemeSettingsRepository();
  await themeSettingsRepo.init();

  runApp(
    ProviderScope(
      overrides: [
        friendsRepositoryProvider.overrideWithValue(friendsRepo),
        scheduleRepositoryProvider.overrideWithValue(scheduleRepo),
        themeSettingsRepositoryProvider.overrideWithValue(themeSettingsRepo),
      ],
      child: const UniSyncApp(),
    ),
  );
}
