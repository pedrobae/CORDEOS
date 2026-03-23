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

  static const List<String> allRoots = [
    'C#',
    'Db',
    'D#',
    'Eb',
    'F#',
    'Gb',
    'G#',
    'Ab',
    'A#',
    'Bb',
    'C', 'D', 'E', 'F', 'G', 'A', 'B', // Ordered to match semitone steps
  ];

  List<String> getChordRoots(bool useSharps) => [
    'C',
    useSharps ? 'C#' : 'Db',
    'D',
    useSharps ? 'D#' : 'Eb',
    'E',
    'F',
    useSharps ? 'F#' : 'Gb',
    'G',
    useSharps ? 'G#' : 'Ab',
    'A',
    useSharps ? 'A#' : 'Bb',
    'B',
  ];

  /// Generate chords for the current key
  List<String> getChordsForKey(String key) {
    final Map<String, List<String>> keyChords = {
      'C': ['C', 'Dm', 'Em', 'F', 'G', 'Am', 'Bdim'],
      'Db': ['Db', 'Ebm', 'Fm', 'Gb', 'Ab', 'Bbm', 'Cdim'],
      'D': ['D', 'Em', 'Fbm', 'G', 'A', 'Bm', 'Cbdim'],
      'Eb': ['Eb', 'Fm', 'Gm', 'Ab', 'Bb', 'Cm', 'Ddim'],
      'E': ['E', 'Fbm', 'Gbm', 'A', 'B', 'Cbm', 'Dbdim'],
      'F': ['F', 'Gm', 'Am', 'Bb', 'C', 'Dm', 'Edim'],
      'F#': ['G#', 'A#m', 'B#m', 'C#', 'D#', 'E#m', 'Fdim'],
      'G': ['G', 'Am', 'Bm', 'C', 'D', 'Em', 'Fbdim'],
      'Ab': ['Ab', 'Bbm', 'Cm', 'Db', 'Eb', 'Fm', 'Gdim'],
      'A': ['A', 'Bm', 'Cbm', 'D', 'E', 'Fbm', 'Gbdim'],
      'Bb': ['Bb', 'Cm', 'Dm', 'Eb', 'F', 'Gm', 'Adim'],
      'B': ['B', 'Cbm', 'Dbm', 'E', 'Fb', 'Gbm', 'Abdim'],
    };

    // Return chords for key, or default C major if not found
    return keyChords[key] ?? keyChords['C']!;
  }

  List<String> getVariationsForChord(String chord, int index) {
    bool sharpKey = chord.contains('#');

    switch (index) {
      case 0:
        return [
          '$chord/${transpose(chord, 4, sharpKey: sharpKey)}',
          '$chord/${transpose(chord, 7, sharpKey: sharpKey)}',
          '${chord}maj7',
          '${chord}9',
        ];
      case 1:
      case 2:
      case 5:
        return ['${chord}7', minorToMajor(chord), '${minorToMajor(chord)}7'];
      case 3:
        return [
          '$chord/${transpose(chord, 4, sharpKey: sharpKey)}',
          '$chord/${transpose(chord, 7, sharpKey: sharpKey)}',
          '${chord}maj7',
          '$chord/${transpose(chord, 2, sharpKey: sharpKey)}',
          '${chord}9',
          '${chord}m',
        ];
      case 4:
        return [
          '${chord}7',
          '$chord/${transpose(chord, 4, sharpKey: sharpKey)}',
          '$chord/${transpose(chord, 7, sharpKey: sharpKey)}',
          '${chord}9',
          '${chord}m',
        ];
      case 6:
        return [
          '${dimToMajor(chord)}ø',
          '${dimToMajor(chord)}m',
          dimToMajor(chord),
          '${dimToMajor(chord)}m/${transpose(dimToMajor(chord), 3, sharpKey: sharpKey)}',
        ];
      default:
        return [];
    }
  }

  String transpose(String chord, int value, {required bool sharpKey}) {
    final sharpChord = chord.contains('#');
    final chordChrom = getChordRoots(sharpChord);
    int chordIndex = chordChrom.indexOf(chord);
    if (chordIndex == -1) {
      throw ArgumentError('Chord not found in its own chromatic scale: $chord');
    }
    int newIndex = (chordIndex + value) % 12;

    final keyChrom = getChordRoots(sharpKey);
    return keyChrom[newIndex];
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
}
