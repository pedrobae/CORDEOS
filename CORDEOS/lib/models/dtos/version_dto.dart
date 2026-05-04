import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cordeos/models/domain/cipher/section.dart';
import 'package:cordeos/models/domain/cipher/version.dart';
import 'package:cordeos/utils/color.dart';
import 'package:cordeos/utils/section_type.dart';

/// DTO para metadados de version (camada de separação entre a nuvem e o armazenamento local).
class VersionDto {
  final String? firebaseId; // ID na nuvem (Firebase)
  final String title;
  final String author;
  final int bpm;
  final int duration;
  final String language;
  final List<String> tags;
  final String versionName;
  final String originalKey;
  final String? transposedKey;
  final List<int> songStructure;
  final Timestamp? updatedAt;
  final Map<int, SectionDto> sections;
  final List<String> links;
  final String? notes;

  VersionDto({
    this.firebaseId,
    required this.versionName,
    required this.songStructure,
    this.updatedAt,
    required this.sections,
    required this.title,
    required this.author,
    required this.bpm,
    required this.duration,
    required this.language,
    this.tags = const [],
    required this.originalKey,
    this.transposedKey,
    this.links = const [],
    this.notes,
  });

  factory VersionDto.fromFirestore(Map<String, dynamic> map, String id) {
    final parsedStructure = _parseStructureAndSections(
      rawSongStructure: map['songStructure'],
      rawSections: map['sections'],
    );

    return VersionDto(
      firebaseId: id,
      author: map['author'] as String,
      title: map['title'] as String,
      duration: map['duration'] as int? ?? 0,
      bpm: map['bpm'] as int? ?? 0,
      language: map['language'] as String,
      versionName: map['versionName'] as String,
      originalKey: map['originalKey'] as String,
      transposedKey: map['transposedKey'] as String?,
      links: ((map['link'] as List<dynamic>?) ?? [])
          .map((link) => link as String)
          .toList(),
      tags: ((map['tags'] as List<dynamic>?) ?? [])
          .map((tag) => tag as String)
          .toList(),
      songStructure: parsedStructure.songStructure,
      updatedAt: map['updatedAt'] as Timestamp?,
      sections: parsedStructure.sections,
      notes: map['notes'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'author': author,
      'title': title,
      'duration': duration,
      'bpm': bpm,
      'language': language,
      'versionName': versionName,
      'originalKey': originalKey,
      'transposedKey': transposedKey,
      'tags': tags,
      'songStructure': songStructure,
      'updatedAt': updatedAt ?? Timestamp.now(),
      'sections': sections.map(
        (key, value) => MapEntry(key.toString(), value.toFirestore()),
      ),
      'links': links,
      'notes': notes,
    };
  }

  factory VersionDto.fromCache(Map<String, dynamic> map) {
    final parsedStructure = _parseStructureAndSections(
      rawSongStructure: map['songStructure'],
      rawSections: map['sections'],
    );

    return VersionDto(
      firebaseId: map['firebaseId'] as String?,
      author: map['author'] as String,
      title: map['title'] as String,
      duration: map['duration'] as int? ?? 0,
      bpm: map['bpm'] as int? ?? 0,
      language: map['language'] as String,
      versionName: map['versionName'] as String,
      originalKey: map['originalKey'] as String,
      transposedKey: map['transposedKey'] as String?,
      songStructure: parsedStructure.songStructure,
      updatedAt: map['updatedAt'] != null
          ? (Timestamp.fromMillisecondsSinceEpoch(map['updatedAt'] as int))
          : Timestamp.now(),
      sections: parsedStructure.sections,
      tags: (map['tags'] as List<dynamic>).map((tag) => tag as String).toList(),
      links: (map['links'] as List<dynamic>)
          .map((link) => link as String)
          .toList(),
      notes: map['notes'] as String?,
    );
  }

  /// Supports both legacy string-keyed structures and new int-keyed structures.
  /// The same logical section id is reused between songStructure and sections.
  static _ParsedStructure _parseStructureAndSections({
    required dynamic rawSongStructure,
    required dynamic rawSections,
  }) {
    final sectionsMap = rawSections is Map ? rawSections : <dynamic, dynamic>{};
    final structureList = rawSongStructure is List
        ? rawSongStructure
        : <dynamic>[];

    final legacyToInt = <String, int>{};
    final usedIds = <int>{};
    var nextGeneratedId = 1;

    int mapId(dynamic rawId) {
      if (rawId is int) {
        usedIds.add(rawId);
        return rawId;
      }

      final normalized = rawId?.toString() ?? '';
      if (normalized.isEmpty) {
        while (usedIds.contains(nextGeneratedId)) {
          nextGeneratedId++;
        }
        final generated = nextGeneratedId;
        usedIds.add(generated);
        nextGeneratedId++;
        return generated;
      }

      final existing = legacyToInt[normalized];
      if (existing != null) {
        return existing;
      }

      final numeric = int.tryParse(normalized);
      if (numeric != null && !usedIds.contains(numeric)) {
        legacyToInt[normalized] = numeric;
        usedIds.add(numeric);
        return numeric;
      }

      while (usedIds.contains(nextGeneratedId)) {
        nextGeneratedId++;
      }
      final generated = nextGeneratedId;
      legacyToInt[normalized] = generated;
      usedIds.add(generated);
      nextGeneratedId++;
      return generated;
    }

    final parsedSections = <int, SectionDto>{};
    for (final entry in sectionsMap.entries) {
      final sectionId = mapId(entry.key);
      final sectionData = Map<String, dynamic>.from(entry.value as Map);
      sectionData['key'] = _tryParseInt(sectionData['key']) ?? sectionId;
      parsedSections[sectionId] = SectionDto.fromFirestore(sectionData);
    }

    final parsedSongStructure = structureList
        .map((item) => mapId(item))
        .toList(growable: false);

    return _ParsedStructure(
      songStructure: parsedSongStructure,
      sections: parsedSections,
    );
  }

  static int? _tryParseInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  /// To JSON for caching (weekly public versions)
  Map<String, dynamic> toCache() {
    return {
      'firebaseId': firebaseId,
      'author': author,
      'title': title,
      'duration': duration,
      'bpm': bpm,
      'language': language,
      'versionName': versionName,
      'originalKey': originalKey,
      'transposedKey': transposedKey,
      'tags': tags,
      'songStructure': songStructure,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
      'sections': sections.map(
        (key, value) => MapEntry(key.toString(), value.toCache()),
      ),
      'links': links,
      'notes': notes,
    };
  }

  Version toDomain({int? cipherId}) {
    return Version(
      firebaseID: firebaseId,
      versionName: versionName,
      transposedKey: transposedKey,
      songStructure: songStructure,
      duration: Duration(seconds: duration),
      bpm: bpm,
      createdAt: updatedAt?.toDate() ?? DateTime.now(),
      cipherID: cipherId ?? -1,
      notes: notes,
    );
  }

  VersionDto copyWith({
    String? firebaseId,
    String? title,
    String? author,
    int? duration,
    int? bpm,
    String? language,
    List<String>? tags,
    String? versionName,
    String? originalKey,
    String? transposedKey,
    List<int>? songStructure,
    Timestamp? updatedAt,
    Map<int, SectionDto>? sections,
    List<String>? links,
    String? notes
  }) {
    return VersionDto(
      firebaseId: firebaseId ?? this.firebaseId,
      title: title ?? this.title,
      author: author ?? this.author,
      duration: duration ?? this.duration,
      bpm: bpm ?? this.bpm,
      language: language ?? this.language,
      tags: tags ?? this.tags,
      versionName: versionName ?? this.versionName,
      originalKey: originalKey ?? this.originalKey,
      transposedKey: transposedKey ?? this.transposedKey,
      songStructure: songStructure ?? this.songStructure,
      updatedAt: updatedAt ?? this.updatedAt,
      sections: sections ?? this.sections,
      links: links ?? this.links,
      notes: notes
    );
  }
}

class SectionDto {
  final int key;
  final String contentType;
  final String contentText;
  final String color;

  SectionType get sectionType {
    return identifySectionType(colorFromHex(color));
  }

  SectionDto({
    required this.key,
    required this.contentType,
    required this.contentText,
    required this.color,
  });

  factory SectionDto.fromFirestore(Map<String, dynamic> map) {
    return SectionDto(
      key: VersionDto._tryParseInt(map['key']) ?? 0,
      contentType: map['contentType'] as String,
      contentText: map['contentText'] as String,
      color: map['contentColor'] as String,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'key': key,
      'contentType': contentType,
      'contentText': contentText,
      'contentColor': color,
    };
  }

  Map<String, dynamic> toCache() => toFirestore();

  Section toDomain({int? versionID}) {
    return Section(
      versionID: versionID ?? -1,
      key: key,
      contentType: contentType,
      contentText: contentText,
      contentColor: colorFromHex(color),
    );
  }
}

class _ParsedStructure {
  final List<int> songStructure;
  final Map<int, SectionDto> sections;

  const _ParsedStructure({required this.songStructure, required this.sections});
}
