import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/theme_mode_menu_button.dart';
import '../application/friends_controller.dart';
import '../domain/friend_profile.dart';
import 'import_friend_sheet.dart';

class FriendsScreen extends ConsumerWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friends = ref.watch(friendsProvider);
    final notifier = ref.read(friendsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        actions: [
          const ThemeModeMenuButton(),
          if (friends.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Remove all friends',
              onPressed: () => _confirmRemoveAll(context, notifier),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showImportFriendSheet(context),
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Import'),
      ),
      body: friends.isEmpty
          ? const EmptyState(
              icon: Icons.group_outlined,
              title: 'No friends yet',
              subtitle:
                  'Import a friend\'s share string to see their schedule.',
            )
          : ListView.separated(
              padding: const EdgeInsets.only(bottom: 88),
              itemCount: friends.length,
              separatorBuilder: (context, index) =>
                const Divider(height: 1, indent: 72),
              itemBuilder: (context, index) {
                final friend = friends[index];
                return _FriendTile(
                  friend: friend,
                  onRemove: () => notifier.removeFriend(friend.id),
                );
              },
            ),
    );
  }

  void _confirmRemoveAll(BuildContext context, FriendsNotifier notifier) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove all friends?'),
        content: const Text(
            'All imported friend schedules will be deleted from this device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              notifier.removeAll();
            },
            child: const Text('Remove all'),
          ),
        ],
      ),
    );
  }
}

class _FriendTile extends StatelessWidget {
  final FriendProfile friend;
  final VoidCallback onRemove;

  const _FriendTile({required this.friend, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final initial =
        friend.username.isNotEmpty ? friend.username[0].toUpperCase() : '?';

    return Dismissible(
      key: ValueKey(friend.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        color: cs.errorContainer,
        padding: const EdgeInsets.only(right: 24),
        child: Icon(Icons.delete_outline, color: cs.error),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('Remove ${friend.username}?'),
            content: const Text(
                'This friend\'s schedule will be removed from your device.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Remove'),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => onRemove(),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: cs.primaryContainer,
          child: Text(
            initial,
            style: TextStyle(
                color: cs.onPrimaryContainer, fontWeight: FontWeight.w700),
          ),
        ),
        title: Text(friend.username),
        subtitle: Text(
          _relativeTime(friend.importedAt),
          style: TextStyle(color: cs.outline, fontSize: 12),
        ),
        trailing: IconButton(
          icon: Icon(Icons.close, size: 18, color: cs.outline),
          tooltip: 'Remove',
          onPressed: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: Text('Remove ${friend.username}?'),
                content: const Text(
                    'This friend\'s schedule will be removed from your device.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Remove'),
                  ),
                ],
              ),
            );
            if (confirmed == true) onRemove();
          },
        ),
      ),
    );
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays >= 1) return 'Imported ${diff.inDays}d ago';
    if (diff.inHours >= 1) return 'Imported ${diff.inHours}h ago';
    if (diff.inMinutes >= 1) return 'Imported ${diff.inMinutes}m ago';
    return 'Imported just now';
  }
}
