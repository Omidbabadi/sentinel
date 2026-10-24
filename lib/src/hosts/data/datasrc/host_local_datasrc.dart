import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:sentinel/core/errors/exceptions.dart';
import 'package:sentinel/core/security/credential_store.dart';
import 'package:sentinel/core/storage/app_database.dart';
import 'package:sentinel/src/hosts/data/model/host_model.dart';
import 'package:sqflite/sqflite.dart';

import '../../../../core/common/internet_conectivity.dart';

abstract class HostLocalDatasrc {
  const HostLocalDatasrc();

  Future<List<HostModel>> getHosts();
  Future<int> addHost({
    required HostModel host,
    required String secret,
    String? passphrase,
  });

  Future<void> update({
    required HostModel host,
    String? secret,
    String? passphrase,
  });

  Future<void> delete(int id);

  Future<HostModel> pingHost({
    required HostModel host,
    Duration timeout = const Duration(seconds: 3),
  });

  Future<List<HostModel>> pingAllHosts({
    required List<HostModel> hosts,

    Duration timeout = const Duration(seconds: 3),
  });
}

class HostLocalDatasrcImpl implements HostLocalDatasrc {
  const HostLocalDatasrcImpl({
    required this._database,
    required this._credentialStore,
    required this._networkInfo,
  });

  final AppDatabase _database;
  final CredentialStore _credentialStore;
  final NetworkInfo _networkInfo;

  @override
  Future<List<HostModel>> getHosts() async {
    try {
      final hasInternet = await _networkInfo.checkConnectivity();
      final db = await _database.database;
      final rows = await db.query(
        'hosts',
        orderBy: 'hostname COLLATE NOCASE ASC',
      );
      final hosts = rows.map(HostModel.fromMap).toList();
      if (!hasInternet) {
        return hosts.map((h) => h.copyWith(clearPing: true)).toList();
      }
      return hosts;
    } catch (e, s) {
      debugPrint(e.toString());
      debugPrintStack(stackTrace: s);
      throw const CacheException(message: 'there was an error ');
    }
  }

  @override
  Future<int> addHost({
    required HostModel host,
    required String secret,
    String? passphrase,
  }) async {
    final db = await _database.database;
    final id = await db.insert(
      'hosts',
      host.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
    try {
      await _ensureGroupExists(db, host.groupName);
      await _credentialStore.save(
        hostId: id,
        secret: secret,
        passphrase: passphrase,
      );
      return id;
    } catch (e, s) {
      debugPrint(e.toString());
      debugPrintStack(stackTrace: s);
      await db.delete('hosts', where: 'id = ?', whereArgs: [id]);

      throw const CacheException(message: 'there was an error ');
    }
  }

  @override
  Future<void> update({
    required HostModel host,
    String? secret,
    String? passphrase,
  }) async {
    final id = host.id;
    if (id == null) {
      throw ArgumentError('Cannot update a host without an ID.');
    }
    final db = await _database.database;
    try {
      await db.update(
        'hosts',
        host.toMap()..remove('id'),
        where: 'id = ?',
        whereArgs: [id],
      );
      await _ensureGroupExists(db, host.groupName);
      if (secret != null && secret.isNotEmpty) {
        await _credentialStore.save(
          hostId: id,
          secret: secret,
          passphrase: passphrase,
        );
      }
    } catch (e, s) {
      debugPrint(e.toString());
      debugPrintStack(stackTrace: s);
      throw const CacheException(message: 'there was an error ');
    }
  }

  @override
  Future<void> delete(int id) async {
    final db = await _database.database;
    try {
      await db.delete('hosts', where: 'id = ?', whereArgs: [id]);
      await _credentialStore.delete(id);
    } catch (e, s) {
      debugPrint(e.toString());
      debugPrintStack(stackTrace: s);
      throw const CacheException(message: 'there was an error ');
    }
  }

  @override
  Future<HostModel> pingHost({
    required HostModel host,
    Duration timeout = const Duration(seconds: 3),
  }) async {
    try {
      final hasInternet = await _networkInfo.checkConnectivity();
      final latency = hasInternet
          ? await _measureTcpLatency(
              ip: host.ip.trim().isNotEmpty
                  ? host.ip.trim()
                  : host.hostname.trim(),
              port: host.port,
              timeout: timeout,
            )
          : null;

      final updatedHost = host.copyWith(
        ping: latency,
        clearPing: latency == null,
        updatedAt: DateTime.now(),
      );

      if (updatedHost.id != null) {
        await update(host: updatedHost);
      }

      return updatedHost;
    } catch (e, s) {
      debugPrint(e.toString());
      debugPrintStack(stackTrace: s);
      throw const CacheException(message: 'Failed to ping host');
    }
  }

  @override
  Future<List<HostModel>> pingAllHosts({
    required List<HostModel> hosts,
    Duration timeout = const Duration(seconds: 3),
  }) async {
    try {
      if (hosts.isEmpty) return hosts;

      final hasInternet = await _networkInfo.checkConnectivity();
      final now = DateTime.now();

      final List<HostModel> updatedHosts;
      if (!hasInternet) {
        updatedHosts = hosts
            .map((h) => h.copyWith(clearPing: true, updatedAt: now))
            .toList();
      } else {
        updatedHosts = await Future.wait(
          hosts.map((host) async {
            final target = host.ip.trim().isNotEmpty
                ? host.ip.trim()
                : host.hostname.trim();
            final latency = await _measureTcpLatency(
              ip: target,
              port: host.port,
              timeout: timeout,
            );
            return host.copyWith(
              ping: latency,
              clearPing: latency == null,
              updatedAt: now,
            );
          }),
        );
      }

      final db = await _database.database;
      final batch = db.batch();
      for (final host in updatedHosts) {
        if (host.id != null) {
          batch.update(
            'hosts',
            host.toMap()..remove('id'),
            where: 'id = ?',
            whereArgs: [host.id],
          );
        }
      }
      await batch.commit(noResult: true);

      return updatedHosts;
    } catch (e, s) {
      debugPrint(e.toString());
      debugPrintStack(stackTrace: s);
      throw const CacheException(message: 'Failed to ping hosts');
    }
  }

  Future<double?> _measureTcpLatency({
    required String ip,
    required int port,
    required Duration timeout,
  }) async {
    if (ip.isEmpty) return null;

    final stopwatch = Stopwatch()..start();
    Socket? socket;

    try {
      socket = await Socket.connect(ip, port, timeout: timeout);
      stopwatch.stop();
      final ms = stopwatch.elapsedMicroseconds / 1000.0;
      return double.parse(ms.toStringAsFixed(2));
    } catch (_) {
      return null;
    } finally {
      socket?.destroy();
    }
  }

  Future<void> _ensureGroupExists(Database db, String? groupName) async {
    final trimmed = groupName?.trim();
    if (trimmed == null || trimmed.isEmpty) return;

    final now = DateTime.now().toIso8601String();
    await db.insert(
      'groups',
      {
        'name': trimmed,
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
