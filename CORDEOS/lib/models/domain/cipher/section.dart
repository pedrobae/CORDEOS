import 'package:cordeos/models/dtos/version_dto.dart';

import 'package:cordeos/utils/color.dart';
import 'package:cordeos/utils/section_type.dart';
import 'package:flutter/cupertino.dart';

class Section {
  final int? id;
  final int key;
  final int versionID;
  String contentType;
  String contentText;
  Color contentColor;

  Section({
    this.id,
    required this.key,
    required this.versionID,
    required this.contentType,
    required this.contentText,
    required this.contentColor,
  });

  SectionType get sectionType {
    return identifySectionType(contentColor);
  }

  factory Section.fromSqLite(Map<String, dynamic> json) {
    return Section(
      id: json['id'],
      key: json['key'],
      versionID: json['version_id'],
      contentType: json['content_type'],
      contentText: json['content_text'],
      contentColor: colorFromHex(json['content_color']),
    );
  }

  /// Converts to a map suitable for SQLite storage.
  /// Later the version Id (int) gets assigned.
  Map<String, dynamic> toSqlite() {
    return {
      'key': key,
      'version_id': versionID,
      'content_type': contentType,
      'content_text': contentText,
      'content_color': colorToHex(contentColor),
    };
  }

  factory Section.fromFirestore(SectionDto dto, int versionID) {
    return Section(
      key: dto.key,
      versionID: versionID,
      contentType: dto.contentType,
      contentText: dto.contentText,
      contentColor: colorFromHex(dto.color),
    );
  }

  SectionDto toDto() {
    return SectionDto(
      key: key,
      contentType: contentType,
      contentText: contentText,
      color: colorToHex(contentColor),
    );
  }

  Section copyWith({
    int? id,
    int? key,
    int? versionID,
    String? contentType,
    String? contentText,
    Color? contentColor,
  }) {
    return Section(
      id: id ?? this.id,
      key: key ?? this.key,
      versionID: versionID ?? this.versionID,
      contentType: contentType ?? this.contentType,
      contentText: contentText ?? this.contentText,
      contentColor: contentColor ?? this.contentColor,
    );
  }
}
