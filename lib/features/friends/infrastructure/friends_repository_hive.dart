import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../domain/friend_profile.dart';

/// Persists [FriendProfile] objects in a local Hive box as JSON strings.
///
/// No code generation required: each entry is stored as a raw JSON string
/// keyed by [FriendProfile.id].
class FriendsRepositoryHive {
  static const String _boxName = 'friends';

  late Box<String> _box;

  Future<void> init() async {
    _box = await Hive.openBox<String>(_boxName);
  }

  List<FriendProfile> getAll() {
    return _box.values
        .map((json) => FriendProfile.fromJson(
              jsonDecode(json) as Map<String, dynamic>,
            ))
        .toList()
      ..sort((a, b) => b.importedAt.compareTo(a.importedAt));
  }

  Future<void> save(FriendProfile profile) async {
    await _box.put(profile.id, jsonEncode(profile.toJson()));
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  Future<void> deleteAll() async {
    await _box.clear();
  }

  bool contains(String id) => _box.containsKey(id);
}
