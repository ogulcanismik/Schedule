import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:unisync/app/app.dart';
import 'package:unisync/core/theme/theme_mode_provider.dart';
import 'package:unisync/core/theme/theme_settings_repository.dart';
import 'package:unisync/features/friends/application/friends_controller.dart';
import 'package:unisync/features/friends/infrastructure/friends_repository_hive.dart';
import 'package:unisync/features/schedule/application/schedule_notifier.dart';
import 'package:unisync/features/schedule/infrastructure/schedule_repository_hive.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App shell shows My Schedule on first tab', (tester) async {
    final tempDir = Directory.systemTemp.createTempSync('unisync_widget_test');
    Hive.init(tempDir.path);

    final friendsRepo = FriendsRepositoryHive();
    await friendsRepo.init();
    final scheduleRepo = ScheduleRepositoryHive();
    await scheduleRepo.init();

    final themeRepo = ThemeSettingsRepository();
    await themeRepo.init();

    addTearDown(() async {
      await Hive.close();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          friendsRepositoryProvider.overrideWithValue(friendsRepo),
          scheduleRepositoryProvider.overrideWithValue(scheduleRepo),
          themeSettingsRepositoryProvider.overrideWithValue(themeRepo),
        ],
        child: const UniSyncApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('My Schedule'), findsOneWidget);
  });
}
