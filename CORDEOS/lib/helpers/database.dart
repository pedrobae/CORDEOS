import 'dart:async';
import 'package:collection/collection.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  factory DatabaseHelper() => _instance;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      String path = join(await getDatabasesPath(), 'cipher_app.db');

      final db = await openDatabase(
        path,
        version: 21,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade, // Handle migrations
      );

      // Enable foreign key constraints to enforce CASCADE delete
      await db.execute('PRAGMA foreign_keys = ON');

      return db;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create tag table
    await db.execute('''
      CREATE TABLE tag (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL
      )
    ''');

    // Create cipher table
    await db.execute('''
      CREATE TABLE cipher (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        author TEXT,
        music_key TEXT,
        language TEXT DEFAULT 'por',
        links TEXT,
        firebase_id TEXT,
        is_deleted BOOLEAN DEFAULT 0,
        updated_at INTEGER DEFAULT (strftime('%s','now')),
        created_at INTEGER DEFAULT (strftime('%s','now'))
      )
    ''');

    // Create cipher_tags junction table
    await db.execute('''
      CREATE TABLE cipher_tags (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tag_id INTEGER NOT NULL,
        cipher_id INTEGER NOT NULL,
        FOREIGN KEY (tag_id) REFERENCES tag (id) ON DELETE CASCADE,
        FOREIGN KEY (cipher_id) REFERENCES cipher (id) ON DELETE CASCADE,
        UNIQUE(tag_id, cipher_id)
      )
    ''');

    // Create version table (renamed from cipher_map)
    await db.execute('''
      CREATE TABLE version (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cipher_id INTEGER NOT NULL,
        song_structure TEXT NOT NULL,
        duration INTEGER DEFAULT 0,
        bpm INTEGER DEFAULT 0,
        transposed_key TEXT,
        version_name TEXT,
        firebase_cipher_id TEXT,
        firebase_id TEXT,
        created_at INTEGER DEFAULT (strftime('%s','now')),
        FOREIGN KEY (cipher_id) REFERENCES cipher (id) ON DELETE CASCADE
      )
    ''');

    // Create section table (renamed from map_content)
    await db.execute('''
      CREATE TABLE section (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        version_id INTEGER NOT NULL,
        key INTEGER NOT NULL,
        content_type TEXT NOT NULL,
        content_text TEXT NOT NULL,
        content_color TEXT,
        FOREIGN KEY (version_id) REFERENCES version (id) ON DELETE CASCADE
      )
    ''');

    // Create user table
    await db.execute('''
      CREATE TABLE user (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        email TEXT UNIQUE NOT NULL,
        profile_photo TEXT,
        firebase_id TEXT UNIQUE,
        country TEXT,
        language TEXT,
        time_zone TEXT,
        created_at INTEGER DEFAULT (strftime('%s','now')),
        updated_at INTEGER DEFAULT (strftime('%s','now')),
        is_active BOOLEAN DEFAULT 1
      )
    ''');

    // Create playlist table
    await db.execute('''
      CREATE TABLE playlist (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        author_id STRING NOT NULL,
        firebase_id TEXT UNIQUE,
        FOREIGN KEY (author_id) REFERENCES user (id) ON DELETE CASCADE
      )
    ''');

    // Create playlist_version table (playlists contain specific cipher versions)
    await db.execute('''
      CREATE TABLE playlist_version (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        version_id INTEGER NOT NULL,
        playlist_id INTEGER NOT NULL,
        firebase_content_id TEXT,
        position INTEGER NOT NULL,
        FOREIGN KEY (version_id) REFERENCES version (id) ON DELETE CASCADE,
        FOREIGN KEY (playlist_id) REFERENCES playlist (id) ON DELETE CASCADE,
        UNIQUE(playlist_id, position)
      )
    ''');

    // Create user_playlist table for collaborators
    await db.execute('''
      CREATE TABLE user_playlist (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        playlist_id INTEGER NOT NULL,
        role TEXT NOT NULL DEFAULT 'collaborator',
        added_by INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES user (id) ON DELETE CASCADE,
        FOREIGN KEY (playlist_id) REFERENCES playlist (id) ON DELETE CASCADE,
        FOREIGN KEY (added_by) REFERENCES user (id) ON DELETE CASCADE,
        UNIQUE(user_id, playlist_id)
      )
    ''');

    // Create flow_item table, for written playlist Items
    await db.execute('''
      CREATE TABLE flow_item (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        playlist_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        firebase_id TEXT,
        position INTEGER NOT NULL DEFAULT 0,
        duration INTEGER DEFAULT 0,
        FOREIGN KEY (playlist_id) REFERENCES playlist (id) ON DELETE CASCADE
      )
    ''');

    // Create schedule table
    await db.execute('''
      CREATE TABLE schedule (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        playlist_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        date TEXT NOT NULL,
        location TEXT,
        room_venue TEXT,
        annotations TEXT,
        firebase_id TEXT UNIQUE,
        owner_firebase_id TEXT NOT NULL,
        share_code TEXT,
        is_public BOOLEAN DEFAULT 0,
        FOREIGN KEY (playlist_id) REFERENCES playlist (id) ON DELETE CASCADE
      )
    ''');

    // Create role table
    await db.execute('''  
      CREATE TABLE role (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        schedule_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        FOREIGN KEY (schedule_id) REFERENCES schedule (id) ON DELETE CASCADE
      ) 
    ''');

    // Create role_member table
    await db.execute('''  
      CREATE TABLE role_member (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        role_id INTEGER NOT NULL,
        member_id INTEGER NOT NULL,
        FOREIGN KEY (role_id) REFERENCES role (id) ON DELETE CASCADE,
        FOREIGN KEY (member_id) REFERENCES user (id) ON DELETE CASCADE
      ) 
    ''');

    // Create indexes for better performance
    await db.execute(
      'CREATE INDEX idx_cipher_tags_cipher_id ON cipher_tags(cipher_id)',
    );
    await db.execute(
      'CREATE INDEX idx_cipher_tags_tag_id ON cipher_tags(tag_id)',
    );
    await db.execute(
      'CREATE INDEX idx_version_cipher_id ON version(cipher_id)',
    );
    await db.execute(
      'CREATE INDEX idx_section_version_id ON section(version_id)',
    );
    await db.execute(
      'CREATE INDEX idx_playlist_author_id ON playlist(author_id)',
    );
    await db.execute(
      'CREATE INDEX idx_playlist_version_playlist_id ON playlist_version(playlist_id)',
    );
    await db.execute(
      'CREATE INDEX idx_playlist_version_version_id ON playlist_version(version_id)',
    );
    await db.execute(
      'CREATE INDEX idx_user_playlist_user_id ON user_playlist(user_id)',
    );
    await db.execute(
      'CREATE INDEX idx_user_playlist_playlist_id ON user_playlist(playlist_id)',
    );
    // For user lookups
    await db.execute('CREATE INDEX idx_user_email ON user(email)');
    await db.execute(
      'CREATE UNIQUE INDEX idx_user_firebase_id ON user(firebase_id)',
    );
    // For cipher lookups
    await db.execute(
      'CREATE UNIQUE INDEX idx_cipher_firebase_id ON cipher(firebase_id)',
    );
    // For version lookups
    await db.execute(
      'CREATE UNIQUE INDEX idx_version_firebase_id ON version(firebase_id)',
    );
    await db.execute(
      'CREATE INDEX idx_version_firebase_cipher_id ON version(firebase_cipher_id)',
    );
    // For content queries
    await db.execute(
      'CREATE INDEX idx_section_content_type ON section(content_type)',
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle migrations between database versions
    if (oldVersion < 17) {
      // ADD COUNTRY, LANGUAGE AND TIMEZONE TO USER TABLE
      await db.execute('ALTER TABLE user ADD COLUMN country TEXT');
      await db.execute('ALTER TABLE user ADD COLUMN language TEXT');
      await db.execute('ALTER TABLE user ADD COLUMN time_zone TEXT');
    }
    if (oldVersion < 18) {
      // REMOVE TIME COLUMN FROM SCHEDULE TABLE
      await db.execute('ALTER TABLE schedule DROP COLUMN time');
    }
    if (oldVersion < 19) {
      // ADD LINK COLUMN TO CIPHER TABLE
      await db.execute('ALTER TABLE cipher ADD COLUMN link TEXT');
    }
    if (oldVersion < 20) {
      // REMOVE content_code ON SECTION TABLE (was NON NULL)
      // ADD key COLUMN TO SECTION TABLE (int, non null)
      // Since SQLite doesn't support altering column constraints directly, we need to recreate the table

      await db.transaction((txn) async {
        await txn.execute('ALTER TABLE section RENAME TO section_old');
        await txn.execute('''
        CREATE TABLE section (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          version_id INTEGER NOT NULL,
          key INTEGER NOT NULL,
          content_type TEXT NOT NULL,
          content_text TEXT NOT NULL,
          content_color TEXT,
          FOREIGN KEY (version_id) REFERENCES version (id) ON DELETE CASCADE
        )
      ''');

        // MAP CODE TO KEY, SO WE CAN CHANGE VERSION STRUCTURE WITHOUT LOSING DATA
        final List<Map<String, dynamic>> oldSections = await txn.query(
          'section_old',
          columns: ['id', 'version_id', 'content_code'],
        );
        await txn.execute('''
        INSERT INTO section (id, version_id, key, content_type, content_text, content_color)
        SELECT id, version_id, id, content_type, content_text, content_color
        FROM section_old
      ''');
        await txn.execute('DROP TABLE section_old');

        await txn.execute(
          'CREATE INDEX idx_section_version_id ON section(version_id)',
        );

        // USING oldSections to update version structure in app logic,
        // so we don't lose data and can migrate smoothly
        final versionStructs = await txn.query(
          'version',
          columns: ['id', 'song_structure'],
        );

        for (var version in versionStructs) {
          final versionID = version['id'] as int;
          final struct = (version['song_structure'] as String).split(',');

          final newStruct = <int>[];
          for (var code in struct) {
            final section = oldSections.firstWhereOrNull(
              (s) =>
                  s['version_id'] == versionID &&
                  s['content_code'] == code.trim(),
            );

            if (section != null) {
              newStruct.add(section['id'] as int);
            }
          }

          await txn.update(
            'version',
            {'song_structure': newStruct.join(',')},
            where: 'id = ?',
            whereArgs: [versionID],
          );
        }
      });
    }
    if (oldVersion < 21) {
      // RENAME LINK TO LINKS BEGIN USING A COLON SEPARATED STRING
      await db.execute('ALTER TABLE cipher RENAME COLUMN link TO links');
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  // Helper method to reset database (for development)
  Future<void> resetDatabase() async {
    try {
      // First close any existing database connection
      if (_database != null) {
        await _database!.close();
        _database = null;
      }

      // Get the database path
      String path = join(await getDatabasesPath(), 'cipher_app.db');

      // Delete the database file completely
      await databaseFactory.deleteDatabase(path);

      // Re-initialize database
      await database;
    } catch (e) {
      rethrow;
    }
  }
}
