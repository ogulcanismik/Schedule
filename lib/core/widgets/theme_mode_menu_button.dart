import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/theme_mode_provider.dart';

/// AppBar action: choose light, dark, or system theme (persisted).
class ThemeModeMenuButton extends ConsumerWidget {
  const ThemeModeMenuButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final notifier = ref.read(themeModeProvider.notifier);

    return PopupMenuButton<ThemeMode>(
      tooltip: 'Theme',
      icon: Icon(_iconFor(mode)),
      onSelected: notifier.setThemeMode,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: ThemeMode.system,
          child: ListTile(
            leading: Icon(
              Icons.brightness_auto_outlined,
              color: mode == ThemeMode.system
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            title: const Text('System'),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: ThemeMode.light,
          child: ListTile(
            leading: Icon(
              Icons.light_mode_outlined,
              color: mode == ThemeMode.light
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            title: const Text('Light'),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: ThemeMode.dark,
          child: ListTile(
            leading: Icon(
              Icons.dark_mode_outlined,
              color: mode == ThemeMode.dark
                  ? Theme.of(context).colorScheme.primary
                  : null,
            ),
            title: const Text('Dark'),
            dense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  static IconData _iconFor(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode_outlined;
      case ThemeMode.dark:
        return Icons.dark_mode_outlined;
      case ThemeMode.system:
        return Icons.brightness_auto_outlined;
    }
  }
}
