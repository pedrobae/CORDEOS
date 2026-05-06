import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cordeos/helpers/codes.dart';
import 'package:cordeos/models/domain/user.dart';
import 'package:cordeos/models/dtos/playlist_dto.dart';
import 'package:cordeos/models/dtos/schedule_dto.dart';

enum ScheduleState { draft, published, completed }

class Schedule {
  final int id;
  final String? firebaseId;
  final String ownerFirebaseId;
  final String name;
  final DateTime date;
  final String location;
  final String? roomVenue;
  final String? annotations;
  final int playlistId;
  final Map<int, Role> roles;
  final List<String> collaborators;
  final String shareCode;
  bool isPublic;

  Schedule({
    required this.id,
    this.firebaseId,
    required this.ownerFirebaseId,
    required this.name,
    required this.date,
    required this.location,
    this.roomVenue,
    required this.playlistId,
    required this.roles,
    required this.collaborators,
    this.annotations,
    required this.shareCode,
    this.isPublic = false,
  });

  ScheduleState get scheduleState {
    if (!isPublic) {
      return ScheduleState.draft;
    } else {
      if (DateTime.now().year > date.year ||
          (DateTime.now().year == date.year &&
              DateTime.now().month > date.month) ||
          (DateTime.now().year == date.year &&
              DateTime.now().month == date.month &&
              DateTime.now().day > date.day)) {
        return ScheduleState.completed;
      } else {
        return ScheduleState.published;
      }
    }
  }

  factory Schedule.fromSqlite(Map<String, dynamic> map, List<Role> roles) {
    return Schedule(
      id: map['id'] as int,
      firebaseId: map['firebase_id'] as String?,
      ownerFirebaseId: map['owner_firebase_id'] as String,
      name: map['name'] as String,
      date: DateTime.parse(map['date'] as String),
      location: map['location'] as String,
      roomVenue: map['room_venue'] as String?,
      playlistId: map['playlist_id'] as int,
      roles: Map.fromEntries(roles.map((r) => MapEntry(r.id, r))),
      collaborators: (map['collaborators'] is String)
          ? (map['collaborators'] as String).split(',')
          : [],
      annotations: map['annotations'] as String?,
      shareCode: map['share_code'] as String? ?? generateShareCode(),
      isPublic: (map['is_public'] as int?) == 1,
    );
  }

  Map<String, dynamic> toSqlite() {
    return {
      'firebase_id': firebaseId,
      'owner_firebase_id': ownerFirebaseId,
      'name': name,
      'date': date.toIso8601String(),
      'location': location,
      'room_venue': roomVenue,
      'playlist_id': playlistId,
      'annotations': annotations,
      'share_code': shareCode,
      'is_public': isPublic ? 1 : 0,
      'collaborators': collaborators.join(','),
    };
  }

  Schedule copyWith({
    int? id,
    String? firebaseId,
    String? ownerFirebaseId,
    String? name,
    DateTime? date,
    String? location,
    String? roomVenue,
    int? playlistId,
    Map<int, Role>? roles,
    String? annotations,
    String? shareCode,
    bool? isPublic,
    List<String>? collaborators,
  }) {
    return Schedule(
      id: id ?? this.id,
      firebaseId: firebaseId ?? this.firebaseId,
      ownerFirebaseId: ownerFirebaseId ?? this.ownerFirebaseId,
      name: name ?? this.name,
      date: date ?? this.date,
      location: location ?? this.location,
      roomVenue: roomVenue ?? this.roomVenue,
      playlistId: playlistId ?? this.playlistId,
      roles: roles ?? this.roles,
      annotations: annotations ?? this.annotations,
      shareCode: shareCode ?? this.shareCode,
      isPublic: isPublic ?? this.isPublic,
      collaborators: collaborators ?? this.collaborators,
    );
  }

  ScheduleDto toDto(PlaylistDto playlist) {
    return ScheduleDto(
      firebaseId: firebaseId,
      ownerFirebaseId: ownerFirebaseId,
      name: name,
      datetime: Timestamp.fromDate(date),
      location: location,
      roomVenue: roomVenue,
      shareCode: shareCode,
      playlist: playlist,
      roles: roles.values.map((role) => role.toDto()).toList(),
      collaborators: collaborators,
    );
  }

  Schedule mergeWith(Schedule other) {
    bool localIsNewer = date.isAfter(other.date);

    final Schedule source = localIsNewer ? this : other;
    final Schedule target = localIsNewer ? other : this;

    final collab = source.collaborators.toSet();
    collab.addAll(target.collaborators);

    return Schedule(
      id: id,
      firebaseId: source.firebaseId ?? target.firebaseId,
      ownerFirebaseId: source.ownerFirebaseId,
      name: source.name.isNotEmpty ? source.name : target.name,
      date: source.date != DateTime(1970) ? source.date : target.date,
      location: source.location.isNotEmpty ? source.location : target.location,
      roomVenue: (source.roomVenue != null && source.roomVenue!.isNotEmpty)
          ? source.roomVenue
          : target.roomVenue,
      playlistId: source.playlistId,
      roles: source.roles.isNotEmpty ? source.roles : target.roles,
      shareCode: source.shareCode,
      isPublic: true,
      collaborators: collab.toList(),
    );
  }

  void addRole(Role role) {
    int id = -1;
    bool foundValidID = false;
    while (!foundValidID) {
      if (!roles.keys.contains(-1)) {
        foundValidID = true;
      } else {
        id--;
      }
    }
    roles[id] = role.copyWith(id: id);
  }
}

class Role {
  final int id;
  String name;
  final List<User> users;

  Role({required this.id, required this.name, required this.users});

  factory Role.fromSqlite(Map<String, dynamic> map, List<User> users) {
    return Role(
      id: map['id'] as int,
      name: map['name'] as String,
      users: users,
    );
  }

  Map<String, dynamic> toSqlite(int scheduleId) {
    return {'name': name, 'schedule_id': scheduleId};
  }

  RoleDto toDto() {
    return RoleDto(
      users: users.map((user) => user.toDto()).toList(),
      name: name,
    );
  }

  Role copyWith({int? id, String? name, List<User>? users}) {
    return Role(
      id: id ?? this.id,
      name: name ?? this.name,
      users: users ?? this.users,
    );
  }
}
