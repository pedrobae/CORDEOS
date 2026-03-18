import 'package:flutter/material.dart';
import 'package:cordis/l10n/app_localizations.dart';

enum SectionLabelType {
  verse,
  chorus,
  bridge,
  intro,
  outro,
  solo,
  preChorus,
  tag,
  finale,
  annotations,
  unknown,
}

extension SectionLabelTypeX on SectionLabelType {
  String get canonicalLabel {
    switch (this) {
      case SectionLabelType.verse:
        return 'Verse';
      case SectionLabelType.chorus:
        return 'Chorus';
      case SectionLabelType.bridge:
        return 'Bridge';
      case SectionLabelType.intro:
        return 'Intro';
      case SectionLabelType.outro:
        return 'Outro';
      case SectionLabelType.solo:
        return 'Solo';
      case SectionLabelType.preChorus:
        return 'Pre-Chorus';
      case SectionLabelType.tag:
        return 'Tag';
      case SectionLabelType.finale:
        return 'Finale';
      case SectionLabelType.annotations:
        return 'Annotations';
      case SectionLabelType.unknown:
        return 'Unlabeled Section';
    }
  }

  String localizedLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (this) {
      case SectionLabelType.verse:
        return l10n.sectionVerse;
      case SectionLabelType.chorus:
        return l10n.sectionChorus;
      case SectionLabelType.bridge:
        return l10n.sectionBridge;
      case SectionLabelType.intro:
        return l10n.sectionIntro;
      case SectionLabelType.outro:
        return l10n.sectionOutro;
      case SectionLabelType.solo:
        return l10n.sectionSolo;
      case SectionLabelType.preChorus:
        return l10n.sectionPreChorus;
      case SectionLabelType.tag:
        return l10n.sectionTag;
      case SectionLabelType.finale:
        return l10n.sectionFinale;
      case SectionLabelType.annotations:
        return l10n.sectionAnnotations;
      case SectionLabelType.unknown:
        return l10n.sectionUnlabeled;
    }
  }
}

/// Common Section labels are iterated through on import / parsing to identify sections
/// MIGHT BE PRUDENT TO MAKE THIS LOCALIZABLE IN THE FUTURE
/// AREA OF OPTIMIZATION: use a more efficient data structure for lookups
const Map<String, SectionLabel> commonSectionLabels = {
  'verse': SectionLabel(
    labelVariations: [
      'verse',
      'verso',
      r'(?:\w+\s+)?parte(?:\s*\d+)?',
      r'(?:\w+\s+)?estrofe(?:\s*\d+)?',
    ],
    labelType: SectionLabelType.verse,
    code: 'V',
    color: Color(0xFF2196F3),
  ),
  'chorus': SectionLabel(
    labelVariations: ['chorus', 'coro', 'refrao', 'refrão'],
    labelType: SectionLabelType.chorus,
    code: 'C',
    color: Color(0xFFF44336),
  ),
  'bridge': SectionLabel(
    labelVariations: ['bridge', 'ponte'],
    labelType: SectionLabelType.bridge,
    code: 'B',
    color: Colors.green,
  ),
  'intro': SectionLabel(
    labelVariations: ['intro'],
    labelType: SectionLabelType.intro,
    code: 'I',
    color: Color(0xFF9C27B0),
  ),
  'outro': SectionLabel(
    labelVariations: ['outro'],
    labelType: SectionLabelType.outro,
    code: 'O',
    color: Colors.brown,
  ),
  'solo': SectionLabel(
    labelVariations: ['solo'],
    labelType: SectionLabelType.solo,
    code: 'S',
    color: Colors.amber,
  ),
  'pre-chorus': SectionLabel(
    labelVariations: ['pre[- ]?chorus', 'pre[- ]?refrao', 'pré[- ]?refrão'],
    labelType: SectionLabelType.preChorus,
    code: 'PC',
    color: Colors.orange,
  ),
  'tag': SectionLabel(
    labelVariations: ['tag'],
    labelType: SectionLabelType.tag,
    code: 'T',
    color: Colors.teal,
  ),
  'finale': SectionLabel(
    labelVariations: ['finale', 'final'],
    labelType: SectionLabelType.finale,
    code: 'F',
    color: Color(0xFF3F51B5),
  ),
  'annotations': SectionLabel(
    labelVariations: ['notes', 'anotacoes', 'anotações'],
    labelType: SectionLabelType.annotations,
    code: 'N',
    color: Colors.grey,
  ),
};

class SectionLabel {
  final List<String> labelVariations;
  final SectionLabelType labelType;
  final String code;
  final Color color;

  const SectionLabel({
    required this.labelVariations,
    required this.labelType,
    required this.code,
    required this.color,
  });

  String get canonicalLabel => labelType.canonicalLabel;

  String localizedLabel(BuildContext context) =>
      labelType.localizedLabel(context);

  factory SectionLabel.unknown() {
    return const SectionLabel(
      labelVariations: [],
      labelType: SectionLabelType.unknown,
      code: '',
      color: Colors.grey,
    );
  }
}

/// Checks if the code trimmed of a numeric suffix matches any of transition codes
bool isTransition(String sectionCode) {
  final trimmedCode = sectionCode.replaceAll(RegExp(r'\d+$'), '');
  final transitionCodes = ['I', 'B', 'PC', 'S', 'O', 'F'];
  return (transitionCodes.contains(trimmedCode));
}

/// Checks if the code trimmed of a numeric suffix matches the annotation code
bool isAnnotation(String sectionCode) {
  final trimmedCode = sectionCode.replaceAll(RegExp(r'\d+$'), '');
  return (trimmedCode == 'N');
}
