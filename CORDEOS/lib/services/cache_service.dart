import 'dart:convert';
import 'package:cordeos/models/dtos/schedule_dto.dart';
import 'package:cordeos/models/dtos/version_dto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static const _versionKey = 'cloudVersions';
  static const _lastVersionLoad = 'lastVersionLoad';

  static const _schedulesKey = 'schedules';

  Future<void> saveCloudSchedules(List<ScheduleDto> schedules) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = schedules.map((s) => s.toCache()).toList();
    await prefs.setString(_schedulesKey, json.encode(jsonList));
  }

  Future<List<ScheduleDto>> loadCloudSchedules() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_schedulesKey);
      if (jsonString == null) return [];
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((j) => ScheduleDto.fromCache(j)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveCloudVersions(List<VersionDto> versions) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = versions.map((v) => v.toCache()).toList();
    await prefs.setString(_versionKey, json.encode(jsonList));
  }

  Future<List<VersionDto>> loadCloudVersions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_versionKey);
      if (jsonString == null) return [];
      final List<dynamic> jsonList = json.decode(jsonString);
      return jsonList.map((j) => VersionDto.fromCache(j)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> saveLastCloudLoad(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastVersionLoad, time.millisecondsSinceEpoch);
  }

  Future<DateTime?> loadLastCloudLoad() async {
    final prefs = await SharedPreferences.getInstance();
    final millis = prefs.getInt(_lastVersionLoad);
    if (millis != null) {
      return DateTime.fromMillisecondsSinceEpoch(millis);
    }
    return null;
  }

  Future<void> clearAllCaches() async {
    final prefs = await SharedPreferences.getInstance();
    // Clear all caches
    final keys = prefs.getKeys();
    for (var key in keys) {
      await prefs.remove(key);
    }
  }
}
