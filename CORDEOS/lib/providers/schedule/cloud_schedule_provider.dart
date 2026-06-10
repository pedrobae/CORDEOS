import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cordeos/models/dtos/schedule_dto.dart';
import 'package:cordeos/providers/schedule/local_schedule_provider.dart';
import 'package:cordeos/repositories/cloud/schedule_repository.dart';
import 'package:cordeos/services/sync_service.dart';
import 'package:cordeos/utils/firebase_error_mapper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CloudScheduleProvider extends ChangeNotifier {
  final _repo = CloudScheduleRepository();
  final _syncService = ScheduleSyncService();

  CloudScheduleProvider();

  final Map<String, ScheduleDto> _schedules = {};

  String _searchTerm = '';

  String? _error;
  dynamic _lastException;

  bool _isLoading = false;
  bool _isSaving = false;
  bool _isSyncing = false;

  final List<ScheduleDto> _syncQueue = [];
  final Map<String, DateTime> _lastSyncTimes = {};

  // ===== GETTERS =====
  Map<String, ScheduleDto> get schedules => _schedules;

  String? get error => _error;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isSyncing => _isSyncing;

  bool syncingStatus({String? firebaseScheduleID, String? shareCode}) =>
      _syncQueue.any(
        (s) => s.firebaseId == firebaseScheduleID || s.shareCode == shareCode,
      );

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
        .where((id) => _schedules[id]!.timestamp.compareTo(now) >= 0)
        .toList();
  }

  List<String> get pastScheduleIDs {
    final now = Timestamp.now();
    return filteredScheduleIds
        .where((id) => _schedules[id]!.timestamp.compareTo(now) < 0)
        .toList();
  }

  ScheduleDto? getSchedule(String scheduleId) {
    return _schedules[scheduleId];
  }

  /// Get localized error message based on the stored exception
  String getLocalizedError(BuildContext context) {
    if (_lastException == null) {
      return _error ?? 'An error occurred';
    }
    return FirebaseErrorMapper.mapErrorToUserMessage(context, _lastException);
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
    _lastException = null;
    _schedules.clear();
    notifyListeners();

    try {
      final schedules = await _repo.fetchSchedulesByUserId(
        userId,
        forceFetch: forceFetch,
      );

      for (var schedule in schedules) {
        if (schedule.ownerFirebaseId == userId && schedule.firebaseId != null) {
          if ((forceFetch || _oldSync(schedule.firebaseId!)) &&
              context.mounted) {
            _syncQueue.add(schedule);
            notifyListeners();
            _syncQueueListener(context);
          }
        } else {
          _schedules[schedule.firebaseId!] = schedule;
        }
      }
    } catch (e) {
      debugPrint('Error loading schedules: $e');
      _lastException = e;
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _syncOwnedSchedule(
    BuildContext context,
    ScheduleDto schedule,
  ) async {
    _isSyncing = true;
    notifyListeners();

    try {
      final localID = await _syncService.scheduleToLocal(schedule);
      _lastSyncTimes[schedule.firebaseId!] = DateTime.now();
      _schedules.remove(schedule.firebaseId!);
      // Trigger local provider load.
      if (context.mounted) {
        final localScheduleProvider = context.read<LocalScheduleProvider>();
        localScheduleProvider.loadSchedule(localID);
      }
    } catch (e) {
      debugPrint('Error syncing owned schedule ${schedule.firebaseId!}: $e');
    } finally {
      _syncQueue.remove(schedule);
      _isSyncing = false;
      notifyListeners();
    }
    if (_syncQueue.isNotEmpty) {
      _syncQueueListener(context);
    }
  }

  void _syncQueueListener(BuildContext context) {
    if (_syncQueue.isNotEmpty && !isSyncing) {
      _syncOwnedSchedule(context, _syncQueue.first);
    }
  }

  /// Fetches a schedule by its cloud ID
  Future<void> loadSchedule(String scheduleId) async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    _lastException = null;
    notifyListeners();

    try {
      final schedule = await _repo.fetchScheduleById(scheduleId);
      if (schedule != null) {
        _schedules[scheduleId] = schedule;
      } else {
        throw Exception('Schedule not found');
      }
    } catch (e) {
      _lastException = e;
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
    _lastException = null;
    notifyListeners();

    try {
      if (userId == _schedules[scheduleId]!.ownerFirebaseId) {
        await _repo.deleteSchedule(scheduleId, userId);
      }

      _schedules.remove(scheduleId);
    } catch (e) {
      _lastException = e;
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
    _syncQueue.clear();
    _searchTerm = '';
    _error = null;
    _lastException = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    _lastException = null;
    notifyListeners();
  }

  Future<bool> joinScheduleWithCode(String shareCode) async {
    bool success = false;

    if (_isLoading) return success;

    _isLoading = true;
    _error = null;
    _lastException = null;
    notifyListeners();

    try {
      success = await _repo.joinWithCode(shareCode);
    } catch (e) {
      _lastException = e;
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
