import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../friends/application/friends_controller.dart';
import '../../friends/domain/friend_profile.dart';

/// Holds the set of friend IDs currently included in the overlay comparison.
///
/// - Initial state: every imported friend is selected.
/// - When a new friend is imported, they are auto-selected.
/// - When a friend is deleted, they are automatically removed from the set.
/// - Manual toggles by the user are preserved across friend list updates.
class OverlaySelectionNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    // React to friend list changes WITHOUT re-running build (which would
    // reset user selections). ref.listen callbacks run after build returns,
    // so it is safe to mutate `state` there.
    ref.listen<List<FriendProfile>>(
      friendsProvider,
      (previous, next) {
        final currentIds = next.map((f) => f.id).toSet();
        final previousIds = previous?.map((f) => f.id).toSet() ?? {};

        // Remove IDs of deleted friends, auto-select newly added friends.
        final retained = state.intersection(currentIds);
        final newIds = currentIds.difference(previousIds);
        state = {...retained, ...newIds};
      },
    );

    // Initial state: all currently imported friends selected.
    return ref.read(friendsProvider).map((f) => f.id).toSet();
  }

  /// Toggles a single friend in or out of the overlay.
  void toggle(String id) {
    final updated = Set<String>.from(state);
    if (updated.contains(id)) {
      updated.remove(id);
    } else {
      updated.add(id);
    }
    state = updated;
  }

  /// Selects every currently imported friend.
  void selectAll() {
    state = ref.read(friendsProvider).map((f) => f.id).toSet();
  }

  /// Deselects all friends (overlay shows only the user's own schedule).
  void selectNone() => state = {};
}

final selectedFriendIdsProvider =
    NotifierProvider<OverlaySelectionNotifier, Set<String>>(
  OverlaySelectionNotifier.new,
);
