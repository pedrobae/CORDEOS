import 'package:cordeos/models/dtos/song_pdf_dto.dart';
import 'package:cordeos/utils/section_type.dart';
import 'package:cordeos/widgets/ciphers/print/page_preview_painter.dart';
import 'package:cordeos/repositories/local/cipher_repository.dart';
import 'package:cordeos/repositories/local/section_repository.dart';
import 'package:cordeos/repositories/local/version_repository.dart';
import 'package:cordeos/services/tokenization/build_service.dart';
import 'package:cordeos/services/tokenization/helper_classes.dart';
import 'package:cordeos/services/tokenization/position_service.dart';
import 'package:cordeos/services/tokenization/tokenization_service.dart';
import 'package:cordeos/utils/token_cache_keys.dart';
import 'package:flutter/material.dart';

class PrintingProvider {
  final _ciph = CipherRepository();
  final _localVer = LocalVersionRepository();
  final _sect = SectionRepository();

  static const _tokenizer = TokenizationService();
  static const _builder = TokenizationBuilder();
  static const _positioner = PositionService();

  Future<SongPdfDto> buildSongPdfDto({
    required int versionID,
    required SongPdfBuildOptions options,
    String Function(String)? transposeChord,
  }) async {
    final version = await _localVer.getVersionWithId(versionID);
    if (version == null) {
      throw Exception('Version not found for ID: $versionID');
    }

    final cipher = await _ciph.getCipherById(version.cipherID);
    if (cipher == null) {
      throw Exception('Cipher not found for ID: ${version.cipherID}');
    }

    final sections = await _sect.getSections(versionID);
    final types = <int, SectionType>{};
    for (var section in sections.values) {
      types[section.key] = section.sectionType;
    }
    final badgesData = getSectionBadges(types);

    // Measure sample text once — shared across all sections.
    final lyricStyle = options.lyricStyle;
    final chordStyle = options.chordStyle;
    final lyricHeight = _builder
        .measureText(style: lyricStyle, text: 'Sample Text')
        .height;
    final chordHeight = _builder
        .measureText(style: chordStyle, text: 'C')
        .height;
    final double effectiveLayoutWidth =
        options.layoutWidth ?? options.pageContentWidth;

    // Shared measurement map — accumulated across sections so identical
    // glyphs are only measured once. This map is stored in the DTO and acts
    // as the cache for the downstream PDF renderer.
    final Map<String, Measurements> tokenMeasurements = {};
    // Global-coordinate positions keyed by section key.
    final Map<int, TokenPositionMap> content = {};
    // Global Y start of each section (for rendering labels and repeat placements).
    final Map<int, double> sectionOffsets = {};

    for (final key in version.songStructure) {
      final section = sections[key];
      if (section == null) {
        throw Exception(
          'Section with key $key not found for version ID: $versionID',
        );
      }

      // Phase 1: Tokenize
      final tokens = _tokenizer.tokenize(
        section.contentText,
        showLyrics: true,
        showChords: true,
        transposeChord: transposeChord ?? (chord) => chord,
      );

      // Phase 2: Organize
      final organized = _tokenizer.organize(tokens);

      // Phase 3: Measure (accumulated into shared map)
      _measureTokens(
        tokens: tokens,
        chordStyle: chordStyle,
        lyricStyle: lyricStyle,
        chordLyricSpacing: options.chordLyricSpacing,
        measurements: tokenMeasurements,
      );

      // Phase 4: Position (local coordinates, using layoutWidth for column support)
      content[key] = _positioner.calculateTokenPositions(
        organizedTokens: organized,
        measurements: tokenMeasurements,
        maxWidth: effectiveLayoutWidth,
        lineSpacing: 0,
        lineBreakSpacing: options.lineBreakSpacing,
        chordLyricSpacing: options.chordLyricSpacing,
        minChordSpacing: options.minChordSpacing,
        letterSpacing: 0,
        isEditMode: false,
        lyricStyle: lyricStyle,
        chordStyle: chordStyle,
        lyricHeight: lyricHeight,
        chordHeight: chordHeight,
      );
    }

    return SongPdfDto(
      title: cipher.title,
      author: cipher.author,
      musicKey: cipher.musicKey,
      language: cipher.language,
      duration: version.duration,
      bpm: version.bpm,
      songStructure: version.songStructure,
      content: content,
      sectionOffsets: sectionOffsets,
      tokenMeasurements: tokenMeasurements,
      pageContentWidth: options.pageContentWidth,
      layoutWidth: effectiveLayoutWidth,
      lyricsStyle: options.lyricStyle,
      chordsStyle: options.chordStyle,
      metadataStyle: options.metadataStyle,
      sectionLabelStyle: options.sectionLabelStyle,
      badgesData: badgesData
    );
  }

  /// Builds a [PagePreviewSnapshot] synchronously from an already-computed
  /// [SongPdfDto] and display options.
  ///
  /// Call this after [buildSongPdfDto] resolves, or again whenever display
  /// options change (e.g. toggling BPM / song-map / section labels) without
  /// needing to re-read the database.
  PagePreviewSnapshot buildPreviewSnapshot({
    required SongPdfDto dto,
    required SongPreviewDisplayOptions displayOptions,
  }) {
    return PagePreviewSnapshot.build(
      dto: dto,
      builder: _builder,
      opt: displayOptions,
    );
  }

  /// Measures every token in [tokens] and accumulates results into [measurements].
  /// Uses [putIfAbsent] so identical glyphs across sections are only computed once.
  void _measureTokens({
    required List<ContentToken> tokens,
    required TextStyle chordStyle,
    required TextStyle lyricStyle,
    required double chordLyricSpacing,
    required Map<String, Measurements> measurements,
  }) {
    for (final token in tokens) {
      switch (token.type) {
        case TokenType.chord:
          final key = measurementKey(token.text, chordStyle);
          measurements.putIfAbsent(
            key,
            () => _builder.measureText(text: token.text, style: chordStyle),
          );
          break;

        case TokenType.space:
        case TokenType.lyric:
          final key = measurementKey(token.text, lyricStyle);
          measurements.putIfAbsent(
            key,
            () => _builder.measureText(text: token.text, style: lyricStyle),
          );
          break;

        case TokenType.preSeparator:
        case TokenType.postSeparator:
        case TokenType.chordTarget:
          // Targets are not shown on the PDF
          break;
        case TokenType.underline:
        case TokenType.newline:
          // Computed dynamically during positioning — nothing to pre-measure.
          break;
      }
    }
  }
}
