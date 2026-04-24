class Chord {
  final String root;
  final String quality;
  final String? bass;
  final String? variation;

  const Chord({
    required this.root,
    required this.quality,
    this.bass,
    this.variation,
  });

  /// Parses a chord string into a Chord object
  /// Example: "C#m7/G#" -> Chord(root: "C#", quality: "m", variation: "7", bass: "G#")
  /// Roots -> C, C#, Db, D, D#, Eb, E, F, F#, Gb, G, G#, Ab, A, A#, Bb, B
  /// Quality -> m for minor, dim for diminished, ø for half-diminished
  /// Variation -> 7, maj7, 9, 11, 13, etc.
  factory Chord.fromString(String chordStr) {
    final regex = RegExp(r'^([A-G][b#]?)(m|dim|ø)?(.*?)(?:/(.*))?$');
    final match = regex.firstMatch(chordStr);
    if (match == null) {
      throw FormatException('Invalid chord format: $chordStr');
    }

    return Chord(
      root: match.group(1)!,
      quality: match.group(2) ?? '',
      variation: match.group(3)?.isEmpty == true ? null : match.group(3),
      bass: match.group(4),
    );
  }

  @override
  String toString() {
    String result = root;
    if (quality.isNotEmpty) result += quality;
    if (variation != null) result += variation!;
    if (bass != null) result += '/$bass';
    return result;
  }
}

class ChordHelper {
  const ChordHelper();

  static const List<String> naturalNotes = ['C', 'D', 'E', 'F', 'G', 'A', 'B'];
  static const List<String> accidents = ['b', '#'];

  static const List<String> keyList = [
    'C',
    'Db',
    'D',
    'Eb',
    'E',
    'F',
    'F#',
    'G',
    'Ab',
    'A',
    'Bb',
    'B',
  ];

  /// Generate chords for the current key
  List<String> getDiatonicChords(String key) {
    final Map<String, List<String>> diatonics = {
      'C': ['C', 'Dm', 'Em', 'F', 'G', 'Am', 'Bdim'],
      'Db': ['Db', 'Ebm', 'Fm', 'Gb', 'Ab', 'Bbm', 'Cdim'],
      'D': ['D', 'Em', 'F#m', 'G', 'A', 'Bm', 'C#dim'],
      'Eb': ['Eb', 'Fm', 'Gm', 'Ab', 'Bb', 'Cm', 'Ddim'],
      'E': ['E', 'F#m', 'G#m', 'A', 'B', 'C#m', 'D#dim'],
      'F': ['F', 'Gm', 'Am', 'Bb', 'C', 'Dm', 'Edim'],
      'F#': ['F#', 'G#m', 'A#m', 'B', 'C#', 'D#m', 'E#dim'],
      'G': ['G', 'Am', 'Bm', 'C', 'D', 'Em', 'F#dim'],
      'Ab': ['Ab', 'Bbm', 'Cm', 'Db', 'Eb', 'Fm', 'Gdim'],
      'A': ['A', 'Bm', 'C#m', 'D', 'E', 'F#m', 'G#dim'],
      'Bb': ['Bb', 'Cm', 'Dm', 'Eb', 'F', 'Gm', 'Adim'],
      'B': ['B', 'C#m', 'D#m', 'E', 'F#', 'G#m', 'A#dim'],
    };

    // Return chords for key, or default C major if not found
    return diatonics[key] ?? diatonics['C']!;
  }

  List<String> getMajorChordsForKey(String key) {
    Map<String, List<String>> keyChords = {
      'C': ['C', 'C#', 'D', 'Eb', 'E', 'F', 'F#', 'G', 'G#', 'A', 'Bb', 'B'],
      'Db': ['Db', 'D', 'Eb', 'E', 'F', 'Gb', 'G', 'Ab', 'A', 'Bb', 'B', 'C'],
      'D': ['D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B', 'C', 'C#'],
      'Eb': ['Eb', 'E', 'F', 'Gb', 'G', 'Ab', 'A', 'Bb', 'B', 'C', 'Db', 'D'],
      'E': ['E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B', 'C', 'C#', 'D', 'D#'],
      'F': ['F', 'F#', 'G', 'Ab', 'A', 'Bb', 'B', 'C', 'C#', 'D', 'Eb', 'E'],
      'F#': ['F#', 'G', 'G#', 'A', 'A#', 'B', 'C', 'C#', 'D', 'D#', 'E', 'F'],
      'G': ['G', 'G#', 'A', 'Bb', 'B', 'C', 'C#', 'D', 'D#', 'E', 'F', 'F#'],
      'Ab': ['Ab', 'A', 'Bb', 'B', 'C', 'Db', 'D', 'Eb', 'E', 'F', 'Gb', 'G'],
      'A': ['A', 'A#', 'B', 'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#'],
      'Bb': ['Bb', 'B', 'C', 'Db', 'D', 'Eb', 'E', 'F', 'F#', 'G', 'Ab', 'A'],
      'B': ['B', 'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#'],
    };

    return keyChords[key]!;
  }

  List<String> getChordVariationsOnKey(String key, String chord, int index) {
    final keyChords = getMajorChordsForKey(key);
    int chordIndex = keyChords.indexOf(chord);
    switch (index) {
      case 0:
        return [
          '$chord/${keyChords[(chordIndex + 4) % 12]}',
          '$chord/${keyChords[(chordIndex + 7) % 12]}',
          '${chord}maj7',
          '${chord}9',
        ];
      case 1:
      case 2:
      case 5:
        return ['${chord}7', minorToMajor(chord), '${minorToMajor(chord)}7'];
      case 3:
        return [
          '$chord/${keyChords[(chordIndex + 4) % 12]}',
          '$chord/${keyChords[(chordIndex + 7) % 12]}',
          '${chord}maj7',
          '$chord/${keyChords[(chordIndex + 2) % 12]}',
          '${chord}9',
          '${chord}m',
        ];
      case 4:
        return [
          '${chord}7',
          '$chord/${keyChords[(chordIndex + 4) % 12]}',
          '$chord/${keyChords[(chordIndex + 7) % 12]}',
          '${chord}9',
          '${chord}m',
        ];
      case 6:
        return [
          '${dimToMajor(chord)}ø',
          '${dimToMajor(chord)}m',
          dimToMajor(chord),
          '${dimToMajor(chord)}m/${keyChords[(chordIndex + 3) % 12]}',
        ];
      default:
        return [];
    }
  }

  String transpose(String key, String chord, int value) {
    if (chord.isEmpty || key.isEmpty) {
      return chord;
    }
    final keyChords = getMajorChordsForKey(key);
    int chordIndex = keyChords.indexOf(chord);
    bool weirdChord = false;
    if (chordIndex == -1) {
      // CHORD IS WEIRD
      // FIND THE INDEX OF THE ALTERNATE ACCIDENT
      // AFTERWARD OVERWRITE THE RESULTING CHORD WITH THE ORIGINAL CHORD'S ACCIDENTAL
      weirdChord = true;
      String alternateChord = toggleAccidental(chord);
      chordIndex = keyChords.indexOf(alternateChord);

      if (chordIndex == -1) {
        throw Exception(
          'TRANSPOSER - could not transpose: ($chord or $alternateChord) is not a major chord of key: $key',
        );
      }
    }
    final keyIndex = keyList.indexOf(key);
    if (keyIndex == -1) {
      throw Exception('TRANSPOSER - invalid key: $key');
    }

    int newKeyIndex = (keyIndex + value) % 12;

    String transposed = getMajorChordsForKey(keyList[newKeyIndex])[chordIndex];
    if (weirdChord) {
      // REPLACE THE ACCIDENTAL IN THE TRANSPOSED CHORD WITH THE ORIGINAL CHORD'S ACCIDENTAL
      transposed = toggleAccidental(transposed);
    }

    return transposed;
  }

  String minorToMajor(String chord) {
    if (chord.endsWith('m')) {
      return chord.substring(0, chord.length - 1);
    }
    return chord;
  }

  String dimToMajor(String chord) {
    if (chord.endsWith('dim')) {
      return chord.substring(0, chord.length - 3);
    }
    return chord;
  }

  // SWITCHES SHARPS TO FLATS AND VICE VERSA, CHANGING THE NOTE
  String toggleAccidental(String chord) {
    final Map<String, String> accidents = {
      'C#': 'Db',
      'Db': 'C#',
      'D#': 'Eb',
      'Eb': 'D#',
      'F#': 'Gb',
      'Gb': 'F#',
      'G#': 'Ab',
      'Ab': 'G#',
      'A#': 'Bb',
      'Bb': 'A#',
    };
    return accidents[chord] ?? chord;
  }
}
