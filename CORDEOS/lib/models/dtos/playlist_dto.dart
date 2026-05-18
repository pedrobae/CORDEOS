import 'package:cordeos/models/domain/playlist/playlist.dart';
import 'package:cordeos/models/domain/playlist/playlist_item.dart';
import 'package:cordeos/models/dtos/version_dto.dart';

class PlaylistDto {
  final String name;
  final List<String> itemOrder;
  final Map<String, Map<String, dynamic>> flowItems;
  final Map<String, VersionDto> versions;

  const PlaylistDto({
    required this.name,
    this.itemOrder = const [],
    this.flowItems = const {},
    this.versions = const {},
  });

  Duration getTotalDuration() {
    return flowItems.values.fold(
      Duration.zero,
      (a, b) =>
          a +
          (b['duration'] != null
              ? Duration(seconds: int.parse(b['duration']!))
              : Duration.zero),
    );
  }

  factory PlaylistDto.fromFirestore(Map<String, dynamic> json) {
    return PlaylistDto(
      name: json['name'] as String,
      itemOrder: (json['itemOrder'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      flowItems: (json['flowItems'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, (value as Map<String, dynamic>)),
      ),
      versions:
          (json['versions'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, VersionDto.fromFirestore(value, key)),
          ) ??
          {},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'itemOrder': itemOrder,
      'flowItems': flowItems,
      'versions': versions.map(
        (key, value) => MapEntry(key, value.toFirestore()),
      ),
    };
  }

  factory PlaylistDto.fromCache(Map<String, dynamic> json) {
    return PlaylistDto(
      name: json['name'] as String,
      itemOrder: (json['itemOrder'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      flowItems: (json['flowItems'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, (value as Map<String, dynamic>)),
      ),
      versions:
          (json['versions'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(key, VersionDto.fromCache(value)),
          ) ??
          {},
    );
  }

  Map<String, dynamic> toCache() {
    return {
      'name': name,
      'itemOrder': itemOrder,
      'flowItems': flowItems,
      'versions': versions.map((key, value) => MapEntry(key, value.toCache())),
    };
  }

  /// Method to convert PlaylistDto to Playlist domain model items must be inserted first
  Playlist toDomain(int ownerLocalId) {
    return Playlist(
      id: -1, // ID local será atribuído pelo banco de dados local
      name: name,
      createdBy: ownerLocalId,
      items: getPlaylistItems(),
    );
  }

  void addVersions(List<VersionDto> newVersions) {
    for (var version in newVersions) {
      versions[version.firebaseId!] = version;
    }
  }

  void removeVersionByKey(String key) {
    versions.remove(key);
  }

  List<PlaylistItem> getPlaylistItems() {
    List<PlaylistItem> playlistItems = [];
    int position = 0;
    for (var itemId in itemOrder) {
      final id = itemId.split(':');
      if (id[0] == 'f') {
        playlistItems.add(
          PlaylistItem(
            id: -1,
            firebaseContentId: id[1],
            position: position++,
            type: PlaylistItemType.flowItem,
            duration: Duration(
              seconds: flowItems[id[1]]?['duration'] as int? ?? 0,
            ),
          ),
        );
      } else if (id[0] == 'v') {
        playlistItems.add(
          PlaylistItem(
            id: -1,
            firebaseContentId: id[1],
            type: PlaylistItemType.version,
            position: position++,
            duration: Duration(seconds: versions[id[1]]?.duration ?? 0),
          ),
        );
      }
    }
    return playlistItems;
  }

  PlaylistDto mergeVersions(
    Map<String, String?>? versionsKeys,
    Map<String, Map<int, CloudVersionNote>>? versionsNotes,
  ) {
    if (versionsKeys == null || versionsNotes == null) return this;
    final newVersions = <String, VersionDto>{};
    for (final version in versions.values) {
      newVersions[version.firebaseId!] = version
          .mergeNotes(versionsNotes[version.firebaseId!]!)
          .copyWith(overwriteKey: versionsKeys[version.firebaseId!]);
    }

    return this.copyWith(versions: newVersions);
  }

  PlaylistDto copyWith({
    String? name,
    List<String>? itemOrder,
    Map<String, Map<String, dynamic>>? flowItems,
    Map<String, VersionDto>? versions,
  }) {
    return PlaylistDto(
      name: name ?? this.name,
      itemOrder: itemOrder ?? this.itemOrder,
      flowItems: flowItems ?? this.flowItems,
      versions: versions ?? this.versions,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PlaylistDto &&
        this.name == other.name &&
        this.versions.values.every(
          (version) => other.versions.containsValue(version),
        );
  }
}
