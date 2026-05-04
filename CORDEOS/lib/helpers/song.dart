import 'package:cordeos/helpers/chords/chords.dart';
import 'package:cordeos/models/domain/cipher/cipher.dart';
import 'package:cordeos/models/domain/cipher/section.dart';
import 'package:cordeos/models/domain/cipher/version.dart';
import 'package:cordeos/utils/date_utils.dart';
import 'package:cordeos/utils/section_type.dart';
import 'package:flutter/material.dart';

class SongHelper {
  static String convertToChordPro(
    Cipher cipher,
    Version version,
    Map<int, Section> sections,
    BuildContext context,
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
          buffer.writeln('\t\t${link.trim()}');
        }
      }
      if (version.notes != null && version.notes!.isNotEmpty) {
        buffer.write(version.notes);
      }
      buffer.writeln('}');
    }

    for (final key in version.songStructure) {
      buffer.writeln();
      _writeSection(buffer, sections[key]!);
    }

    return buffer.toString();
  }

  static String convertToRegularText(String chordPro) {
    final result = StringBuffer();

    return result.toString();
  }

  static void _writeSection(StringBuffer buffer, Section section) {
    buffer.writeln(
      '{start_of_${section.sectionType.canonicalLabel}: label="${section.contentType}"}',
    );
    buffer.writeln(section.contentText);
    buffer.writeln('{end_of_${section.sectionType.canonicalLabel}}');
  }
}
