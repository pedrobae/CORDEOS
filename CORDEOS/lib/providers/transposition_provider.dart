import 'package:flutter/material.dart';
import 'package:cordeos/helpers/chords/chords.dart';

class TranspositionProvider extends ChangeNotifier {
  String _originalKey = '';
  String? _transposedKey;
  int _versionID = -1;

  bool get useSharp => _transposedKey != null && _transposedKey!.contains('#');

  int get _transposeValue {
    if (_transposedKey == null) return 0;

    int indexOriginal = ChordHelper.keyList.indexOf(_originalKey);
    int indexTransposed = ChordHelper.keyList.indexOf(_transposedKey!);

    if (indexOriginal == -1 || indexTransposed == -1) return 0;

    return (indexTransposed - indexOriginal) % 12;
  }

  String get originalKey => _originalKey;
  String? get transposedKey => _transposedKey;
  int get versionID => _versionID;

  void setTransposedKey(String? newKey) {
    _transposedKey = newKey;
    notifyListeners();
  }

  void setOriginalKey(String newKey, int versionID) {
    _originalKey = newKey;
    _transposedKey = null;
    _versionID = versionID;
    notifyListeners();
  }

  void clearTransposer() {
    _transposedKey = null;
    _originalKey = '';
    _versionID = -1;
  }

  void transposeUp() {
    int index = ChordHelper.keyList.indexOf(_transposedKey ?? _originalKey);
    if (index == -1) return;
    int newIndex = (index + 1) % ChordHelper.keyList.length;
    _transposedKey = ChordHelper.keyList[newIndex];
    notifyListeners();
  }

  void transposeDown() {
    int index = ChordHelper.keyList.indexOf(_transposedKey ?? _originalKey);
    if (index == -1) return;
    int newIndex = index - 1;
    if (newIndex < 0) newIndex += ChordHelper.keyList.length;
    _transposedKey = ChordHelper.keyList[newIndex];
    notifyListeners();
  }

  String transposeChord(String chord) {
    // Parse chord root first
    String? root;
    String suffix = '';
    String prefix = '';

    String preSlash;
    String postSlash = '';
    if (chord.contains('/')) {
      final parts = chord.split('/');
      preSlash = parts[0];
      for (int i = 1; i < parts.length; i++) {
        postSlash = '$postSlash/${parts[i]}';
      }
    } else {
      preSlash = chord;
    }

    // Find the longest matching root (handles both C# and C correctly)
    for (final r in ChordHelper.allRoots) {
      if (preSlash.contains(r)) {
        root = r;
        final index = preSlash.indexOf(r);
        suffix = '${preSlash.substring(index + r.length)}$postSlash';
        prefix = preSlash.substring(0, index);
        break;
      }
    }
    if (root == null) return chord;

    // Parse slash chord if present
    String? bass;
    String chordSuffix = suffix;

    if (suffix.contains('/')) {
      final slashIndex = suffix.indexOf('/');
      chordSuffix = suffix.substring(0, slashIndex);
      final bassPart = suffix.substring(slashIndex + 1);

      // Find bass note (should match exactly or be at the start)
      for (final r in ChordHelper.allRoots) {
        if (bassPart == r || bassPart.startsWith(r)) {
          bass = r;
          break;
        }
      }
    }

    // Transpose root and bass
    String transposedRoot = ChordHelper().transpose(
      root,
      _transposeValue,
      sharpKey: useSharp,
    );
    String result = prefix + transposedRoot + chordSuffix;

    if (bass != null) {
      String transposedBass = ChordHelper().transpose(
        bass,
        _transposeValue,
        sharpKey: useSharp,
      );
      result += '/$transposedBass';
    }

    return result;
  }
}
