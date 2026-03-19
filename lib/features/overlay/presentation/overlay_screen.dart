import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/theme_mode_menu_button.dart';
import '../../../core/widgets/schedule_grid_widget.dart';
import '../../friends/application/friends_controller.dart';
import '../../friends/presentation/import_friend_sheet.dart';
import '../../schedule/application/schedule_notifier.dart';
import '../../friends/domain/friend_profile.dart';
import '../application/overlay_selection.dart';
import '../domain/overlay_math.dart';

/// Derives an [OverlayResult] from the user's schedule + only the
/// friends currently selected in [selectedFriendIdsProvider].
final overlayResultProvider = Provider<OverlayResult>((ref) {
  final mySchedule = ref.watch(scheduleProvider);
  final friends = ref.watch(friendsProvider);
  final selectedIds = ref.watch(selectedFriendIdsProvider);

  final selectedFriends =
      friends.where((f) => selectedIds.contains(f.id)).toList();

  return OverlayMath.computeOverlay([
    OverlayParticipant(
      bitmask: mySchedule.bitmask,
      label: mySchedule.username,
      isUser: true,
    ),
    ...selectedFriends.map(
      (f) => OverlayParticipant(
        bitmask: f.bitmask,
        label: f.username,
      ),
    ),
  ]);
});

class OverlayScreen extends ConsumerWidget {
  const OverlayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friends = ref.watch(friendsProvider);
    final selectedIds = ref.watch(selectedFriendIdsProvider);
    final selectionNotifier = ref.read(selectedFriendIdsProvider.notifier);
    final overlay = ref.watch(overlayResultProvider);
    final cs = Theme.of(context).colorScheme;

    final allSelected =
        friends.isNotEmpty && friends.every((f) => selectedIds.contains(f.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Free Slots'),
        actions: [
          const ThemeModeMenuButton(),
          if (friends.isNotEmpty)
            TextButton(
              onPressed: allSelected
                  ? selectionNotifier.selectNone
                  : selectionNotifier.selectAll,
              child: Text(
                allSelected ? 'None' : 'All',
                style: TextStyle(color: cs.primary),
              ),
            ),
        ],
      ),
      body: friends.isEmpty
          ? EmptyState(
              icon: Icons.auto_awesome_outlined,
              title: 'No friends imported yet',
              subtitle:
                  'Import your friends\' schedules to find times when everyone is free.',
              actionLabel: 'Import a friend',
              onAction: () => showImportFriendSheet(context),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _FriendSelectorRow(
                    friends: friends,
                    selectedIds: selectedIds,
                    onToggle: selectionNotifier.toggle,
                  ),
                  const SizedBox(height: 16),
                  ScheduleGridWidget(
                    bitmask: ref.watch(scheduleProvider).bitmask,
                    overlay: overlay,
                    readOnly: true,
                  ),
                ],
              ),
            ),
    );
  }
}

class _FriendSelectorRow extends StatelessWidget {
  final List<FriendProfile> friends;
  final Set<String> selectedIds;
  final void Function(String id) onToggle;

  const _FriendSelectorRow({
    required this.friends,
    required this.selectedIds,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Compare with',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: cs.outline,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: friends.map((friend) {
              final isSelected = selectedIds.contains(friend.id);
              final initial = friend.username.isNotEmpty
                  ? friend.username[0].toUpperCase()
                  : '?';
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  selected: isSelected,
                  onSelected: (_) => onToggle(friend.id),
                  avatar: CircleAvatar(
                    radius: 10,
                    backgroundColor: isSelected
                        ? cs.primary
                        : cs.surfaceContainerHighest,
                    child: Text(
                      initial,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? cs.onPrimary
                            : cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                  label: Text(friend.username),
                  showCheckmark: false,
                  selectedColor: cs.primaryContainer,
                  backgroundColor: cs.surfaceContainerHighest,
                  side: BorderSide(
                    color: isSelected ? cs.primary : cs.outline.withAlpha(60),
                  ),
                  labelStyle: TextStyle(
                    color: isSelected ? cs.onPrimaryContainer : cs.onSurface,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
