import 'package:cordeos/helpers/codes.dart';
import 'package:cordeos/utils/date_utils.dart';

class FlowItem {
  final int? id;
  final String firebaseId;
  final int playlistId;
  final String title;
  String contentText;
  final Duration duration;
  final int position;

  FlowItem({
    this.id,
    required this.firebaseId,
    required this.playlistId,
    required this.title,
    required this.contentText,
    required this.duration,
    required this.position,
  });

  String get chordPro {
    return '{comment: $title - ${DateTimeUtils.formatDuration(duration)}\n{comment: $contentText}\n';
  }

  String get holyrics {
    return '//$title - ${DateTimeUtils.formatDuration(duration)}\n//$contentText\n';
  }

  factory FlowItem.fromSqlite(Map<String, dynamic> row) {
    return FlowItem(
      id: row['id'] as int?,
      firebaseId: row['firebase_id'] as String? ?? generateFirebaseId(),
      playlistId: row['playlist_id'],
      duration: Duration(seconds: row['duration'] ?? 0),
      title: row['title'],
      contentText: row['content'],
      position: row['position'],
    );
  }

  factory FlowItem.fromFirestore(
    Map<String, dynamic> json, {
    int? id,
    String? firebaseId,
    required int playlistId,
  }) {
    return FlowItem(
      id: id,
      playlistId: playlistId,
      firebaseId: json['firebaseId'] ?? firebaseId ?? generateFirebaseId(),
      duration: json['duration'] != null
          ? Duration(seconds: json['duration'])
          : Duration.zero,
      title: json['title'],
      contentText: json['contentText'],
      position: json['position'] ?? 0,
    );
  }

  Map<String, dynamic> toSQLite() {
    return {
      'id': id,
      'firebase_id': firebaseId,
      'playlist_id': playlistId,
      'title': title,
      'content': contentText,
      'position': position,
      'duration': duration.inSeconds,
    };
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'contentText': contentText,
      'firebaseId': firebaseId,
      'position': position,
      'duration': duration.inSeconds,
    };
  }

  FlowItem copyWith({
    String? firebaseId,
    int? playlistId,
    String? title,
    String? contentText,
    Duration? duration,
    int? position,
  }) {
    return FlowItem(
      firebaseId: firebaseId ?? this.firebaseId,
      playlistId: playlistId ?? this.playlistId,
      title: title ?? this.title,
      contentText: contentText ?? this.title,
      duration: duration ?? this.duration,
      position: position ?? this.position,
    );
  }
}
