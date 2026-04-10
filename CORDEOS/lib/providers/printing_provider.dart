import 'package:cordeos/models/dtos/song_pdf_dto.dart';
import 'package:cordeos/providers/token_cache_provider.dart';
import 'package:cordeos/repositories/local/cipher_repository.dart';
import 'package:cordeos/repositories/local/section_repository.dart';
import 'package:cordeos/repositories/local/version_repository.dart';
import 'package:cordeos/services/tokenization/helper_classes.dart';
import 'package:cordeos/utils/token_cache_keys.dart';
import 'package:flutter/material.dart';

class PrintingProvider {
  final ciph = CipherRepository();
  final localVer = LocalVersionRepository();
  final sect = SectionRepository();

  final _tokenize = TokenProvider();

  Future<SongPdfDto> buildSongPdfDto({
    required int versionID,
    required TextStyle lyricStyle,
    required TextStyle chordStyle,
    required TextStyle metadataStyle,
  }) async {
    final version = await localVer.getVersionWithId(versionID);

    if (version == null) {
      throw Exception('Version not found for ID: $versionID');
    }

    final cipher = await ciph.getCipherById(version.cipherID);
    if (cipher == null) {
      throw Exception('Cipher not found for ID: ${version.cipherID}');
    }

    final sections = await sect.getSections(versionID);
    if (sections.length != version.songStructure.toSet().length) {
      throw Exception(
        'Mismatch between song structure and sections for version ID: $versionID',
      );
    }

    // TOKENIZATION
    final Map<String, TokenPositionMap> content = {};
    for (int i = 0; i < sections.length; i++) {
      final contentCode = version.songStructure.toSet().elementAt(i);
      final section = sections[contentCode];

      if (section == null) {
        throw Exception(
          'Section with code $contentCode not found for version ID: $versionID',
        );
      }

      final TokenCacheKey key = TokenCacheKey(
        sectionIndex: i,
        content: section.contentText,
        maxWidth:
            100, // TODO: This should be calculated based on the PDF layout, not hardcoded
        lineSpacing: 0,
        lineBreakSpacing: 0,
        chordLyricSpacing: 0,
        minChordSpacing: 5,
        letterSpacing: 0,
        showChords: true,
        showLyrics: true,
        isEditMode: false,
        transposeValue: 0,
        chordColor: Colors.deepOrange,
        lyricColor: Colors.black,
      );

      _tokenize.tokenize(
        key,
        transposeChord: (chord) {
          return chord;
        },
      );

      _tokenize.organize(key);
      _tokenize.measureTokens(
        chordStyle: chordStyle,
        lyricStyle: lyricStyle,
        key: key,
      );
      _tokenize.calculatePositions(
        key: key,
        lyricStyle: lyricStyle,
        chordStyle: chordStyle,
      );
    }

    return SongPdfDto(
      title: cipher.title,
      author: cipher.author,
      musicKey: cipher.musicKey,
      language: cipher.language,
      duration: version.duration,
      bpm: version.bpm,
      songStructure: version.songStructure,
      content: content,
      tokenMeasurements: _tokenize.getMeasurements(),
      lyricsStyle: lyricStyle,
      chordsStyle: chordStyle,
      metadataStyle: metadataStyle,
    );
  }
}
