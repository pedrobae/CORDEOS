import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cordeos/models/dtos/schedule_dto.dart';
import 'package:cordeos/providers/schedule/local_schedule_provider.dart';
import 'package:cordeos/repositories/cloud/schedule_repository.dart';
import 'package:cordeos/services/sync_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CloudScheduleProvider extends ChangeNotifier {
  final _repo = CloudScheduleRepository();
  final _syncService = ScheduleSyncService();

  CloudScheduleProvider();

  final Map<String, ScheduleDto> _schedules = {};

  String _searchTerm = '';

  String? _error;

  bool _isLoading = false;
  bool _isSaving = false;

  final Map<String, bool> _isSyncing = {};
  final Map<String, DateTime> _lastSyncTimes = {};

  // ===== GETTERS =====
  Map<String, ScheduleDto> get schedules => _schedules;

  String? get error => _error;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;

  bool syncingStatus(String scheduleId) => _isSyncing[scheduleId] ?? false;

  List<String> get filteredScheduleIds {
    if (_searchTerm.isEmpty) {
      return _schedules.keys.toList();
    } else {
      final List<String> tempIds = [];
      for (var entry in _schedules.entries) {
        if (entry.value.name.toLowerCase().contains(_searchTerm) ||
            entry.value.location.toLowerCase().contains(_searchTerm)) {
          tempIds.add(entry.key);
        }
      }
      return tempIds;
    }
  }

  List<String> get futureScheduleIDs {
    final now = Timestamp.now();
    return filteredScheduleIds
        .where((id) => _schedules[id]!.datetime.compareTo(now) >= 0)
        .toList();
  }

  List<String> get pastScheduleIDs {
    final now = Timestamp.now();
    return filteredScheduleIds
        .where((id) => _schedules[id]!.datetime.compareTo(now) < 0)
        .toList();
  }

  ScheduleDto? getSchedule(String scheduleId) {
    return _schedules[scheduleId];
  }

  // ===== READ =====
  /// Fetches all schedules from the cloud repository (user has to be a collaborator)
  Future<void> loadSchedules(
    BuildContext context,
    String userId, {
    bool forceFetch = false,
  }) async {
    if (_isLoading && !forceFetch) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final schedules = await _repo.fetchSchedulesByUserId(
        userId,
        forceFetch: forceFetch,
      );

      for (var schedule in schedules) {
        _schedules[schedule.firebaseId!] = schedule;
      }
    } catch (e) {
      debugPrint('Error loading schedules: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    // Keep loading state scoped to cloud fetch only.
    // Owner schedule sync can be slow and should not block the screen loader.
    for (final schedule in _schedules.values.toList()) {
      if (schedule.ownerFirebaseId == userId && schedule.firebaseId != null) {
        if ((forceFetch || _oldSync(schedule.firebaseId!)) && context.mounted) {
          unawaited(_syncOwnedSchedule(context, schedule));
        } else {
          _schedules.remove(schedule.firebaseId!);
        }
      }
    }
  }

  Future<void> _syncOwnedSchedule(
    BuildContext context,
    ScheduleDto schedule,
  ) async {
    final scheduleId = schedule.firebaseId!;

    _isSyncing[scheduleId] = true;
    notifyListeners();

    try {
      final localID = await _syncService.scheduleToLocal(schedule);
      _lastSyncTimes[scheduleId] = DateTime.now();
      _schedules.remove(scheduleId);
      // Trigger local provider load.
      if (context.mounted) {
        final localScheduleProvider = context.read<LocalScheduleProvider>();
        localScheduleProvider.loadSchedule(localID);
      }
    } catch (e) {
      debugPrint('Error syncing owned schedule $scheduleId: $e');
    } finally {
      _isSyncing[scheduleId] = false;
      notifyListeners();
    }
  }

  /// Fetches a schedule by its cloud ID
  Future<void> loadSchedule(String scheduleId) async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final schedule = await _repo.fetchScheduleById(scheduleId);
      if (schedule != null) {
        _schedules[scheduleId] = schedule;
      } else {
        throw Exception('Schedule not found');
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ===== DELETE =====
  /// Delete a schedule from the cache and in Firestore
  Future<void> deleteSchedule(String userId, String scheduleId) async {
    if (_isSaving) return;

    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      if (userId == _schedules[scheduleId]!.ownerFirebaseId) {
        await _repo.deleteSchedule(scheduleId, userId);
      }

      _schedules.remove(scheduleId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isSaving = false;
    }
    notifyListeners();
  }

  // ===== HELPERS =====
  void clearCache() {
    _schedules.clear();
    _isLoading = false;
    _isSaving = false;
    _isSyncing.clear();
    _searchTerm = '';
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void startSyncing(String scheduleId) {
    _isSyncing[scheduleId] = true;
    notifyListeners();
  }

  void stopSyncing(String scheduleId) {
    _isSyncing[scheduleId] = false;
    notifyListeners();
  }

  Future<bool> joinScheduleWithCode(String shareCode) async {
    bool success = false;

    if (_isLoading) return success;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      success = await _repo.joinWithCode(shareCode);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return success;
  }

  bool _oldSync(String scheduleId) {
    return (_lastSyncTimes[scheduleId] == null ||
        DateTime.now().difference(_lastSyncTimes[scheduleId]!) >
            const Duration(minutes: 30));
  }

  // ===== SEARCH & FILTER =====
  void setSearchTerm(String searchTerm) {
    _searchTerm = searchTerm.toLowerCase();
    notifyListeners();
  }
}
