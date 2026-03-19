import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/friend_profile.dart';
import '../infrastructure/friends_repository_hive.dart';

/// Provides the initialised [FriendsRepositoryHive] instance.
///
/// Must be overridden in [ProviderScope] after Hive has been initialised.
final friendsRepositoryProvider = Provider<FriendsRepositoryHive>((ref) {
  throw StateError(
    'FriendsRepositoryHive must be overridden after Hive.init(). '
    'Use ProviderScope(overrides: [...]) in main.',
  );
});

/// Notifier that manages the ordered list of imported friend profiles.
class FriendsNotifier extends Notifier<List<FriendProfile>> {
  FriendsRepositoryHive get _repo => ref.read(friendsRepositoryProvider);

  @override
  List<FriendProfile> build() => ref.watch(friendsRepositoryProvider).getAll();

  /// Imports a friend from a share string.
  ///
  /// Throws [FormatException] if [shareString] is invalid.
  Future<void> importFromShareString(String shareString) async {
    final profile = FriendProfile.fromShareString(shareString);
    await _repo.save(profile);
    state = _repo.getAll();
  }

  Future<void> removeFriend(String id) async {
    await _repo.delete(id);
    state = _repo.getAll();
  }

  Future<void> removeAll() async {
    await _repo.deleteAll();
    state = [];
  }
}

final friendsProvider =
    NotifierProvider<FriendsNotifier, List<FriendProfile>>(
  FriendsNotifier.new,
);
