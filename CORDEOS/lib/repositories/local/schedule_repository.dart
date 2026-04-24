import 'package:cordeos/helpers/database.dart';
import 'package:cordeos/models/domain/schedule.dart';
import 'package:cordeos/models/domain/user.dart';

class LocalScheduleRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // ===== CREATE =====
  Future<int> insertSchedule(Schedule schedule) async {
    final db = await _databaseHelper.database;
    int scheduleId = await db.insert('schedule', schedule.toSqlite());

    for (var role in schedule.roles.values) {
      await insertRole(scheduleId, role);
    }

    return scheduleId;
  }

  Future<int> insertRole(int scheduleId, Role role) async {
    final db = await _databaseHelper.database;
    int roleId = await db.insert('role', role.toSqlite(scheduleId));

    for (var userId in role.users.map((user) => user.id)) {
      if (userId == null || userId == -1) continue;
      await insertMember(roleId, userId);
    }

    return roleId;
  }

  Future<int> insertMember(int roleId, int userId) async {
    final db = await _databaseHelper.database;
    return await db.insert('role_member', {
      'role_id': roleId,
      'member_id': userId,
    });
  }

  // ===== READ =====
  /// Retrieves all schedules from the local database.
  Future<List<Schedule>> getAllSchedules() async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('schedule');

    List<Schedule> schedules = [];
    for (var map in maps) {
      final scheduleId = map['id'] as int;
      final roles = await getRolesForSchedule(scheduleId);

      schedules.add(Schedule.fromSqlite(map, roles));
    }

    return schedules;
  }

  Future<Schedule?> getScheduleById(int id) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'schedule',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;

    final scheduleId = maps.first['id'] as int;
    final roles = await getRolesForSchedule(scheduleId);

    return Schedule.fromSqlite(maps.first, roles);
  }

  Future<Schedule?> getScheduleByFirebaseIdOrShareCode(
    String firebaseId,
    String shareCode,
  ) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'schedule',
      where: 'firebase_id = ? OR share_code = ?',
      whereArgs: [firebaseId, shareCode],
    );

    if (maps.isEmpty) return null;

    final scheduleId = maps.first['id'] as int;
    final roles = await getRolesForSchedule(scheduleId);

    return Schedule.fromSqlite(maps.first, roles);
  }

  Future<List<Role>> getRolesForSchedule(int scheduleId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'role',
      where: 'schedule_id = ?',
      whereArgs: [scheduleId],
    );

    List<Role> roles = [];
    for (var map in maps) {
      final roleId = map['id'] as int;
      final users = await getUsersForRole(roleId);
      roles.add(Role.fromSqlite(map, users));
    }

    return roles;
  }

  Future<List<User>> getUsersForRole(int roleId) async {
    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'role_member',
      where: 'role_id = ?',
      whereArgs: [roleId],
    );

    final userIds = maps.map((map) => map['member_id'] as int).toList();

    // Fetch user details for each userId
    final List<Map<String, dynamic>> userMaps = await db.query(
      'user',
      where: 'id IN (${List.filled(userIds.length, '?').join(',')})',
      whereArgs: userIds,
    );

    List<User> users = [];
    for (var map in userMaps) {
      users.add(User.fromSqlite(map));
    }

    return users;
  }

  // ===== UPDATE =====
  Future<void> updateSchedule(Schedule schedule) async {
    final db = await _databaseHelper.database;
    await db.update(
      'schedule',
      schedule.toSqlite(),
      where: 'id = ?',
      whereArgs: [schedule.id],
    );
  }

  Future<void> upsertRole(int scheduleId, Role role) async {
    final db = await _databaseHelper.database;
    final existing = await db.query(
      'role',
      where: 'name = ? AND schedule_id = ?',
      whereArgs: [role.name, scheduleId],
    );

    if (existing.isEmpty) {
      // Role doesn't exist, insert it
      int roleId = await db.insert('role', role.toSqlite(scheduleId));
      for (var user in role.users) {
        if (user.id == null || user.id == -1) continue;
        await insertMember(roleId, user.id!);
      }
    } else {
      await db.update(
        'role',
        role.toSqlite(scheduleId),
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );

      // Update members
      await db.delete(
        'role_member',
        where: 'role_id = ?',
        whereArgs: [existing.first['id']],
      );
      for (var user in role.users) {
        await insertMember(existing.first['id'] as int, user.id!);
      }
    }
  }

  // ===== DELETE =====
  Future<void> deleteSchedule(int id) async {
    final db = await _databaseHelper.database;
    await db.delete('schedule', where: 'id = ?', whereArgs: [id]);
  }

  /// Deletes a role and its member associations from the database.
  Future<void> deleteRole(int roleId) async {
    final db = await _databaseHelper.database;
    await db.delete('role', where: 'id = ?', whereArgs: [roleId]);
    await db.delete('role_member', where: 'role_id = ?', whereArgs: [roleId]);
  }

  /// Removes a user from a role by deleting the corresponding entry in the role_member table.
  Future<void> removeUserFromRole(int roleId, int userId) async {
    final db = await _databaseHelper.database;
    await db.delete(
      'role_member',
      where: 'role_id = ? AND member_id = ?',
      whereArgs: [roleId, userId],
    );
  }
}
