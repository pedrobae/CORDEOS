import 'package:collection/collection.dart';
import 'package:cordeos/helpers/codes.dart';
import 'package:cordeos/models/domain/schedule.dart';
import 'package:cordeos/models/domain/user.dart';
import 'package:cordeos/repositories/local/schedule_repository.dart';
import 'package:cordeos/services/sync_service.dart';
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

  bool isLive(int scheduleID) {
    final schedule = _schedules[scheduleID];
    if (schedule == null) return false;
    return (schedule.isPublic && schedule.date.isAfter(DateTime.now()));
  }

  Future<Schedule?> getScheduleWithPlaylistId(int playlistId) async {
    await loadSchedules();

    return _schedules.values.firstWhereOrNull(
      (schedule) => schedule.playlistId == playlistId,
    );
  }

  // ===== CREATE =====
  void cacheBrandNewSchedule(int playlistId, String ownerFirebaseId) {
    _schedules[-1] = Schedule(
      id: -1,
      ownerFirebaseId: ownerFirebaseId,
      name: '',
      date: DateTime.now(),
      location: '',
      playlistId: playlistId,
      roles: {},
      shareCode: generateShareCode(),
      collaborators: []
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
          int.parse(startTime.split(':')[0]),
          int.parse(startTime.split(':')[1]),
        ),
        location: location,
        roomVenue: roomVenue,
        firebaseId: '',
        isPublic: false,
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

  /// If owner is equal to the current user
  /// And the schedule is already public
  /// And current date is earlier than the schedule date,
  /// Then the schedule will be updated in the cloud.
  Future<void> uploadChangesToCloud(
    int scheduleID,
    String userFirebaseId,
  ) async {
    final schedule = _schedules[scheduleID];
    if (schedule == null) return;

    if (schedule.ownerFirebaseId != userFirebaseId) return;

    if (!schedule.isPublic) return;

    if (DateTime.now().isAfter(schedule.date)) return;

    try {
      await _syncService.upsertScheduleToCloud(schedule, userFirebaseId);
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

    // If id is -1, it means we want to clear the current schedule
    // (used when discarding changes on a new schedule that hasn't been saved yet)
    if (id == -1) {
      _schedules.remove(-1);
      return;
    }

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
      _hasUnsavedChanges = false;
      notifyListeners();
    }
  }

  // ===== UPDATE =====
  Future<void> addRoleToSchedule(int scheduleID, String roleName) async {
    final schedule = _schedules[scheduleID];
    if (schedule == null) return;

    final newRole = Role(id: -1, name: roleName, users: []);

    final newID = await _repo.insertRole(scheduleID, newRole);
    (_schedules[scheduleID] as Schedule).roles[newID] = newRole.copyWith(
      id: newID,
    );
    _hasUnsavedChanges = true;
    notifyListeners();
  }

  void updateRoleName(int scheduleID, int roleID, String newName) {
    final schedule = _schedules[scheduleID];
    if (schedule == null) return;

    final role = schedule.roles[roleID]!;
    role.name = newName;

    _hasUnsavedChanges = true;

    notifyListeners();
  }

  void assignPlaylistToSchedule(int scheduleID, int playlistId) {
    final schedule = _schedules[scheduleID];
    if (schedule == null) return;

    _schedules[scheduleID] = (_schedules[scheduleID] as Schedule).copyWith(
      playlistId: playlistId,
    );

    _hasUnsavedChanges = true;

    notifyListeners();
  }

  void publishSchedule(int scheduleID) {
    final schedule = _schedules[scheduleID];
    if (schedule == null) return;

    _schedules[scheduleID] = schedule.copyWith(isPublic: true);
    saveDetails(scheduleID);
    notifyListeners();
  }

  void cacheName(int scheduleID, String name) {
    final schedule = _schedules[scheduleID];
    if (schedule == null) return;

    _schedules[scheduleID] = schedule.copyWith(name: name);
    _hasUnsavedChanges = true;

    notifyListeners();
  }

  void cacheLocation(int scheduleID, String location) {
    final schedule = _schedules[scheduleID];
    if (schedule == null) return;

    _schedules[scheduleID] = schedule.copyWith(location: location);
    _hasUnsavedChanges = true;

    notifyListeners();
  }

  void cacheRoomVenue(int scheduleID, String roomVenue) {
    final schedule = _schedules[scheduleID];
    if (schedule == null) return;

    _schedules[scheduleID] = schedule.copyWith(roomVenue: roomVenue);
    _hasUnsavedChanges = true;

    notifyListeners();
  }

  void cacheDate(int scheduleID, DateTime date) {
    final schedule = _schedules[scheduleID];
    if (schedule == null) return;

    _schedules[scheduleID] = schedule.copyWith(date: date);
    _hasUnsavedChanges = true;

    notifyListeners();
  }

  void cacheTime(int scheduleID, TimeOfDay time) {
    final schedule = _schedules[scheduleID];
    if (schedule == null) return;

    final newDate = DateTime(
      schedule.date.year,
      schedule.date.month,
      schedule.date.day,
      time.hour,
      time.minute,
    );

    _schedules[scheduleID] = schedule.copyWith(date: newDate);
    _hasUnsavedChanges = true;

    notifyListeners();
  }

  Future<void> saveDetails(int scheduleID) async {
    if (_isSaving) return;

    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final schedule = _schedules[scheduleID]!;
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
  void addUserToRole(int scheduleID, int roleId, User user) {
    final schedule = _schedules[scheduleID];
    if (schedule == null) return;

    final role = schedule.roles.values.firstWhere((role) => role.id == roleId);

    role.users.add(user);

    _hasUnsavedChanges = true;

    notifyListeners();
  }

  void removeUserFromRole(int scheduleID, int roleId, int userId) {
    final schedule = _schedules[scheduleID];
    if (schedule == null) return;

    final role = schedule.roles.values.firstWhere((role) => role.id == roleId);

    role.users.removeWhere((user) => user.id == userId);

    _hasUnsavedChanges = true;

    notifyListeners();
  }

  void clearUsersFromRole(int scheduleID, int roleId) {
    final schedule = _schedules[scheduleID];
    if (schedule == null) return;

    final role = schedule.roles.values.firstWhere((role) => role.id == roleId);

    role.users.clear();

    _hasUnsavedChanges = true;

    notifyListeners();
  }

  Future<void> saveUserRoles(int scheduleID) async {
    if (_isSaving) return;

    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final schedule = _schedules[scheduleID];

      for (Role role in schedule?.roles.values ?? []) {
        await _repo.updateRole(scheduleID, role);
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isSaving = false;
      _hasUnsavedChanges = false;
      notifyListeners();
    }
  }

  // ===== DELETE =====
  /// Deletes a role from a schedule (local).
  /// Also removes all members assigned to that role.
  void deleteRole(int scheduleID, int roleId) {
    final schedule = _schedules[scheduleID];
    if (schedule == null || _isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      schedule.roles.remove(roleId);

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
  Future<void> deleteSchedule(int scheduleID) async {
    if (_isLoading) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repo.deleteSchedule(scheduleID);
      _schedules.remove(scheduleID);
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
      if (schedule.date.isAfter(DateTime.now())) {
        futureSchedules.add(scheduleID);
      }
    }
    return futureSchedules;
  }

  List<int> get pastScheduleIDs {
    final pastSchedules = <int>[];
    for (var scheduleID in filteredScheduleIDs) {
      final schedule = _schedules[scheduleID]!;

      if (schedule.date.isBefore(DateTime.now())) {
        pastSchedules.add(scheduleID);
      }
    }
    return pastSchedules;
  }
}
