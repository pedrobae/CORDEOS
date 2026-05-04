import 'package:cordeos/helpers/chords.dart';
import 'package:cordeos/models/domain/cipher/cipher.dart';
import 'package:cordeos/models/domain/cipher/section.dart';
import 'package:cordeos/models/domain/cipher/version.dart';
import 'package:cordeos/utils/date_utils.dart';
import 'package:cordeos/utils/section_type.dart';

class SongHelper {
  static String convertToChordPro(
    Cipher cipher,
    Version version,
    Map<int, Section> sections,
  ) {
    final buffer = StringBuffer();

    // ================ METADATA =====================
    buffer.writeln('{title: ${cipher.title}}');
    if (cipher.author.isNotEmpty) {
      buffer.writeln('{artist: ${cipher.author}}');
    }
    if ((version.transposedKey != null && version.transposedKey!.isNotEmpty) ||
        cipher.musicKey.isNotEmpty) {
      buffer.writeln('{key: ${version.transposedKey ?? cipher.musicKey}}');
    }
    if (version.duration != Duration.zero) {
      buffer.writeln(
        '{duration: ${DateTimeUtils.formatDuration(version.duration)}}',
      );
    }
    if (version.bpm != 0) {
      buffer.writeln('{tempo: ${version.bpm}}');
    }
    if ((version.transposedKey != null && version.transposedKey!.isNotEmpty) &&
        cipher.musicKey.isNotEmpty) {
      int indexOriginal = ChordHelper.keyList.indexOf(cipher.musicKey);
      int indexTransposed = ChordHelper.keyList.indexOf(version.transposedKey!);

      if (indexOriginal != -1 && indexTransposed != -1) {
        final value = (indexTransposed - indexOriginal) % 12;

        buffer.writeln('{transpose: $value}');
      }
    }

    // links
    if (cipher.links.isNotEmpty ||
        (version.notes != null && version.notes!.isNotEmpty)) {
      buffer.writeln('{comment: ');
      for (final link in cipher.links) {
        if (link.isNotEmpty) {
          buffer.writeln('\t${link.trim()}');
        }
      }
      if (version.notes != null && version.notes!.isNotEmpty) {
        buffer.write(version.notes);
      }
      buffer.writeln('}');
    }

    for (final key in version.songStructure) {
      buffer.writeln();
      _writeChordProSection(buffer, sections[key]!);
    }

    return buffer.toString();
  }

  static String convertToRegularText(
    Cipher cipher,
    Version version,
    Map<int, Section> sections,
  ) {
    final buffer = StringBuffer();

    // ================ METADATA =====================
    buffer.writeln('Title: ${cipher.title}');
    if (cipher.author.isNotEmpty) {
      buffer.writeln('Artist: ${cipher.author}');
    }
    if ((version.transposedKey != null && version.transposedKey!.isNotEmpty) ||
        cipher.musicKey.isNotEmpty) {
      buffer.writeln('Key: ${version.transposedKey ?? cipher.musicKey}');
    }
    if (version.bpm != 0) {
      buffer.writeln('BPM: ${version.bpm}');
    }

    buffer.writeln();

    // ======================= CONTENT ========================
    for (final key in version.songStructure) {
      _writeHolyricsSection(
        buffer,
        sections[key]!,
        cipher.musicKey,
        version.transposedKey,
      );
      buffer.writeln();
    }
    // extras
    if (cipher.links.isNotEmpty ||
        (version.notes != null && version.notes!.isNotEmpty) ||
        (version.duration != Duration.zero)) {
      buffer.writeln('--extras--');
      if (version.duration != Duration.zero) {
        buffer.writeln(
          'Duration: ${DateTimeUtils.formatDuration(version.duration)}',
        );
      }
      for (final link in cipher.links) {
        if (link.isNotEmpty) {
          buffer.writeln('\t${link.trim()}');
        }
      }
      if (version.notes != null && version.notes!.isNotEmpty) {
        buffer.writeln(version.notes);
      }
    }

    return buffer.toString();
  }

  static void _writeChordProSection(StringBuffer buffer, Section section) {
    buffer.writeln(
      '{start_of_${section.sectionType.canonicalLabel}: label="${section.contentType}"}',
    );
    buffer.writeln(section.contentText);
    buffer.writeln('{end_of_${section.sectionType.canonicalLabel}}');
  }

  static void _writeHolyricsSection(
    StringBuffer buffer,
    Section section,
    String originalKey,
    String? transposedKey,
  ) {
    final lines = section.contentText.split('\n');

    for (final line in lines) {
      final commentLine = StringBuffer('//');
      final lyricLine = StringBuffer();
      for (int i = 0; i < line.trim().length; i++) {
        final char = line[i];
        if (char == '[') {
          i++;
          // Start parsing chord
          final chord = StringBuffer();
          while (line[i] != ']' && i < line.length) {
            chord.write(line[i]);
            i++;
          }
          if (i + 1 < line.length && line[i + 1] != '[') i++;

          commentLine.write(
            ChordHelper().transposeChord(
              originalKey: originalKey,
              newKey: transposedKey,
              chord: chord.toString(),
            ),
          );
          if (i < line.length && line[i] != ']') lyricLine.write(line[i]);
        } else {
          commentLine.write(' ');
          lyricLine.write(char);
        }
      }
      if (commentLine.isNotEmpty) buffer.writeln(commentLine);
      if (lyricLine.isNotEmpty) buffer.writeln(lyricLine);
    }
  }
}
