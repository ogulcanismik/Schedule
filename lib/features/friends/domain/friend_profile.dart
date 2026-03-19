import 'dart:convert';
import 'dart:typed_data';

import '../../schedule/domain/schedule.dart';
import '../../schedule/domain/weekly_bitmask.dart';

/// An imported friend: their display name + decoded weekly schedule.
class FriendProfile {
  /// Unique ID (milliseconds since epoch as string, sufficient for local storage).
  final String id;
  final String username;
  final WeeklyBitmask bitmask;
  final DateTime importedAt;

  const FriendProfile({
    required this.id,
    required this.username,
    required this.bitmask,
    required this.importedAt,
  });

  Schedule toSchedule() =>
      Schedule(username: username, bitmask: bitmask);

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'bitmaskB64': base64Url.encode(bitmask.bytes),
        'importedAt': importedAt.toIso8601String(),
      };

  factory FriendProfile.fromJson(Map<String, dynamic> json) {
    final bitmaskBytes =
        Uint8List.fromList(base64Url.decode(json['bitmaskB64'] as String));
    return FriendProfile(
      id: json['id'] as String,
      username: json['username'] as String,
      bitmask: WeeklyBitmask.fromBytes(bitmaskBytes),
      importedAt: DateTime.parse(json['importedAt'] as String),
    );
  }

  /// Convenience: build a [FriendProfile] from a decoded share string.
  factory FriendProfile.fromShareString(String shareString) {
    final schedule = Schedule.fromShareString(shareString);
    return FriendProfile(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      username: schedule.username,
      bitmask: schedule.bitmask,
      importedAt: DateTime.now(),
    );
  }

  FriendProfile copyWith({
    String? id,
    String? username,
    WeeklyBitmask? bitmask,
    DateTime? importedAt,
  }) =>
      FriendProfile(
        id: id ?? this.id,
        username: username ?? this.username,
        bitmask: bitmask ?? this.bitmask,
        importedAt: importedAt ?? this.importedAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is FriendProfile && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'FriendProfile(id: $id, username: $username)';
}
