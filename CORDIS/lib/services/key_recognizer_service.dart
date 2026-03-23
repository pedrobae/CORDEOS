import 'package:cordis/models/domain/cipher/section.dart';
import 'package:cordis/models/dtos/version_dto.dart';
import 'package:cordis/helpers/chords/chords.dart';

import 'package:cordis/repositories/local/version_repository.dart';
import 'package:cordis/repositories/local/section_repository.dart';

class KeyRecognizerService {
  final _localVersionRepo = LocalVersionRepository();
  final _sectionRepo = SectionRepository();
  final _chords = ChordHelper();

  /// Collects all chords of a cipherID and select a music key based on them
  Future<String> recognizeKeyLocal(int cipherID) async {
    final version = await _localVersionRepo.getOldestVersionOfCipher(cipherID);
    final sections = await _sectionRepo.getSections(version.id!);

    List<String> chords = [];
    for (var section in sections.values) {
      final text = section.contentText;
      final chord = StringBuffer();
      bool inChord = false;
      for (var i = 0; i < text.length; i++) {
        final char = text[i];
        if (inChord) {
          if (char == ']') {
            inChord = false;
            chords.add(chord.toString());
            chord.clear();
          } else {
            chord.write(char);
          }
        } else {
          if (char == '[') {
            inChord = true;
          }
        }
      }
    }
    return _extractKey(chords);
  }

  /// Collects all chords of a Cloud Version and select a music key based on them
  Future<String> recognizeKeyCloud(VersionDto version) async {
    List<String> chords = [];
    for (var section in version.sections.values) {
      final text = section['contentText'] as String;
      final chord = StringBuffer();
      bool inChord = false;
      for (var i = 0; i < text.length; i++) {
        final char = text[i];
        if (inChord) {
          if (char == ']') {
            inChord = false;
            chords.add(chord.toString());
            chord.clear();
          } else {
            chord.write(char);
          }
        } else {
          if (char == '[') {
            inChord = true;
          }
        }
      }
    }
    return _extractKey(chords);
  }

  /// Recognizes the key of a new cipher that is cache only
  String recognizeKeyForNewCipher(List<Section> sections) {
    List<String> chords = [];
    for (var section in sections) {
      final text = section.contentText;
      final chord = StringBuffer();
      bool inChord = false;
      for (var i = 0; i < text.length; i++) {
        final char = text[i];
        if (inChord) {
          if (char == ']') {
            inChord = false;
            chords.add(chord.toString());
            chord.clear();
          } else {
            chord.write(char);
          }
        } else {
          if (char == '[') {
            inChord = true;
          }
        }
      }
    }
    return _extractKey(chords);
  }

  /// Calculates the key based on the chords of a cipher, and updates the cipher with the new key
  /// Returns the new key
  String _extractKey(List<String> chords) {
    Map<String, int> chordCounts = {};
    Map<String, Chord> chordCache = {};
    for (var chordStr in chords) {
      if (!chordCache.containsKey(chordStr)) {
        try {
          chordCache[chordStr] = Chord.fromString(chordStr);
        } catch (e) {
          continue; // Skip unrecognized chords
        }
      }
      final chord = chordCache[chordStr]!;
      final chordKey = '${chord.root}${chord.quality}';
      chordCounts[chordKey] = (chordCounts[chordKey] ?? 0) + 1;
    }

    Map<String, double> keyScores = {};
    for (var key in ChordHelper.keyList) {
      final chordsOfKey = _chords.getDiatonicChords(key);
      int inPaletteCount = 0;
      for (var chord in chordCounts.keys) {
        if (chordsOfKey.contains(chord)) {
          inPaletteCount += chordCounts[chord]!;
        }
      }
      keyScores[key] = inPaletteCount / chords.length;
    }
    return keyScores.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }
}
