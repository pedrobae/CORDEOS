class DateTimeUtils {
  static String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  static String formatTime(DateTime date) {
    final hours = date.hour.toString().padLeft(2, '0');
    final minutes = date.minute.toString().padLeft(2, '0');
    return '$hours:$minutes';
  }

  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  static DateTime? parseDateTime(String? value) {
    if (value != null && value.isNotEmpty) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  /// Formats a Duration into a human-readable string like "HH:MM:SS"
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    StringBuffer buffer = StringBuffer();

    if (hours > 0) {
      buffer.write('$hours:');
    }
    if (minutes > 0) {
      final minuteStr = minutes.toString().padLeft(2, '0');
      if (buffer.isNotEmpty) {
        buffer.write('$minuteStr:');
      } else {
        buffer.write('$minutes:');
      }
    } else if (buffer.isNotEmpty) {
      buffer.write('00:');
    }
    if (seconds > 0) {
      buffer.write('$seconds'.padLeft(2, '0'));
    } else if (buffer.isNotEmpty) {
      buffer.write('00');
    }

    return buffer.toString();
  }

  /// Parses a duration string in the format "HH:MM:SS" or "MM:SS" into a Duration object
  /// Returns Duration.zero if the string is empty
  static Duration parseDuration(String durationStr) {
    if (durationStr.isEmpty) {
      return Duration.zero;
    }
    final parts = durationStr.split(':').map(int.parse).toList();
    if (parts.length == 3) {
      return Duration(hours: parts[0], minutes: parts[1], seconds: parts[2]);
    } else if (parts.length == 2) {
      return Duration(minutes: parts[0], seconds: parts[1]);
    } else {
      throw FormatException('Invalid duration format');
    }
  }
}
