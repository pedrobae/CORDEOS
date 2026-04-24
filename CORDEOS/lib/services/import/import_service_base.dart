abstract class ImportService {
  /// Extracts raw text from the import source.
  ///
  /// [path] - File path or identifier for the source
  /// Returns the extracted text as a String
  /// Throws exception if extraction fails
  Future<String> extractText(String path) async {
    return path;
  }

  /// Validates if the file/source is accessible and valid
  Future<bool> validate(String path) async {
    return path.isNotEmpty;
  }

  Future<void> dispose() async {}
}
