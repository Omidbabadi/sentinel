import 'package:flutter/foundation.dart';
import 'package:sentinel/core/errors/exceptions.dart';
import 'package:sentinel/core/storage/app_database.dart';
import 'package:sentinel/src/groups/data/model/server_group_model.dart';
import 'package:sqflite/sqflite.dart';

abstract class GroupLocalDatasrc {
  const GroupLocalDatasrc();

  Future<List<ServerGroupModel>> getGroups();

  Future<int> addGroup({
    required ServerGroupModel group,
    List<int> assignedHostIds = const [],
  });

  Future<void> updateGroup({
    required ServerGroupModel group,
    String? previousName,
    List<int>? assignedHostIds,
  });

  Future<void> deleteGroup({
    required int id,
    required String groupName,
  });

  Future<void> assignHostsToGroup({
    required String groupName,
    required List<int> hostIds,
  });
}

class GroupLocalDatasrcImpl implements GroupLocalDatasrc {
  const GroupLocalDatasrcImpl({
    required this._database,
  });

  final AppDatabase _database;

  @override
  Future<List<ServerGroupModel>> getGroups() async {
    try {
      final db = await _database.database;

      // Sync any distinct group_name values already assigned on hosts
      // so legacy/host-entered groups are always present in the groups table.
      await _syncHostGroups(db);

      final rows = await db.query(
        'groups',
        orderBy: 'name COLLATE NOCASE ASC',
      );
      return rows.map(ServerGroupModel.fromMap).toList();
    } catch (e, s) {
      debugPrint(e.toString());
      debugPrintStack(stackTrace: s);
      throw const CacheException(message: 'Failed to load server groups');
    }
  }

  @override
  Future<int> addGroup({
    required ServerGroupModel group,
    List<int> assignedHostIds = const [],
  }) async {
    try {
      final db = await _database.database;
      return await db.transaction((txn) async {
        final id = await txn.insert(
          'groups',
          group.toMap()..remove('id'),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        if (assignedHostIds.isNotEmpty) {
          final now = DateTime.now().toIso8601String();
          final placeholders = List.filled(assignedHostIds.length, '?').join(',');
          await txn.rawUpdate(
            'UPDATE hosts SET group_name = ?, updated_at = ? WHERE id IN ($placeholders)',
            [group.name, now, ...assignedHostIds],
          );
        }

        return id;
      });
    } catch (e, s) {
      debugPrint(e.toString());
      debugPrintStack(stackTrace: s);
      throw const CacheException(message: 'Failed to create server group');
    }
  }

  @override
  Future<void> updateGroup({
    required ServerGroupModel group,
    String? previousName,
    List<int>? assignedHostIds,
  }) async {
    final id = group.id;
    if (id == null) {
      throw ArgumentError('Cannot update a group without an ID.');
    }

    try {
      final db = await _database.database;
      await db.transaction((txn) async {
        await txn.update(
          'groups',
          group.toMap()..remove('id'),
          where: 'id = ?',
          whereArgs: [id],
        );

        final now = DateTime.now().toIso8601String();
        final oldName = previousName?.trim();
        final newName = group.name.trim();

        // Keep existing hosts linked if the group was renamed
        if (oldName != null && oldName.isNotEmpty && oldName != newName) {
          await txn.update(
            'hosts',
            {'group_name': newName, 'updated_at': now},
            where: 'group_name = ?',
            whereArgs: [oldName],
          );
        }

        // If explicit host membership was provided, sync host assignments
        if (assignedHostIds != null) {
          await txn.update(
            'hosts',
            {'group_name': null, 'updated_at': now},
            where: 'group_name = ?',
            whereArgs: [newName],
          );

          if (assignedHostIds.isNotEmpty) {
            final placeholders = List.filled(assignedHostIds.length, '?').join(',');
            await txn.rawUpdate(
              'UPDATE hosts SET group_name = ?, updated_at = ? WHERE id IN ($placeholders)',
              [newName, now, ...assignedHostIds],
            );
          }
        }
      });
    } catch (e, s) {
      debugPrint(e.toString());
      debugPrintStack(stackTrace: s);
      throw const CacheException(message: 'Failed to update server group');
    }
  }

  @override
  Future<void> deleteGroup({
    required int id,
    required String groupName,
  }) async {
    try {
      final db = await _database.database;
      await db.transaction((txn) async {
        await txn.delete(
          'groups',
          where: 'id = ?',
          whereArgs: [id],
        );

        // Unassign hosts that belonged to this group so they become Ungrouped
        final now = DateTime.now().toIso8601String();
        await txn.update(
          'hosts',
          {'group_name': null, 'updated_at': now},
          where: 'group_name = ?',
          whereArgs: [groupName],
        );
      });
    } catch (e, s) {
      debugPrint(e.toString());
      debugPrintStack(stackTrace: s);
      throw const CacheException(message: 'Failed to delete server group');
    }
  }

  @override
  Future<void> assignHostsToGroup({
    required String groupName,
    required List<int> hostIds,
  }) async {
    try {
      final db = await _database.database;
      final now = DateTime.now().toIso8601String();
      await db.transaction((txn) async {
        await txn.update(
          'hosts',
          {'group_name': null, 'updated_at': now},
          where: 'group_name = ?',
          whereArgs: [groupName],
        );

        if (hostIds.isNotEmpty) {
          final placeholders = List.filled(hostIds.length, '?').join(',');
          await txn.rawUpdate(
            'UPDATE hosts SET group_name = ?, updated_at = ? WHERE id IN ($placeholders)',
            [groupName, now, ...hostIds],
          );
        }
      });
    } catch (e, s) {
      debugPrint(e.toString());
      debugPrintStack(stackTrace: s);
      throw const CacheException(message: 'Failed to assign hosts to group');
    }
  }

  Future<void> _syncHostGroups(Database db) async {
    final rows = await db.rawQuery('''
      SELECT DISTINCT TRIM(group_name) AS group_name
      FROM hosts
      WHERE group_name IS NOT NULL AND TRIM(group_name) != ''
    ''');
    if (rows.isEmpty) return;

    final now = DateTime.now().toIso8601String();
    final batch = db.batch();
    for (final row in rows) {
      final name = (row['group_name'] as String?)?.trim();
      if (name != null && name.isNotEmpty) {
        batch.insert(
          'groups',
          {
            'name': name,
            'description': null,
            'color_hex': '#10B981',
            'icon_name': 'folder',
            'created_at': now,
            'updated_at': now,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    }
    await batch.commit(noResult: true);
  }
}
