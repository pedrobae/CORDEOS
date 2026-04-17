import 'package:flutter/material.dart';
import 'package:cordeos/l10n/app_localizations.dart';

enum SectionType {
  verse,
  chorus,
  bridge,
  intro,
  outro,
  solo,
  preChorus,
  tag,
  finale,
  annotation,
  unknown,
}

SectionType identifySectionType(String label) {
  final normalizedLabel = label.toLowerCase().trim();
  for (var type in SectionType.values) {
    for (var knownLabel in type.knownLabels) {
      final regex = RegExp(
        '^${knownLabel.replaceAll(r'\s+', r'\\s+')}\\b',
        caseSensitive: false,
      );
      if (regex.hasMatch(normalizedLabel)) {
        return type;
      }
    }
  }
  return SectionType.unknown;
}

extension SectionTypeMethods on SectionType {
  Color get color {
    switch (this) {
      case SectionType.verse:
        return Color(0xFF2196F3);
      case SectionType.chorus:
        return Color(0xFFF44336);
      case SectionType.bridge:
        return Colors.green;
      case SectionType.intro:
        return Color(0xFF9C27B0);
      case SectionType.outro:
        return Colors.brown;
      case SectionType.solo:
        return Colors.amber;
      case SectionType.preChorus:
        return Colors.orange;
      case SectionType.tag:
        return Colors.teal;
      case SectionType.finale:
        return Color(0xFF3F51B5);
      case SectionType.annotation:
        return Colors.grey;
      case SectionType.unknown:
        return Colors.grey;
    }
  }

  String localizedLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (this) {
      case SectionType.verse:
        return l10n.sectionVerse;
      case SectionType.chorus:
        return l10n.sectionChorus;
      case SectionType.bridge:
        return l10n.sectionBridge;
      case SectionType.intro:
        return l10n.sectionIntro;
      case SectionType.outro:
        return l10n.sectionOutro;
      case SectionType.solo:
        return l10n.sectionSolo;
      case SectionType.preChorus:
        return l10n.sectionPreChorus;
      case SectionType.tag:
        return l10n.sectionTag;
      case SectionType.finale:
        return l10n.sectionFinale;
      case SectionType.annotation:
        return l10n.sectionAnnotations;
      case SectionType.unknown:
        return l10n.sectionUnlabeled;
    }
  }

  String get canonicalLabel {
    switch (this) {
      case SectionType.verse:
        return 'Verse';
      case SectionType.chorus:
        return 'Chorus';
      case SectionType.bridge:
        return 'Bridge';
      case SectionType.intro:
        return 'Intro';
      case SectionType.outro:
        return 'Outro';
      case SectionType.solo:
        return 'Solo';
      case SectionType.preChorus:
        return 'Pre-Chorus';
      case SectionType.tag:
        return 'Tag';
      case SectionType.finale:
        return 'Finale';
      case SectionType.annotation:
        return 'Annotations';
      case SectionType.unknown:
        return 'Unlabeled Section';
    }
  }

  /// Common Section labels are iterated through on import / parsing to identify sections
  /// MIGHT BE PRUDENT TO MAKE THIS LOCALIZABLE IN THE FUTURE
  /// AREA OF OPTIMIZATION: use a more efficient data structure for lookups
  List<String> get knownLabels {
    switch (this) {
      case SectionType.verse:
        return [
          'verse',
          'verso',
          r'(?:\w+\s+)?parte(?:\s*\d+)?',
          r'(?:\w+\s+)?estrofe(?:\s*\d+)?',
        ];
      case SectionType.chorus:
        return ['chorus', 'coro', 'refrao', 'refrão'];
      case SectionType.bridge:
        return ['bridge', 'ponte'];
      case SectionType.intro:
        return ['intro'];
      case SectionType.outro:
        return ['outro', 'ending', 'saída', 'saida'];
      case SectionType.solo:
        return ['solo'];
      case SectionType.preChorus:
        return ['pre[- ]?chorus', 'pre[- ]?refrao', 'pré[- ]?refrão'];
      case SectionType.tag:
        return ['tag'];
      case SectionType.finale:
        return ['finale', 'final'];
      case SectionType.annotation:
        return ['notes', 'anotacoes', 'anotações'];
      case SectionType.unknown:
        return [
          'unlabeled',
          'unknown',
          'untitled',
          'sem título',
          'sem titulo',
          'desconhecido',
        ];
    }
  }

  String code(int index) {
    final suffix = index > 0 ? '$index' : '';
    switch (this) {
      case SectionType.verse:
        return 'V$suffix';
      case SectionType.chorus:
        return 'C$suffix';
      case SectionType.bridge:
        return 'B$suffix';
      case SectionType.intro:
        return 'I$suffix';
      case SectionType.outro:
        return 'O$suffix';
      case SectionType.solo:
        return 'S$suffix';
      case SectionType.preChorus:
        return 'PC$suffix';
      case SectionType.tag:
        return 'T$suffix';
      case SectionType.finale:
        return 'F$suffix';
      case SectionType.annotation:
        return 'N$suffix';
      case SectionType.unknown:
        return 'U$suffix';
    }
  }
}

class SectionBadgeData {
  final SectionType type;
  final String code;
  final Color color;

  SectionBadgeData({
    required this.type,
    required this.code,
    required this.color,
  });
}

Map<int, SectionBadgeData> getSectionBadges(Map<int, SectionType> types) {
  final badgeData = <int, SectionBadgeData>{};
  Map<SectionType, int> typeCountMap = {};
  for (var entry in types.entries) {
    final sectionType = entry.value;
    typeCountMap[sectionType] = (typeCountMap[sectionType] ?? 0) + 1;

    badgeData[entry.key] = SectionBadgeData(
      type: sectionType,
      code: sectionType.code(typeCountMap[sectionType]!),
      color: sectionType.color,
    );
  }

  // REMOVE NUMBERING FROM SINGLE TYPE OCURRENCES
  for (var entry in badgeData.entries) {
    final type = entry.value.type;
    if (typeCountMap[type] == 1) {
      badgeData[entry.key] = SectionBadgeData(
        type: type,
        code: type.code(0),
        color: type.color,
      );
    }
  }

  return badgeData;
}

bool isTransition(SectionType? type) {
  return type == SectionType.intro ||
      type == SectionType.outro ||
      type == SectionType.solo ||
      type == SectionType.bridge;
}
