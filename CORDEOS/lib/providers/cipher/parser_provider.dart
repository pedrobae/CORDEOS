import 'package:cordeos/models/dtos/version_dto.dart';
import 'package:cordeos/models/domain/parsing_cipher.dart';
import 'package:cordeos/services/parsing/parsing_service_base.dart';
import 'package:flutter/material.dart';

class ParserProvider extends ChangeNotifier {
  final ParsingServiceBase _parsingService = ParsingServiceBase();

  // Chosen Cipher after parsing
  bool _isParsing = false;
  bool get isParsing => _isParsing;

  String _error = '';
  String get error => _error;

  Future<VersionDto?> parseCipher(ParsingCipher importedCipher) async {
    VersionDto? song;
    if (_isParsing) return song;

    _isParsing = true;
    _error = '';
    notifyListeners();

    try {
      /// ===== PARSING STEPS =====
      final result = _parsingService.parse(importedCipher.result);
      song = _parsingService.buildVersionFromResult(result);
      _isParsing = false;
      notifyListeners();
    } catch (e) {
      _error = 'Error during parsing: $e';
      _isParsing = false;
      notifyListeners();
    }
    return song;
  }

  void clearCache() {
    _isParsing = false;
    _error = '';
  }
}
