import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cordis/models/domain/cipher/section.dart';
import 'package:cordis/models/domain/cipher/version.dart';
import 'package:cordis/utils/color.dart';
import 'package:flutter/material.dart';

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
  final List<String> songStructure;
  final Timestamp? updatedAt;
  final Map<String, SectionDto> sections;

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
  });

  factory VersionDto.fromFirestore(Map<String, dynamic> map, String id) {
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
      tags: (map['tags'] as List<dynamic>).map((e) => e.toString()).toList(),
      songStructure: (map['songStructure'] as List<dynamic>)
          .map((e) => e.toString())
          .toList(),
      updatedAt: map['updatedAt'] as Timestamp?,
      sections: (map['sections'] as Map<String, dynamic>).map(
        (sectionsCode, section) => MapEntry(
          sectionsCode,
          SectionDto.fromFirestore(Map<String, dynamic>.from(section)),
        ),
      ),
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
      'sections': sections.map((key, value) => MapEntry(key, value.toFirestore())),
    };
  }

  factory VersionDto.fromCache(Map<String, dynamic> map) {
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
      tags: (map['tags'] as List<dynamic>).map((e) => e.toString()).toList(),
      songStructure: (map['songStructure'] as List<dynamic>)
          .map((e) => e.toString())
          .toList(),
      updatedAt: map['updatedAt'] != null
          ? (Timestamp.fromMillisecondsSinceEpoch(map['updatedAt'] as int))
          : Timestamp.now(),
      sections: (map['sections'] as Map<String, dynamic>).map(
        (sectionsCode, section) => MapEntry(
          sectionsCode,
          SectionDto.fromFirestore(Map<String, dynamic>.from(section)),
        ),
      ),
    );
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
      'sections': sections.map((key, value) => MapEntry(key, value.toCache())),
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
    List<String>? songStructure,
    Timestamp? updatedAt,
    Map<String, SectionDto>? sections,
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
    );
  }
}

class SectionDto {
  final String contentCode;
  final String contentType;
  final String contentText;
  final String? color;

  SectionDto({
    required this.contentCode,
    required this.contentType,
    required this.contentText,
    this.color,
  });

  factory SectionDto.fromFirestore(Map<String, dynamic> map) {
    return SectionDto(
      contentCode: map['contentCode'] as String,
      contentType: map['contentType'] as String,
      contentText: map['contentText'] as String,
      color: map['contentColor'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'contentCode': contentCode,
      'contentType': contentType,
      'contentText': contentText,
      'contentColor': color,
    };
  }

  Map<String, dynamic> toCache() => toFirestore();

  Section toDomain({int? versionID}) {
    return Section(
      versionID: versionID ?? -1,
      contentType: contentType,
      contentCode: contentCode,
      contentText: contentText,
      contentColor: color != null ? colorFromHex(color!) : Colors.grey,
    );
  }
}
