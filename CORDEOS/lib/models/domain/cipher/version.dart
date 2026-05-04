import 'package:cordeos/models/domain/cipher/cipher.dart';
import 'package:cordeos/models/domain/cipher/section.dart';
import 'package:cordeos/models/dtos/version_dto.dart';

enum VersionType { import, brandNew, cloud, local, playlist }

class Version {
  final int? id;
  final String? firebaseID;
  final int cipherID;
  final String versionName;
  final String? transposedKey;
  final List<int> songStructure;
  final int bpm;
  final Duration duration;
  final DateTime createdAt;
  final String? notes;

  const Version({
    this.id,
    this.firebaseID,
    required this.cipherID,
    this.versionName = 'Original',
    this.transposedKey,
    this.songStructure = const [],
    required this.bpm,
    required this.duration,
    required this.createdAt,
    this.notes,
  });

  factory Version.fromSqLite(Map<String, dynamic> row) {
    return Version(
      id: row['id'] as int?,
      firebaseID: row['firebase_id'] as String?,
      cipherID: row['cipher_id'] as int,
      songStructure: ((row['song_structure'] as String?) != null)
          ? (row['song_structure'] as String).split(',').map(int.parse).toList()
          : [],
      transposedKey: row['transposed_key'] as String?,
      versionName: row['version_name'] as String,
      bpm: row['bpm'] as int,
      duration: row['duration'] != null
          ? Duration(seconds: row['duration'])
          : Duration.zero,
      createdAt: row['created_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(row['created_at'])
          : DateTime.now(),
      notes: row['notes'],
    );
  }
  // To JSON for database (without content - sections handled separately)
  Map<String, dynamic> toSqLite() {
    final row = {
      'cipher_id': cipherID,
      'song_structure': songStructure.join(','),
      'duration': duration.inSeconds,
      'bpm': bpm,
      'transposed_key': transposedKey,
      'version_name': versionName,
      'created_at': createdAt.millisecondsSinceEpoch.toString(),
      'notes': notes,
    };
    if (firebaseID != null && firebaseID!.isNotEmpty) {
      row['firebase_id'] = firebaseID;
    }
    return row;
  }

  VersionDto toDto(Cipher cipher, Map<int, Section> sections) {
    return VersionDto(
      links: cipher.links,
      firebaseId: firebaseID,
      versionName: versionName,
      transposedKey: transposedKey,
      songStructure: songStructure,
      sections: sections.map(
        (sectionKey, section) => MapEntry(sectionKey, section.toDto()),
      ),
      title: cipher.title,
      author: cipher.author,
      language: cipher.language,
      originalKey: cipher.musicKey,
      bpm: bpm,
      duration: duration.inSeconds,
      tags: cipher.tags,
      notes: notes,
    );
  }

  Version copyWith({
    int? id,
    String? firebaseID,
    int? cipherID,
    List<int>? songStructure,
    Duration? duration,
    int? bpm,
    String? transposedKey,
    String? versionName,
    DateTime? createdAt,
    String? notes,
  }) {
    return Version(
      id: id ?? this.id,
      firebaseID: firebaseID ?? this.firebaseID,
      cipherID: cipherID ?? this.cipherID,
      songStructure: songStructure ?? this.songStructure,
      transposedKey: transposedKey ?? this.transposedKey,
      duration: duration ?? this.duration,
      bpm: bpm ?? this.bpm,
      versionName: versionName ?? this.versionName,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
    );
  }

  Version mergeWith(Version other) {
    return Version(
      id: id ?? other.id,
      firebaseID: firebaseID ?? other.firebaseID,
      cipherID: cipherID,
      songStructure: songStructure.isNotEmpty
          ? songStructure
          : other.songStructure,
      transposedKey: transposedKey ?? other.transposedKey,
      duration: duration != Duration.zero ? duration : other.duration,
      bpm: bpm != 0 ? bpm : other.bpm,
      versionName: versionName.isNotEmpty ? versionName : other.versionName,
      createdAt: createdAt.isBefore(other.createdAt)
          ? createdAt
          : other.createdAt,
      notes: notes ?? other.notes,
    );
  }

  // Factory for creating empty version
  factory Version.empty({int? cipherId}) {
    return Version(
      cipherID: cipherId ?? -1,
      versionName: 'Versão 1',
      songStructure: [],
      transposedKey: '',
      duration: Duration.zero,
      bpm: 0,
      createdAt: DateTime.now(),
    );
  }

  // Check if version is new (no ID)
  bool get isNew => id == -1;
}
