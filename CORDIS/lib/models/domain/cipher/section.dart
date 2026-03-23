import 'package:cordis/models/dtos/version_dto.dart';
import 'package:cordis/utils/color.dart';
import 'package:flutter/cupertino.dart';

class Section {
  final int? id;
  int versionID;
  String contentType;
  String contentCode;
  String contentText;
  Color contentColor;

  Section({
    this.id,
    required this.versionID,
    required this.contentType,
    required this.contentCode,
    required this.contentText,
    required this.contentColor,
  });

  factory Section.fromSqLite(Map<String, dynamic> json) {
    return Section(
      id: json['id'],
      versionID: json['version_id'],
      contentType: json['content_type'],
      contentCode: json['content_code'],
      contentText: json['content_text'],
      contentColor: colorFromHex(json['content_color']),
    );
  }

  /// Converts to a map suitable for SQLite storage.
  /// Later the version Id (int) gets assigned.
  Map<String, dynamic> toSqlite() {
    return {
      'content_type': contentType,
      'content_code': contentCode,
      'content_text': contentText,
      'content_color': colorToHex(contentColor),
    };
  }
  SectionDto toFirestore() {
    return SectionDto(
      contentCode: contentCode,
      contentType: contentType,
      contentText: contentText,
      color: colorToHex(contentColor),
    );
  }

  Section copyWith({
    int? id,
    int? versionID,
    String? contentType,
    String? contentCode,
    String? contentText,
    Color? contentColor,
  }) {
    return Section(
      id: id ?? this.id,
      versionID: versionID ?? this.versionID,
      contentType: contentType ?? this.contentType,
      contentCode: contentCode ?? this.contentCode,
      contentText: contentText ?? this.contentText,
      contentColor: contentColor ?? this.contentColor,
    );
  }
}
