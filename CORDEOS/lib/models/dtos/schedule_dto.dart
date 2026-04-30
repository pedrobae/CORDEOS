import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cordeos/helpers/codes.dart';
import 'package:cordeos/models/domain/playlist/playlist_item.dart';
import 'package:cordeos/models/domain/schedule.dart';
import 'package:cordeos/models/dtos/playlist_dto.dart';
import 'package:cordeos/models/dtos/user_dto.dart';

class ScheduleDto {
  final String? firebaseId;
  final String ownerFirebaseId;
  final String name;
  final Timestamp datetime;
  final String location;
  final String? roomVenue;
  final PlaylistDto playlist;
  final List<RoleDto> roles;
  final String shareCode;
  final List<String> collaborators;

  ScheduleDto({
    this.firebaseId,
    required this.ownerFirebaseId,
    required this.name,
    required this.datetime,
    required this.location,
    this.roomVenue,
    required this.playlist,
    required this.roles,
    required this.shareCode,
    required this.collaborators,
  });

  List<PlaylistItem> get items {
    List<PlaylistItem> items = [];
    int position = 0;
    for (var key in playlist.itemOrder) {
      final split = key.split(':');
      if (split.length != 2) continue;
      final typeStr = split[0];
      final contentId = split[1];

      if (typeStr == 'v') {
        final version = playlist.versions[contentId];

        items.add(
          PlaylistItem(
            type: PlaylistItemType.version,
            firebaseContentId: version!.firebaseId,
            position: position,
            duration: Duration(seconds: version.duration),
          ),
        );
        position++;
      } else if (typeStr == 'f') {
        final flow = playlist.flowItems[contentId]!;

        items.add(
          PlaylistItem(
            type: PlaylistItemType.flowItem,
            firebaseContentId: contentId,
            position: position,
            duration: Duration(seconds: flow['duration'] as int),
          ),
        );
        position++;
      }
    }
    return items;
  }

  factory ScheduleDto.fromFirestore(Map<String, dynamic> json, String id) {
    return ScheduleDto(
      firebaseId: id,
      ownerFirebaseId: json['ownerId'] as String,
      name: json['name'] as String,
      datetime: json['datetime'] as Timestamp,
      location: json['location'] as String,
      roomVenue: json['roomVenue'] as String?,
      playlist: PlaylistDto.fromFirestore(
        json['playlist'] as Map<String, dynamic>,
      ),
      roles: (json['roles'] as List<dynamic>)
          .map((role) => RoleDto.fromFirestore(role as Map<String, dynamic>))
          .toList(),
      shareCode: json['shareCode'] as String? ?? generateShareCode(),
      collaborators: (json['collaborators'] as List<dynamic>? ?? [])
          .map((collab) => collab as String)
          .toList(),
    );
  }

  Map<String, dynamic> toFirestore() {
    final collab = <String>{};
    List<String> roleUserIDs = roles
        .expand((role) => role.users.expand((user) => [user.firebaseId ?? '']))
        .toList();

    collab.addAll(roleUserIDs);
    collab.add(ownerFirebaseId); // Ensure owner is included as a collaborator
    collab.remove(''); // Remove any empty IDs

    return {
      'ownerId': ownerFirebaseId,
      'name': name,
      'datetime': datetime,
      'location': location,
      'roomVenue': roomVenue,
      'playlist': playlist.toFirestore(),
      'roles': roles.map((role) => role.toFirestore()).toList(),
      'shareCode': shareCode,
      'collaborators': collab.toList(),
    };
  }

  Map<String, dynamic> toCache() {
    final collab = <String>{};
    List<String> roleUserIDs = roles
        .expand((role) => role.users.expand((user) => [user.firebaseId ?? '']))
        .toList();

    collab.addAll(roleUserIDs);
    collab.add(ownerFirebaseId); // Ensure owner is included as a collaborator
    collab.remove(''); // Remove any empty IDs

    return {
      'firebaseId': firebaseId,
      'ownerId': ownerFirebaseId,
      'name': name,
      'datetime': datetime.millisecondsSinceEpoch,
      'location': location,
      'roomVenue': roomVenue,
      'playlist': playlist.toCache(),
      'roles': roles.map((role) => role.toFirestore()).toList(),
      'shareCode': shareCode,
      'collaborators': collab.toList(),
    };
  }

  Schedule toDomain({required int playlistLocalId}) {
    final dateTime = datetime.toDate();
    final schedule = Schedule(
      id: -1, // ID will be set by local database
      ownerFirebaseId: ownerFirebaseId,
      firebaseId: firebaseId,
      name: name,
      date: dateTime,
      location: location,
      roomVenue: roomVenue,
      playlistId: playlistLocalId,
      roles: {},
      shareCode: shareCode,
      collaborators: collaborators,
      isPublic:
          true, // All schedules on firestore are considered published, access is controlled by share code and collaborators list
    );

    int i = -1;
    for (var roleDto in roles) {
      final role = roleDto.toDomain(i);
      schedule.roles[i] = role;
      i--;
    }

    return schedule;
  }

  ScheduleDto copyWith({
    String? firebaseId,
    String? name,
    String? ownerFirebaseId,
    Timestamp? datetime,
    String? location,
    String? roomVenue,
    PlaylistDto? playlist,
    List<RoleDto>? roles,
    String? shareCode,
    List<String>? collaborators,
  }) {
    return ScheduleDto(
      firebaseId: firebaseId ?? this.firebaseId,
      ownerFirebaseId: ownerFirebaseId ?? this.ownerFirebaseId,
      name: name ?? this.name,
      datetime: datetime ?? this.datetime,
      location: location ?? this.location,
      roomVenue: roomVenue ?? this.roomVenue,
      playlist: playlist ?? this.playlist,
      roles: roles ?? this.roles,
      shareCode: shareCode ?? this.shareCode,
      collaborators: collaborators ?? this.collaborators,
    );
  }
}

class RoleDto {
  String name;
  final List<UserDto> users;

  RoleDto({required this.name, required this.users});

  factory RoleDto.fromFirestore(Map<String, dynamic> json) {
    return RoleDto(
      name: json['name'] as String,
      users: (json['users'] as List<dynamic>)
          .map((userJson) => UserDto.fromSchedule(userJson))
          .toList(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'users': users.map((user) => user.toSchedule()).toList(),
    };
  }

  Role toDomain(int id) {
    final role = Role(
      id: id,
      name: name,
      users: users.map((user) => user.toDomain()).toList(),
    );
    return role;
  }
}
