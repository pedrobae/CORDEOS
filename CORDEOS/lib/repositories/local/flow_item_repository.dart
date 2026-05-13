import 'package:cordeos/helpers/database.dart';
import 'package:cordeos/models/domain/playlist/flow_item.dart';

class FlowItemRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  // ===== CREATE =====
  Future<int> createFlowItem(FlowItem flowItem) async {
    final db = await _databaseHelper.database;

    return await db.insert('flow_item', flowItem.toSQLite());
  }

  Future<int> upsertFlowItem(FlowItem flowItem) async {
    final db = await _databaseHelper.database;

    final existingFlowItem = await getFlowItemByFirebaseId(flowItem.firebaseId);

    if (existingFlowItem == null) {
      // Insert new flow item
      final id = await db.insert('flow_item', flowItem.toSQLite());
      return id;
    } else {
      // Update existing flow item - exclude id from update
      final updateData = flowItem.toSQLite();
      updateData.remove('id'); // Never update the primary key

      await db.update(
        'flow_item',
        updateData,
        where: 'id = ?',
        whereArgs: [existingFlowItem.id],
      );
      return existingFlowItem.id!;
    }
  }

  // ===== READ =====
  Future<FlowItem?> getFlowItem(int id) async {
    final db = await _databaseHelper.database;

    final results = await db.query(
      'flow_item',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (results.isNotEmpty) {
      return FlowItem.fromSqlite(results.first);
    }
    return null;
  }

  Future<FlowItem?> getFlowItemByFirebaseId(String firebaseId) async {
    final db = await _databaseHelper.database;

    final results = await db.query(
      'flow_item',
      where: 'firebase_id = ?',
      whereArgs: [firebaseId],
    );

    if (results.isNotEmpty) {
      return FlowItem.fromSqlite(results.first);
    }
    return null;
  }

  Future<Map<int, FlowItem>> getFlowItemsByIds(List<int> ids) async {
    final db = await _databaseHelper.database;
    Map<int, FlowItem> flowItems = {};

    final placeholders = List.filled(ids.length, '?').join(',');
    final results = await db.query(
      'flow_item',
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );

    for (final row in results) {
      flowItems[row['id'] as int] = FlowItem.fromSqlite(row);
    }

    return flowItems;
  }

  Future<List<FlowItem>> getFlowItemsByPlaylistId(int playlistId) async {
    final db = await _databaseHelper.database;

    final results = await db.query(
      'flow_item',
      where: 'playlist_id = ?',
      whereArgs: [playlistId],
      orderBy: 'position ASC',
    );

    return results.map((row) => FlowItem.fromSqlite(row)).toList();
  }

  // ===== UPDATE =====
  Future<void> updateFlowItem(
    int id, {
    String? title,
    String? content,
    int? position,
    int? duration,
  }) async {
    final db = await _databaseHelper.database;

    await db.transaction((txn) async {
      Map<String, dynamic> updates = {};

      if (title != null) updates['title'] = title;
      if (content != null) updates['content'] = content;
      if (position != null) updates['position'] = position;
      if (duration != null) updates['duration'] = duration;

      if (updates.isNotEmpty) {
        final result = await txn.update(
          'flow_item',
          updates,
          where: 'id = ?',
          whereArgs: [id],
        );

        if (result == 0) {
          throw Exception(
            'Failed to update text section with id $id - no rows affected',
          );
        }
      }
    });
  }

  // ===== DELETE =====
  Future<void> deleteFlowItem(int id) async {
    final db = await _databaseHelper.database;

    await db.transaction((txn) async {
      // First, get the position and playlist_id of the item being deleted
      final result = await txn.query(
        'flow_item',
        columns: ['position', 'playlist_id'],
        where: 'id = ?',
        whereArgs: [id],
      );

      if (result.isNotEmpty) {
        final deletedPosition = result.first['position'] as int;
        final playlistId = result.first['playlist_id'] as int;

        // Delete the text section
        await txn.delete('flow_item', where: 'id = ?', whereArgs: [id]);

        // Adjust positions of items that come after the deleted item
        // Get all flow items in the same playlist with a position greater than the deleted item
        final itemsToUpdate = await txn.query(
          'flow_item',
          columns: ['id', 'position'],
          where: 'playlist_id = ? AND position > ?',
          whereArgs: [playlistId, deletedPosition],
        );

        for (final item in itemsToUpdate) {
          final currentPosition = item['position'] as int;
          final newPos = currentPosition - 1;
          await txn.rawUpdate(
            'UPDATE flow_item SET position = ? WHERE id = ?',
            [newPos, item['id']],
          );
        }
      }
    });
  }
}
