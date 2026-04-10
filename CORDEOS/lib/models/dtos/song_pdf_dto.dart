import 'package:cordeos/services/tokenization/helper_classes.dart';
import 'package:flutter/material.dart';

class SongPdfDto {
  final String title;
  final String author;
  final String musicKey;
  final String language;
  final Duration duration;
  final int bpm;
  final String? link;

  final List<String> songStructure;
  final Map<String, TokenPositionMap> content;
  final Map<String, Measurements> tokenMeasurements;

  final TextStyle lyricsStyle;
  final TextStyle chordsStyle;
  final TextStyle metadataStyle;

  SongPdfDto({
    required this.title,
    required this.author,
    required this.musicKey,
    required this.language,
    required this.duration,
    required this.bpm,
    this.link,
    required this.songStructure,
    required this.content,
    required this.tokenMeasurements,
    required this.lyricsStyle,
    required this.chordsStyle,
    required this.metadataStyle,
  });
}

class TokenizedSection {
  final String code;
  final TokenPositionMap tokens;

  TokenizedSection({required this.code, required this.tokens});
}
