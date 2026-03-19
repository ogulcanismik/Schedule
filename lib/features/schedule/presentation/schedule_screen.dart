import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/schedule_grid_widget.dart';
import '../../../core/widgets/theme_mode_menu_button.dart';
import '../application/schedule_notifier.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  late final TextEditingController _usernameCtrl;
  late final FocusNode _usernameFocus;

  @override
  void initState() {
    super.initState();
    final schedule = ref.read(scheduleProvider);
    _usernameCtrl = TextEditingController(text: schedule.username);
    _usernameFocus = FocusNode()
      ..addListener(() {
        if (!_usernameFocus.hasFocus) {
          ref.read(scheduleProvider.notifier).updateUsername(_usernameCtrl.text);
        }
      });
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _usernameFocus.dispose();
    super.dispose();
  }

  void _copyShareString(BuildContext context, String shareString) {
    Clipboard.setData(ClipboardData(text: shareString));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share string copied to clipboard'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _confirmClear(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear schedule?'),
        content: const Text('All busy slots will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(scheduleProvider.notifier).clearSchedule();
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final schedule = ref.watch(scheduleProvider);
    final notifier = ref.read(scheduleProvider.notifier);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Schedule'),
        actions: [
          const ThemeModeMenuButton(),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Clear all slots',
            onPressed: () => _confirmClear(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Username card
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your name',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _usernameCtrl,
                      focusNode: _usernameFocus,
                      decoration: const InputDecoration(
                        hintText: 'Enter your display name',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (v) =>
                          ref.read(scheduleProvider.notifier).updateUsername(v),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Tap-hint
            Row(
              children: [
                Icon(Icons.touch_app_outlined,
                    size: 14, color: cs.outlineVariant),
                const SizedBox(width: 4),
                Text(
                  'Tap slots to mark busy (8:00–20:00)',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: cs.outlineVariant),
                ),
                const Spacer(),
                _Legend(color: cs.primary, label: 'Busy'),
                const SizedBox(width: 12),
                _Legend(
                    color: cs.surfaceContainerHighest, label: 'Free'),
              ],
            ),
            const SizedBox(height: 8),
            // Schedule grid
            ScheduleGridWidget(
              bitmask: schedule.bitmask,
              onTap: (d, s) =>
                  notifier.toggleSlot(dayIndex: d, slotIndex: s),
            ),
            const SizedBox(height: 20),
            // Share card
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.share_outlined,
                            size: 16, color: cs.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Share string',
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(
                                color: cs.primary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.copy_outlined),
                          tooltip: 'Copy to clipboard',
                          onPressed: () => _copyShareString(
                              context, schedule.toShareString()),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SelectableText(
                        schedule.toShareString(),
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Paste this into UniSync on any device to share your schedule.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.outline,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }
}
