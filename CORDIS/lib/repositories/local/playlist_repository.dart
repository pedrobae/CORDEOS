import 'package:cordis/helpers/database.dart';
import 'package:cordis/models/domain/playlist/playlist.dart';
import 'package:cordis/models/domain/playlist/playlist_item.dart';

// class Playlist {
//   final int id;
//   final String name;
//   final String? firebaseId;
//   final String? description;
//   final int createdBy;
//   final bool? isPublic;
//   final DateTime? createdAt;
//   final DateTime? updatedAt;
//   final List<String> collaborators;
//   final String? shareCode;
//   final List<PlaylistItem> items;

class PlaylistRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // ===== PLAYLIST CRUD =====
  // ===== CREATE =====
  /// Creates a new playlist, as well as the playlist_version, and user_playlist relational objects
  Future<int> insertPlaylist(Playlist playlist) async {
    final db = await _databaseHelper.database;

    return await db.transaction((txn) async {
      // 1. Insert the playlist (basic info only)
      final playlistId = await txn.insert(
        'playlist',
        playlist.toSqlite(),
      );

      // 2. Insert playlist items if any
      for (final item in playlist.items) {
        switch (item.type) {
          case PlaylistItemType.version:
            await txn.insert('playlist_version', {
              'version_id': item.contentId,
              'playlist_id': playlistId,
              'position': item.position,
            });
            break;
          case PlaylistItemType.flowItem:
            // Handle text sections if they exist
            // For now, just skip as we're removing text sections
            break;
        }
      }

      return playlistId;
    });
  }

  // ===== READ =====
  /// Gets all playlists stored in the database
  Future<List<Playlist>> getAllPlaylists() async {
    final db = await _databaseHelper.database;

    // Get playlists
    final playlistResults = await db.rawQuery('''
      SELECT p.* FROM playlist p
    ''');

    List<Playlist> playlists = [];

    for (Map<String, dynamic> playlistData in playlistResults) {
      final playlist = Playlist.fromSQLite(playlistData);

      /// Gets all items of a playlist in order
      final versionItems = await _getVersionItemsOfPlaylist(playlist.id);
      final textItems = await _getTextItemsOfPlaylist(playlist.id);

      // Combine and sort all items by position
      final allItemResults = [...versionItems, ...textItems]
        ..sort((a, b) => (a.position).compareTo(b.position));

      playlists.add(playlist.copyWith(items: allItemResults));
    }

    return playlists;
  }

  /// Gets a single playlist by ID without relationships
  /// Returns null if not found
  Future<Playlist?> getPlaylistById(int playlistId) async {
    final db = await _databaseHelper.database;

    final playlistResults = await db.query(
      'playlist',
      where: 'id = ?',
      whereArgs: [playlistId],
    );

    if (playlistResults.isEmpty) return null;

    /// Gets all items of a playlist in order
    final versionItems = await _getVersionItemsOfPlaylist(playlistId);
    final textItems = await _getTextItemsOfPlaylist(playlistId);

    // Combine and sort all items by position
    final allItemResults = [...versionItems, ...textItems]
      ..sort((a, b) => (a.position).compareTo(b.position));

    return Playlist.fromSQLite(
      playlistResults.first,
    ).copyWith(items: allItemResults);
  }

  // ===== UPDATE =====

  /// Upserts playlist metadata
  /// Used for syncing playlists from cloud to local database
  Future<int> upsertPlaylistMetadata(Playlist playlist) async {
    final db = await _databaseHelper.database;

    // First, try to find existing playlist by name
    final existingResult = await db.query(
      'playlist',
      columns: ['id'],
      where: 'name = ?',
      whereArgs: [playlist.name],
    );

    if (existingResult.isNotEmpty) {
      // Update existing playlist
      final playlistId = existingResult.first['id'] as int;

      await db.update(
        'playlist',
        {'name': playlist.name},
        where: 'id = ?',
        whereArgs: [playlistId],
      );
      return playlistId;
    } else {
      // Insert new playlist
      final playlistId = await db.insert(
        'playlist',
        playlist.toSqlite() as Map<String, Object?>,
      );
      return playlistId;
    }
  }

  // ===== DELETE =====
  /// Deletes a playlist and all its related data
  Future<void> deletePlaylist(int playlistId) async {
    final db = await _databaseHelper.database;

    await db.delete('playlist', where: 'id = ?', whereArgs: [playlistId]);
    await db.delete(
      'playlist_version',
      where: 'playlist_id = ?',
      whereArgs: [playlistId],
    );
    await db.delete(
      'user_playlist',
      where: 'playlist_id = ?',
      whereArgs: [playlistId],
    );
  }

  // ===== VERSION MANAGEMENT =====
  /// Adds a version to the end of the playlist
  Future<void> addVersionToPlaylist(int playlistId, int versionID) async {
    final db = await _databaseHelper.database;

    await db.transaction((txn) async {
      // Get current max position
      final positionResult = await txn.rawQuery(
        '''
        SELECT COALESCE(MAX(position), -1) + 1 as next_position 
        FROM playlist_version 
        WHERE playlist_id = ?
      ''',
        [playlistId],
      );

      final nextPosition = positionResult.first['next_position'] as int;

      // Insert version relationship
      await txn.insert('playlist_version', {
        'version_id': versionID,
        'playlist_id': playlistId,
        'position': nextPosition,
      });
    });
  }

  /// Adds a version to a specific position in the playlist (used when importing)
  Future<void> addVersionToPlaylistAtPosition(
    int playlistId,
    int versionID,
    int position,
  ) async {
    final db = await _databaseHelper.database;

    await db.transaction((txn) async {
      // Insert version relationship at the desired position
      await txn.insert('playlist_version', {
        'version_id': versionID,
        'playlist_id': playlistId,
        'position': position,
      });
    });
  }

  /// Upserts a version's position in a playlist
  Future<void> updatePlaylistVersionPosition(
    int playlistVersionId,
    int newPosition,
  ) async {
    final db = await _databaseHelper.database;

    await db.update(
      'playlist_version',
      {'position': newPosition},
      where: 'id = ?',
      whereArgs: [playlistVersionId],
    );
  }

  /// Removes a version from a playlist by playlist version ID
  Future<void> removeVersionFromPlaylist(int itemId) async {
    final db = await _databaseHelper.database;

    await db.transaction((txn) async {
      // Remove version relationship
      await txn.delete(
        'playlist_version',
        where: 'id = ?',
        whereArgs: [itemId],
      );
    });
  }

  // ===== UNIFIED PLAYLIST ITEMS =====
  /// Saves playlist items from a list
  /// Used for reordering items in a playlist
  Future<void> savePlaylistOrder(
    int playlistId,
    List<PlaylistItem> items,
  ) async {
    final db = await _databaseHelper.database;

    await db.transaction((txn) async {
      for (var i = 0; i < items.length; i++) {
        final item = items[i];
        final tempPosition = -(i + 1000);

        switch (item.type) {
          case PlaylistItemType.version:
            await txn.update(
              'playlist_version',
              {'position': tempPosition},
              where: 'id = ?',
              whereArgs: [item.id!],
            );
            break;

          case PlaylistItemType.flowItem:
            await txn.update(
              'flow_item',
              {'position': tempPosition},
              where: 'id = ?',
              whereArgs: [item.contentId],
            );
            break;
        }
      }

      for (var item in items) {
        switch (item.type) {
          case PlaylistItemType.version:
            await txn.update(
              'playlist_version',
              {'position': item.position},
              where: 'id = ?',
              whereArgs: [item.id!],
            );
            break;
          case PlaylistItemType.flowItem:
            await txn.update(
              'flow_item',
              {'position': item.position},
              where: 'id = ?',
              whereArgs: [item.contentId],
            );
        }
      }
    });
  }

  /// Gets text items of a playlist
  Future<List<PlaylistItem>> _getTextItemsOfPlaylist(int playlistId) async {
    final db = await _databaseHelper.database;

    final flowItemResults = await db.rawQuery(
      '''
        SELECT id as content_id, position, duration, firebase_id as firebase_id
        FROM flow_item
        WHERE playlist_id = ? 
        ORDER BY position ASC
      ''',
      [playlistId],
    );

    return flowItemResults.map((row) {
      final contentId = row['content_id'] as int;
      final position = row['position'] as int;
      final duration = Duration(seconds: row['duration'] as int);
      final firebaseId = row['firebase_id'] as String;

      return PlaylistItem.flowItem(
        flowItemId: contentId,
        position: position,
        duration: duration,
        flowItemFirebaseId: firebaseId,
      );
    }).toList();
  }

  /// Gets version items of a playlist
  Future<List<PlaylistItem>> _getVersionItemsOfPlaylist(int playlistId) async {
    final db = await _databaseHelper.database;

    final versionResults = await db.rawQuery(
      '''
        SELECT v.id as content_id, position, v.duration, pv.id, v.firebase_id as firebase_id
        FROM playlist_version AS pv JOIN version AS v ON pv.version_id = v.id
        WHERE playlist_id = ? 
        ORDER BY position ASC
      ''',
      [playlistId],
    );

    return versionResults.map((row) {
      final id = row['id'] as int;
      final contentId = row['content_id'] as int;
      final firebaseId = row['firebase_id'] as String?;
      final position = row['position'] as int;
      final duration = Duration(seconds: row['duration'] as int);

      return PlaylistItem.version(
        versionId: contentId,
        position: position,
        id: id,
        duration: duration,
        versionFirebaseId: firebaseId,
      );
    }).toList();
  }

  /// Gets version item ID in a playlist by playlist and version IDs
  /// Returns null if not found
  Future<int?> getPlaylistVersionId(
    int playlistId,
    int versionId, {
    int? position,
  }) async {
    final db = await _databaseHelper.database;

    final result = await db.query(
      'playlist_version',
      columns: ['id'],
      where:
          'playlist_id = ? AND version_id = ?${position != null ? ' AND position = ?' : ''}',
      whereArgs: [playlistId, versionId, ?position],
    );

    if (result.isNotEmpty) {
      return result.first['id'] as int;
    } else {
      return null;
    }
  }

  /// Prunes playlist items present in the provided lists
  /// Used during sync to remove items no longer in the cloud playlist
  Future<void> prunePlaylistItems(
    int playlistId,
    List<int> textItemIds,
    List<int> versionItemIds,
  ) async {
    final db = await _databaseHelper.database;

    // Prune versions
    if (versionItemIds.isNotEmpty) {
      final versionPlaceholders = List.filled(
        versionItemIds.length,
        '?',
      ).join(', ');
      await db.delete(
        'playlist_version',
        where: 'id IN ($versionPlaceholders)',
        whereArgs: [...versionItemIds],
      );
    }

    // Prune text sections
    if (textItemIds.isNotEmpty) {
      final textPlaceholders = List.filled(textItemIds.length, '?').join(', ');
      await db.delete(
        'flow_item',
        where: 'playlist_id = ? AND id IN ($textPlaceholders)',
        whereArgs: [playlistId, ...textItemIds],
      );
    }
  }

  // ===== UTILS =====
  /// Sync entire playlist with all its items in a single transaction
  /// This prevents database locking issues during bulk sync operations
  Future<int> syncPlaylistWithTransaction(
    Playlist playlist,
    List<Map<String, dynamic>> versionSectionItems,
    List<Map<String, dynamic>> textSectionItems,
    List<int> textItemsToPrune,
    List<int> versionItemsToPrune,
  ) async {
    final db = await _databaseHelper.database;
    late int playlistId;

    await db.transaction((txn) async {
      // 1. Upsert playlist
      final existingResult = await txn.query(
        'playlist',
        columns: ['id'],
        where: 'name = ?',
        whereArgs: [playlist.name],
      );

      if (existingResult.isNotEmpty) {
        // Update existing playlist
        playlistId = existingResult.first['id'] as int;
        await txn.update(
          'playlist',
          {'name': playlist.name},
          where: 'id = ?',
          whereArgs: [playlistId],
        );
      } else {
        // Insert new playlist
        playlistId = await txn.insert(
          'playlist',
          playlist.toSqlite() as Map<String, Object?>,
        );
      }

      // 2. Prune old items
      if (versionItemsToPrune.isNotEmpty) {
        final versionPlaceholders = List.filled(
          versionItemsToPrune.length,
          '?',
        ).join(', ');
        await txn.delete(
          'playlist_version',
          where: 'id IN ($versionPlaceholders)',
          whereArgs: [...versionItemsToPrune],
        );
      }

      if (textItemsToPrune.isNotEmpty) {
        final textPlaceholders = List.filled(
          textItemsToPrune.length,
          '?',
        ).join(', ');
        await txn.delete(
          'flow_item',
          where: 'playlist_id = ? AND id IN ($textPlaceholders)',
          whereArgs: [playlistId, ...textItemsToPrune],
        );
      }

      // 3. Upsert text items
      for (final item in textSectionItems) {
        final existingTextResult = await txn.query(
          'flow_item',
          columns: ['id'],
          where: 'firebase_id = ?',
          whereArgs: [item['firebaseContentId']],
        );

        if (existingTextResult.isNotEmpty) {
          // Update existing text item
          await txn.update(
            'flow_item',
            {
              'title': item['title'],
              'content': item['content'],
              'position': item['position'],
            },
            where: 'firebase_id = ?',
            whereArgs: [item['firebaseContentId']],
          );
        } else {
          // Insert new text item
          await txn.insert('flow_item', {
            'added_by': item['addedBy'],
            'firebase_id': item['firebaseContentId'],
            'playlist_id': playlistId,
            'title': item['title'],
            'content': item['content'],
            'position': item['position'],
          });
        }
      }

      // 4. Upsert version items
      for (final item in versionSectionItems) {
        // Check if this version is already in the playlist
        final existingVersionResult = await txn.query(
          'playlist_version',
          columns: ['id'],
          where: 'playlist_id = ? AND version_id = ?',
          whereArgs: [playlistId, item['contentId']],
        );

        if (existingVersionResult.isNotEmpty) {
          // Update existing version item position
          await txn.update(
            'playlist_version',
            {'position': item['position']},
            where: 'id = ?',
            whereArgs: [existingVersionResult.first['id']],
          );
        } else {
          // Insert new version item
          await txn.insert('playlist_version', {
            'version_id': item['contentId'],
            'playlist_id': playlistId,
            'position': item['position'],
          });
        }
      }
    });

    return playlistId;
  }
}
