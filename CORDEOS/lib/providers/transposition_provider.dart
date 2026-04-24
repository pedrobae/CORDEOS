import 'package:flutter/material.dart';
import 'package:cordeos/helpers/chords/chords.dart';

class TranspositionProvider extends ChangeNotifier {
  String _originalKey = '';
  String? _transposedKey;
  int _versionID = -1;

  bool get useFlat =>
      _transposedKey != null && _transposedKey!.contains('b') ||
      _transposedKey == 'F';

  int get transposeValue {
    if (_transposedKey == null) return 0;

    int indexOriginal = ChordHelper.keyList.indexOf(_originalKey);
    int indexTransposed = ChordHelper.keyList.indexOf(_transposedKey!);

    if (indexOriginal == -1 || indexTransposed == -1) return -1;

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
    final result = StringBuffer();
    String root;
    String prefix;
    String suffix = chord;

    while (suffix.isNotEmpty) {
      (root, prefix, suffix) = _extractRoot(suffix);

      result.write(prefix);
      // Write transposed root
      result.write(
        ChordHelper().transpose(originalKey, root.toString(), transposeValue),
      );
    }
    return result.toString();
  }

  (String root, String prefix, String suffix) _extractRoot(String chord) {
    final root = StringBuffer();
    String prefix = '';
    // Find the first natural note
    int i = -1;
    while (i < chord.length - 1) {
      i++;
      final char = chord[i];
      if (ChordHelper.naturalNotes.contains(char)) {
        root.write(char);
        prefix = chord.substring(0, i);
        break;
      }
    }
    i++;
    if (root.isNotEmpty) {
      if (i < chord.length) {
        final nextChar = chord[i];
        if (ChordHelper.accidents.contains(nextChar)) {
          root.write(nextChar);
          i++;
        }
      }
    } else {
      prefix = chord;
    }

    final suffix = (i < chord.length) ? chord.substring(i) : '';

    return (root.toString(), prefix, suffix);
  }
}
