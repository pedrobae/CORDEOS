import 'package:flutter/material.dart';
import 'package:cordis/helpers/chords/chords.dart';

class TranspositionProvider extends ChangeNotifier {
  String _originalKey = '';
  String? _transposedKey;

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

  void setTransposedKey(String? newKey) {
    _transposedKey = newKey;
    notifyListeners();
  }

  void setOriginalKey(String newKey) {
    _originalKey = newKey;
    _transposedKey = null;
    notifyListeners();
  }

  void clearTransposer() {
    _transposedKey = null;
    _originalKey = '';
    notifyListeners();
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
    String remainingSuffix = '';

    // Find the longest matching root (handles both C# and C correctly)
    for (final r in ChordHelper.allRoots) {
      if (chord.startsWith(r)) {
        root = r;
        remainingSuffix = chord.substring(r.length);
        break;
      }
    }
    if (root == null) return chord;

    // Parse slash chord if present
    String? bass;
    String chordSuffix = remainingSuffix;

    if (remainingSuffix.contains('/')) {
      final slashIndex = remainingSuffix.indexOf('/');
      chordSuffix = remainingSuffix.substring(0, slashIndex);
      final bassPart = remainingSuffix.substring(slashIndex + 1);

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
      sharpKey: !useSharp,
    );
    String result = transposedRoot + chordSuffix;

    if (bass != null) {
      String transposedBass = ChordHelper().transpose(
        bass,
        _transposeValue,
        sharpKey: !useSharp,
      );
      result += '/$transposedBass';
    }

    return result;
  }
}
