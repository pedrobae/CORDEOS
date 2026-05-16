import 'dart:io';

import 'package:excel/excel.dart';

enum Field {
  content,
  title,
  author,
  key,
  bpm,
  duration,
  language,
  tags,
  links,
  annotations,
}

extension FieldMethods on Field {
  List<String> get knownLabels {
    switch (this) {
      case Field.content:
        return ['content', 'conteudo', 'conteúdo', 'música', 'song'];
      case Field.title:
        return ['title', 'titulo', 'nome', 'name'];
      case Field.author:
        return [
          'author',
          'autor',
          'artist',
          'artista',
          'writer',
          'composer',
          'escritor',
          'compositor',
        ];
      case Field.key:
        return ['tom', 'key', 'music key'];
      case Field.bpm:
        return ['bpm', 'tempo', 'pace'];
      case Field.duration:
        return ['duration', 'time', 'duração', 'duracao'];
      case Field.language:
        return ['language', 'lingua', 'idioma'];
      case Field.tags:
        return ['tags'];
      case Field.links:
        return ['links'];
      case Field.annotations:
        return ['annotations', 'anotações', 'notas', 'notes', 'anotacoes'];
    }
  }
}

class SpreadsheetLine {
  final String content;
  final String title;
  String? author;
  String? key;
  int? bpm;
  int? duration;
  String? language;
  List<String> tags;
  List<String> links;
  String? annotations;

  SpreadsheetLine({
    required this.content,
    required this.title,
    this.author,
    this.key,
    this.bpm,
    this.duration,
    this.language,
    this.tags = const [],
    this.links = const [],
    this.annotations,
  });

  Map<String, dynamic> get metadata => {
    'title': title,
    'author': author,
    'key': key,
    'bpm': bpm,
    'duration': duration,
    'language': language,
    'tags': tags,
    'links': links,
    'annotations': annotations,
  };
}

class SpreadsheetImportService {
  Future<List<SpreadsheetLine>> extractData(String path) async {
    final lines = <SpreadsheetLine>[];
    if (!await validate(path)) return lines;
    final extension = path.toLowerCase().substring(path.lastIndexOf('.'));

    if (extension == '.xlsx') {
      // String column index -> field
      Map<Field, int> fieldIdx = {};
      bool setLabels = false;
      var bytes = File(path).readAsBytesSync();
      final excel = Excel.decodeBytes(bytes);
      for (var table in excel.tables.values) {
        for (var row in table.rows) {
          if (!setLabels) {
            for (var cell in row) {
              if (cell == null) continue;
              for (final field in Field.values) {
                if (fieldIdx.containsValue(field)) break;
                for (final label in field.knownLabels) {
                  if (label == cell.value.toString().toLowerCase()) {
                    fieldIdx[field] = cell.columnIndex;
                    break;
                  }
                }
              }
            }
            setLabels = true;
            continue;
          }

          if (fieldIdx.containsKey(Field.content) &&
              fieldIdx.containsKey(Field.title)) {
            final line = SpreadsheetLine(
              content:
                  row.elementAt(fieldIdx[Field.content]!)?.value.toString() ??
                  '',
              title:
                  row.elementAt(fieldIdx[Field.title]!)?.value.toString() ?? '',
            );

            for (final field in fieldIdx.keys) {
              switch (field) {
                case Field.content:
                case Field.title:
                  // Already  included in line creation
                  break;
                case Field.author:
                  line.author = row
                      .elementAt(fieldIdx[field]!)
                      ?.value
                      .toString();
                  break;
                case Field.key:
                  line.key = row.elementAt(fieldIdx[field]!)?.value.toString();
                  break;
                case Field.bpm:
                  line.bpm = int.tryParse(
                    row.elementAt(fieldIdx[field]!)?.value.toString() ?? '',
                  );
                  break;
                case Field.duration:
                  final value = row.elementAt(fieldIdx[field]!)?.value;
                  if (value is TimeCellValue) {
                    line.duration = value.asDuration().inSeconds;
                  }
                  break;
                case Field.language:
                  line.language = row
                      .elementAt(fieldIdx[field]!)
                      ?.value
                      .toString();
                  break;
                case Field.tags:
                  line.tags =
                      row
                          .elementAt(fieldIdx[field]!)
                          ?.value
                          .toString()
                          .split(',') ??
                      [];
                  break;
                case Field.links:
                  line.links =
                      row
                          .elementAt(fieldIdx[field]!)
                          ?.value
                          .toString()
                          .split(',') ??
                      [];
                  break;
                case Field.annotations:
                  line.annotations = row
                      .elementAt(fieldIdx[field]!)
                      ?.value
                      .toString();
                  break;
              }
            }
            lines.add(line);
          }
        }
      }
    }
    return lines;
  }

  /// Validates that the image file exists and has valid image extension
  Future<bool> validate(String path) async {
    final validExtensions = ['.csv', '.xlsx'];
    final extension = path.toLowerCase().substring(path.lastIndexOf('.'));

    if (!validExtensions.contains(extension)) {
      return false;
    }

    final file = File(path);
    return await file.exists();
  }
}
