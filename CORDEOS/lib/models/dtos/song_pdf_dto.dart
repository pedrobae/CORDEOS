import 'package:cordeos/services/tokenization/helper_classes.dart';
import 'package:cordeos/utils/section_type.dart';
import 'package:flutter/material.dart';

class SongPdfDto {
  final String title;
  final String author;
  final String musicKey;
  final String language;
  final Duration duration;
  final int bpm;
  final String? link;

  final List<int> songStructure;
  final Map<int, TokenPositionMap> content;
  final Map<int, SectionBadgeData> badgesData;

  /// Global Y coordinate of each section's top edge, keyed by section code.
  /// Use this to render section labels and to iterate songStructure for repeats.
  final Map<int, double> sectionOffsets;

  final Map<String, Measurements> tokenMeasurements;

  /// Full page content width (page width minus margins). Stored so the renderer
  /// can compute margins, column positions, etc.
  final double pageContentWidth;

  /// Width used when calculating token positions. May be narrower than
  /// [pageContentWidth] (e.g. a chord-map column in a multi-column layout).
  final double layoutWidth;

  final TextStyle lyricsStyle;
  final TextStyle chordsStyle;
  final TextStyle metadataStyle;
  final TextStyle sectionLabelStyle;

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
    required this.sectionOffsets,
    required this.badgesData,
    required this.tokenMeasurements,
    required this.pageContentWidth,
    required this.layoutWidth,
    required this.lyricsStyle,
    required this.chordsStyle,
    required this.metadataStyle,
    required this.sectionLabelStyle,
  });
}

/// Options required to build a [SongPdfDto] from raw version data.
///
/// Group these instead of passing a long flat parameter list to
/// [PrintingProvider.buildSongPdfDto].
class SongPdfBuildOptions {
  /// Full page content width (page width minus horizontal margins).
  final double pageContentWidth;

  /// Width used for token wrapping. Pass a narrower value for multi-column
  /// layouts. Defaults to [pageContentWidth] when null.
  final double? layoutWidth;

  final TextStyle lyricStyle;
  final TextStyle chordStyle;
  final TextStyle metadataStyle;
  final TextStyle sectionLabelStyle;

  final double lineBreakSpacing;
  final double chordLyricSpacing;
  final double minChordSpacing;

  const SongPdfBuildOptions({
    required this.pageContentWidth,
    this.layoutWidth,
    required this.lyricStyle,
    required this.chordStyle,
    required this.metadataStyle,
    required this.sectionLabelStyle,
    this.lineBreakSpacing = 0,
    this.chordLyricSpacing = 0,
    this.minChordSpacing = 5,
  });
}

/// Display options consumed by [PrintingProvider.buildPreviewSnapshot].
///
/// All strings should already be localized by the caller before constructing
/// this object (the provider has no [BuildContext]).
class SongPreviewDisplayOptions {
  final bool showSongMap;
  final bool showBpm;
  final bool showDuration;

  final String songMapLabel;
  final String bpmLabel;
  final String durationLabel;
  final Map<int, SectionLabelData> labelData;

  const SongPreviewDisplayOptions({
    this.showSongMap = true,
    this.showBpm = true,
    this.showDuration = true,
    required this.songMapLabel,
    required this.bpmLabel,
    required this.durationLabel,
    required this.labelData,
  });
}

class TokenizedSection {
  final String code;
  final TokenPositionMap tokens;

  TokenizedSection({required this.code, required this.tokens});
}

class SectionLabelData {
  final SectionType type;
  final String localizedLabel;
  final String code;

  SectionLabelData({
    required this.type,
    required this.code,
    required this.localizedLabel,
  });

  String get label {
    return '$code - $localizedLabel';
  }
}
