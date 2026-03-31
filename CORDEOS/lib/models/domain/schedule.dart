import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cordeos/helpers/codes.dart';
import 'package:cordeos/models/domain/user.dart';
import 'package:cordeos/models/dtos/playlist_dto.dart';
import 'package:cordeos/models/dtos/schedule_dto.dart';
import 'package:flutter/material.dart';

enum ScheduleState { draft, published, completed }

class Schedule {
  final int id;
  final String? firebaseId;
  final String ownerFirebaseId;
  final String name;
  final DateTime date;
  final TimeOfDay time;
  final String location;
  final String? roomVenue;
  final String? annotations;
  final int playlistId;
  final List<Role> roles;
  final String shareCode;
  bool isPublic;

  Schedule({
    required this.id,
    this.firebaseId,
    required this.ownerFirebaseId,
    required this.name,
    required this.date,
    required this.time,
    required this.location,
    this.roomVenue,
    required this.playlistId,
    required this.roles,
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
      time: TimeOfDay(
        hour: int.parse((map['time'] as String).split(':')[0]),
        minute: int.parse((map['time'] as String).split(':')[1]),
      ),
      location: map['location'] as String,
      roomVenue: map['room_venue'] as String?,
      playlistId: map['playlist_id'] as int,
      roles: roles,
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
      'time':
          '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
      'location': location,
      'room_venue': roomVenue,
      'playlist_id': playlistId,
      'annotations': annotations,
      'share_code': shareCode,
      'is_public': isPublic ? 1 : 0,
    };
  }

  Schedule copyWith({
    int? id,
    String? firebaseId,
    String? ownerFirebaseId,
    String? name,
    DateTime? date,
    TimeOfDay? time,
    String? location,
    String? roomVenue,
    int? playlistId,
    List<Role>? roles,
    String? annotations,
    String? shareCode,
    bool? isPublic,
  }) {
    return Schedule(
      id: id ?? this.id,
      firebaseId: firebaseId ?? this.firebaseId,
      ownerFirebaseId: ownerFirebaseId ?? this.ownerFirebaseId,
      name: name ?? this.name,
      date: date ?? this.date,
      time: time ?? this.time,
      location: location ?? this.location,
      roomVenue: roomVenue ?? this.roomVenue,
      playlistId: playlistId ?? this.playlistId,
      roles: roles ?? this.roles,
      annotations: annotations ?? this.annotations,
      shareCode: shareCode ?? this.shareCode,
      isPublic: isPublic ?? this.isPublic,
    );
  }

  ScheduleDto toDto(PlaylistDto playlist) {
    final dateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    return ScheduleDto(
      firebaseId: firebaseId,
      ownerFirebaseId: ownerFirebaseId,
      name: name,
      datetime: Timestamp.fromDate(dateTime),
      location: location,
      roomVenue: roomVenue,
      shareCode: shareCode,
      playlist: playlist,
      roles: roles.map((role) => role.toDto()).toList(),
    );
  }

  Schedule mergeWith(Schedule other) {
    final localDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    final otherDateTime = DateTime(
      other.date.year,
      other.date.month,
      other.date.day,
      other.time.hour,
      other.time.minute,
    );

    bool localIsNewer = localDateTime.isAfter(otherDateTime);

    final Schedule source = localIsNewer ? this : other;
    final Schedule target = localIsNewer ? other : this;

    return Schedule(
      id: id,
      firebaseId: source.firebaseId ?? target.firebaseId,
      ownerFirebaseId: source.ownerFirebaseId,
      name: source.name.isNotEmpty ? source.name : target.name,
      date: source.date != DateTime(1970) ? source.date : target.date,
      time: source.time != TimeOfDay(hour: 0, minute: 0)
          ? source.time
          : target.time,
      location: source.location.isNotEmpty ? source.location : target.location,
      roomVenue: (source.roomVenue != null && source.roomVenue!.isNotEmpty)
          ? source.roomVenue
          : target.roomVenue,
      playlistId: source.playlistId,
      roles: source.roles.isNotEmpty ? source.roles : target.roles,
      shareCode: source.shareCode,
      isPublic: true,
    );
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
