import 'package:cordeos/helpers/database.dart';
import 'package:cordeos/models/domain/schedule.dart';
import 'package:cordeos/models/domain/user.dart';
import 'package:sqflite/sqflite.dart';

class LocalScheduleRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // ===== CREATE =====
  Future<int> insertSchedule(Schedule schedule) async {
    final db = await _databaseHelper.database;
    int scheduleId = await db.insert('schedule', schedule.toSqlite());

    for (var role in schedule.roles) {
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

  /// Delete roles not on the list, create roles not on the db, update roles on both
  Future<void> saveRoles(int scheduleId, List<Role> roles) async {
    final db = await _databaseHelper.database;

    await db.transaction((txn) async {
      final result = await txn.query(
        'role',
        where: 'schedule_id = ?',
        whereArgs: [scheduleId],
      );

      final existingIds = result.map((row) => row['id'] as int).toList();

      for (final role in roles) {
        if (existingIds.contains(role.id)) {
          await txn.update(
            'role',
            role.toSqlite(scheduleId),
            where: 'id = ?',
            whereArgs: [role.id],
          );
          await _saveUsersInTxn(txn, role.users, role.id);
        } else {
          await txn.insert('role', role.toSqlite(scheduleId));
        }
        await _saveUsersInTxn(txn, role.users, role.id);
        existingIds.remove(role.id);
      }

      for (final remainingID in existingIds) {
        await txn.delete('role', where: 'id = ?', whereArgs: [remainingID]);
      }
    });
  }

  Future<void> _saveUsersInTxn(
    Transaction txn,
    List<User> users,
    int roleID,
  ) async {
    await txn.delete('role_member', where: 'role_id = ?', whereArgs: [roleID]);

    for (final user in users) {
      await txn.insert('role_member', {
        'role_id': roleID,
        'member_id': user.id,
      });
    }
  }

  // ===== DELETE =====
  Future<void> deleteSchedule(int id) async {
    final db = await _databaseHelper.database;
    await db.delete('schedule', where: 'id = ?', whereArgs: [id]);
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
