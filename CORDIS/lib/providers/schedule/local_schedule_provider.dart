import 'package:cordis/helpers/codes.dart';
import 'package:cordis/models/domain/schedule.dart';
import 'package:cordis/models/domain/user.dart';
import 'package:cordis/repositories/local/schedule_repository.dart';
import 'package:cordis/services/sync_service.dart';
import 'package:flutter/material.dart';

class LocalScheduleProvider extends ChangeNotifier {
  final LocalScheduleRepository _repo = LocalScheduleRepository();
  final _syncService = ScheduleSyncService();

  LocalScheduleProvider();

  Map<int, Schedule> _schedules = {};

  String _searchTerm = '';

  bool _isLoading = false;
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;

  String? _error;

  // Getters
  Map<int, Schedule> get schedules => _schedules;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get hasUnsavedChanges => _hasUnsavedChanges;

  String? get error => _error;

  /// Returns a list of schedule IDs filtered by the current search term.
  List<int> get filteredScheduleIDs {
    if (_searchTerm.isEmpty) {
      return _schedules.keys.toList();
    } else {
      final tempFiltered = <int>[];
      for (var entry in _schedules.entries) {
        final schedule = entry.value;

        if (schedule.name.toLowerCase().contains(_searchTerm) ||
            schedule.location.toLowerCase().contains(_searchTerm)) {
          tempFiltered.add(entry.key);
        }
      }
      return tempFiltered;
    }
  }

  Schedule? getSchedule(int id) {
    return _schedules[id];
  }

  Schedule? getNextSchedule() {
    try {
      return _schedules.values.firstWhere(
        (schedule) => schedule.date.isAfter(DateTime.now()),
      );
    } catch (e) {
      return null;
    }
  }

  String? getUserRoleInSchedule(int scheduleId, int? localUserId) {
    if (localUserId == null) return null;

    final schedule = getSchedule(scheduleId);
    if (schedule == null) return null;

    for (var role in schedule.roles) {
      if (role.users.any((user) => user.id == localUserId)) {
        return role.name;
      }
    }
    return null;
  }

  bool isLive(int scheduleID) {
    final schedule = _schedules[scheduleID];
    if (schedule == null) return false;
    return (schedule.isPublic && schedule.date.isAfter(DateTime.now()));
  }

  Future<Schedule?> getScheduleWithPlaylistId(int playlistId) async {
    try {
      await loadSchedules();

      return _schedules.values.firstWhere(
        (schedule) => schedule.playlistId == playlistId,
      );
    } catch (e) {
      return null;
    }
  }

  // ===== CREATE =====
  /// Creates a brand new schedule, used when duplicating a cloud schedule.
  Future<int?> createSchedule(Schedule schedule) async {
    int? localId;
    try {
      if (_isSaving) throw Exception('A save operation is already in progress');

      _isSaving = true;
      _error = null;
      notifyListeners();

      localId = await _repo.insertSchedule(schedule);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isSaving = false;
      notifyListeners();
    }
    return localId;
  }

  void cacheBrandNewSchedule(int playlistId, String ownerFirebaseId) {
    _schedules[-1] = Schedule(
      id: -1,
      ownerFirebaseId: ownerFirebaseId,
      name: '',
      date: DateTime.now(),
      time: TimeOfDay.now(),
      location: '',
      playlistId: playlistId,
      roles: [],
      shareCode: generateShareCode(),
    );
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  Future<bool> createFromCache(String ownerFirebaseId) async {
    if (_isSaving) return false;

    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final schedule = _schedules[-1] as Schedule;

      final localId = await _repo.insertSchedule(
        schedule.copyWith(ownerFirebaseId: ownerFirebaseId),
      );
      _schedules.remove(-1);
      _hasUnsavedChanges = false;
      notifyListeners();

      await loadSchedule(localId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isSaving = false;
      notifyListeners();
    }
    if (_error == null) {
      return true;
    } else {
      return false;
    }
  }

  /// Duplicates an existing schedule with new details,
  /// with the same playlist
  Future<void> duplicateSchedule(
    int scheduleID,
    String name,
    String date,
    String startTime,
    String location,
    String? roomVenue,
  ) async {
    if (_isSaving) return;

    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final originalSchedule = _schedules[scheduleID];
      if (originalSchedule == null) {
        throw Exception('Original schedule not found');
      }

      final newSchedule = originalSchedule.copyWith(
        name: name,
        date: DateTime(
          int.parse(date.split('/')[2]),
          int.parse(date.split('/')[1]),
          int.parse(date.split('/')[0]),
        ),
        time: TimeOfDay(
          hour: int.parse(startTime.split(':')[0]),
          minute: int.parse(startTime.split(':')[1]),
        ),
        location: location,
        roomVenue: roomVenue,
      );

      final newLocalId = await _repo.insertSchedule(newSchedule);
      await loadSchedule(newLocalId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// Uploads changes of a local schedule to the cloud.
  Future<void> uploadScheduleToCloud(
    int scheduleId,
    String ownerFirebaseId,
  ) async {
    final schedule = _schedules[scheduleId];
    if (schedule == null) return;

    try {
      await _syncService.scheduleToCloud(schedule, ownerFirebaseId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // ===== READ =====
  /// Loads schedules from the local repository.
  Future<void> loadSchedules() async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final scheduleList = await _repo.getAllSchedules();
      _schedules = {for (var schedule in scheduleList) schedule.id: schedule};
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadSchedule(int id) async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final schedule = await _repo.getScheduleById(id);
      if (schedule != null) {
        _schedules[id] = schedule;
      } else {
        _error = 'Schedule not found';
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ===== UPDATE =====
  void addRoleToSchedule(int scheduleId, String roleName) {
    final schedule = _schedules[scheduleId];
    if (schedule == null) return;

    final newRole = Role(id: -1, name: roleName, users: []);
    (_schedules[scheduleId] as Schedule).roles.add(newRole);

    _hasUnsavedChanges = true;

    notifyListeners();
  }

  void updateRoleName(int scheduleId, String oldName, String newName) {
    final schedule = _schedules[scheduleId];
    if (schedule == null) return;

    final role = schedule.roles.firstWhere((role) => role.name == oldName);
    role.name = newName;

    _hasUnsavedChanges = true;

    notifyListeners();
  }

  void assignPlaylistToSchedule(int scheduleId, int playlistId) {
    final schedule = _schedules[scheduleId];
    if (schedule == null) return;

    _schedules[scheduleId] = (_schedules[scheduleId] as Schedule).copyWith(
      playlistId: playlistId,
    );

    _hasUnsavedChanges = true;

    notifyListeners();
  }

  void publishSchedule(int scheduleId) {
    final schedule = _schedules[scheduleId];
    if (schedule == null) return;

    _schedules[scheduleId] = schedule.copyWith(isPublic: true);
    saveSchedule(scheduleId);
    notifyListeners();
  }

  void cacheScheduleDetails(
    int scheduleId, {
    required String name,
    required String date,
    required String startTime,
    required String location,
    String? roomVenue,
    String? annotations,
  }) {
    final schedule = _schedules[scheduleId];
    if (schedule == null) return;

    _schedules[scheduleId] = schedule.copyWith(
      name: name,
      date: DateTime(
        int.parse(date.split('/')[2]),
        int.parse(date.split('/')[1]),
        int.parse(date.split('/')[0]),
      ),
      time: TimeOfDay(
        hour: int.parse(startTime.split(':')[0]),
        minute: int.parse(startTime.split(':')[1]),
      ),
      location: location,
      roomVenue: roomVenue,
      annotations: annotations,
    );

    _hasUnsavedChanges = true;

    notifyListeners();
  }

  Future<void> saveSchedule(int scheduleId) async {
    if (_isSaving) return;

    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final schedule = _schedules[scheduleId]!;
      await _repo.updateSchedule(schedule);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isSaving = false;
      _hasUnsavedChanges = false;
      notifyListeners();
    }
  }

  // ===== MEMBER MANAGEMENT =====
  /// Adds an existing user to a role in a schedule (local).
  void addUserToRole(int scheduleId, int roleId, User user) {
    final schedule = _schedules[scheduleId];
    if (schedule == null) return;

    final role = schedule.roles.firstWhere((role) => role.id == roleId);

    role.users.add(user);

    _hasUnsavedChanges = true;

    notifyListeners();
  }

  void removeUserFromRole(int scheduleId, int roleId, int userId) {
    final schedule = _schedules[scheduleId];
    if (schedule == null) return;

    final role = schedule.roles.firstWhere((role) => role.id == roleId);

    role.users.removeWhere((user) => user.id == userId);

    _hasUnsavedChanges = true;

    notifyListeners();
  }

  void clearUsersFromRole(int scheduleId, int roleId) {
    final schedule = _schedules[scheduleId];
    if (schedule == null) return;

    final role = schedule.roles.firstWhere((role) => role.id == roleId);

    role.users.clear();

    _hasUnsavedChanges = true;

    notifyListeners();
  }

  // ===== DELETE =====
  /// Deletes a role from a schedule (local).
  /// Also removes all members assigned to that role.
  void deleteRole(int scheduleId, int roleId) {
    final schedule = _schedules[scheduleId];
    if (schedule == null || _isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      schedule.roles.removeWhere((role) => role.id == roleId);

      if (roleId != -1) _repo.deleteRole(roleId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      _hasUnsavedChanges = false;
      notifyListeners();
    }
  }

  /// Deletes a schedule.
  Future<void> deleteSchedule(int scheduleId) async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repo.deleteSchedule(scheduleId);
      _schedules.remove(scheduleId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      _hasUnsavedChanges = false;
      notifyListeners();
    }
  }

  // ===== SEARCH & FILTER =====
  void setSearchTerm(String term) {
    _searchTerm = term.toLowerCase();
  }

  // ===== HELPER METHODS =====
  void clearCache() {
    _schedules = {};
    _searchTerm = '';
    _error = null;
    notifyListeners();
  }

  List<int> get futureScheduleIDs {
    final futureSchedules = <int>[];

    for (var scheduleID in filteredScheduleIDs) {
      final schedule = _schedules[scheduleID]!;
      if (schedule.date.isAfter(DateTime.now()) ||
          (schedule.date.isAtSameMomentAs(DateTime.now()) &&
              (schedule.time.hour > TimeOfDay.now().hour ||
                  (schedule.time.hour == TimeOfDay.now().hour &&
                      schedule.time.minute > TimeOfDay.now().minute)))) {
        futureSchedules.add(scheduleID);
      }
    }
    return futureSchedules;
  }

  List<int> get pastScheduleIDs {
    final pastSchedules = <int>[];
    for (var scheduleID in filteredScheduleIDs) {
      final schedule = _schedules[scheduleID]!;

      if (schedule.date.isBefore(DateTime.now()) ||
          (schedule.date.isAtSameMomentAs(DateTime.now()) &&
              (schedule.time.hour < TimeOfDay.now().hour ||
                  (schedule.time.hour == TimeOfDay.now().hour &&
                      schedule.time.minute < TimeOfDay.now().minute)))) {
        pastSchedules.add(scheduleID);
      }
    }
    return pastSchedules;
  }
}
