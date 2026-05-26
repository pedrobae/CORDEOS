/// Represents a content item in a playlist (cipher version or text section)
enum PlaylistItemType { version, flowItem }

extension PlaylistItemTypeExtension on PlaylistItemType {
  String get name {
    switch (this) {
      case PlaylistItemType.version:
        return 'cipherVersion';
      case PlaylistItemType.flowItem:
        return 'textSection';
    }
  }

  static PlaylistItemType getTypeByName(String name) {
    switch (name) {
      case 'cipherVersion':
        return PlaylistItemType.version;
      case 'textSection':
        return PlaylistItemType.flowItem;
      default:
        throw Exception('Not a PlaylistItemType name: $name');
    }
  }
}

class PlaylistItem {
  final PlaylistItemType type;
  final int id;
  final int? contentId; // when contentID is null - firebaseContentId is not
  Duration duration;
  String? firebaseContentId;
  int position;

  PlaylistItem({
    required this.id,
    required this.type,
    this.contentId,
    required this.position,
    required this.duration,
    this.firebaseContentId,
  });
  // Helper constructors
  PlaylistItem.version({
    required int versionId,
    required int position,
    required int id,
    Duration? duration,
    String? versionFirebaseId,
  }) : this(
         id: id,
         type: PlaylistItemType.version,
         contentId: versionId,
         position: position,
         duration: duration ?? Duration.zero,
         firebaseContentId: versionFirebaseId,
       );

  PlaylistItem.flowItem({
    required int flowItemId,
    required int position,
    required int id,
    Duration? duration,
    String? flowItemFirebaseId,
  }) : this(
         id: id,
         type: PlaylistItemType.flowItem,
         contentId: flowItemId,
         position: position,
         duration: duration ?? Duration.zero,
         firebaseContentId: flowItemFirebaseId,
       );

  // Type checking helpers
  bool get isFlowItem => type == PlaylistItemType.flowItem;

  PlaylistItem copyWith({
    PlaylistItemType? type,
    int? contentId,
    String? firebaseContentId,
    int? position,
    Duration? duration,
  }) {
    return PlaylistItem(
      id: id,
      type: type ?? this.type,
      contentId: contentId ?? this.contentId,
      firebaseContentId: firebaseContentId ?? this.firebaseContentId,
      position: position ?? this.position,
      duration: duration ?? this.duration,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlaylistItem &&
        other.type == type &&
        other.contentId == contentId &&
        other.position == position;
  }

  @override
  int get hashCode => type.hashCode ^ contentId.hashCode ^ position.hashCode;
}
