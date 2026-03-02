import '../../helpers/database.dart';
import '../../models/domain/user.dart';

class UserRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // ===== CREATE =====
  /// Creates a new user
  /// Returns the ID of the newly created user
  Future<int> createUser(User user) async {
    final db = await _databaseHelper.database;

    return await db.insert('user', user.toSQLite());
  }

  // ===== READ =====
  /// Gets all users known by the local database
  Future<List<User>> getAllUsers() async {
    final db = await _databaseHelper.database;

    final result = await db.query('user');

    return result.map((row) => User.fromSqlite(row)).toList();
  }

  /// Gets a user by ID
  /// Returns null if no user is found
  Future<User?> getUserById(int userId) async {
    final db = await _databaseHelper.database;

    final results = await db.query(
      'user',
      where: 'id = ?',
      whereArgs: [userId],
    );

    if (results.isNotEmpty) {
      return User.fromSqlite(results.first);
    }

    return null;
  }

  /// Gets users by Firebase ID
  /// Used when ensuring users exist locally
  Future<User?> getUserByFirebaseId(String firebaseId) async {
    final db = await _databaseHelper.database;

    final results = await db.query(
      'user',
      where: 'firebase_id = ?',
      whereArgs: [firebaseId],
    );

    if (results.isNotEmpty) {
      return User.fromSqlite(results.first);
    }

    return null;
  }

  /// Gets a user by email
  /// Used when ensuring users exist locally, since some users may not have a Firebase ID if they were created locally and haven't been synced yet
  Future<User?> getUserByEmail(String email) async {
    final db = await _databaseHelper.database;

    final results = await db.query(
      'user',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (results.isNotEmpty) {
      return User.fromSqlite(results.first);
    }

    return null;
  }

  /// Gets all users that collaborate on a given playlist
  Future<List<User>> getUsersForPlaylist(int playlistId) async {
    final db = await _databaseHelper.database;

    final results = await db.rawQuery(
      '''
      SELECT u.*
      FROM user u
      INNER JOIN collaborator c ON u.id = c.user_id
      WHERE c.playlist_id = ?
    ''',
      [playlistId],
    );

    return results.map((row) => User.fromSqlite(row)).toList();
  }

  // ===== UPDATE =====
  /// Updates an existing user
  Future<int> updateUser(User user) async {
    final db = await _databaseHelper.database;

    return await db.update(
      'user',
      user.toSQLite(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  // ===== DELETE =====
  /// Deletes a user by Firebase ID
  Future<void> deleteUser(String firebaseId) async {
    final db = await _databaseHelper.database;

    await db.delete('user', where: 'firebase_id = ?', whereArgs: [firebaseId]);
  }
}
