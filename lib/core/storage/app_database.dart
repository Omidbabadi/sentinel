import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

class AppDatabase {
  AppDatabase.internal();

  static final AppDatabase instance = AppDatabase.internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    final databasesPath = await getDatabasesPath();
    final databasePath = p.join(databasesPath, 'sentinel.db');
    _database = await openDatabase(
      databasePath,
      version: 4,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE hosts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            ip TEXT NOT NULL,
            hostname TEXT NOT NULL,
            port INTEGER NOT NULL,
            username TEXT NOT NULL,
            auth_type TEXT NOT NULL,
            group_name TEXT,
            os_name TEXT NOT NULL DEFAULT 'unknown',
            os_version TEXT NOT NULL DEFAULT '',
            ping REAL DEFAULT 0,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE INDEX idx_hosts_name ON hosts(hostname)
        ''');
        await _createGroupsTable(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            ALTER TABLE hosts
            ADD COLUMN os_name TEXT NOT NULL DEFAULT 'unknown'
          ''');
          await db.execute('''
            ALTER TABLE hosts
            ADD COLUMN os_version TEXT NOT NULL DEFAULT ''
          ''');
        }
        if (oldVersion < 3) {
          await db.execute('''
            ALTER TABLE hosts
            ADD COLUMN ping REAL DEFAULT 0
          ''');
        }
        if (oldVersion < 4) {
          await _createGroupsTable(db);
        }
      },
    );

    return _database!;
  }

  Future<void> _createGroupsTable(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS groups (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        description TEXT,
        color_hex TEXT NOT NULL DEFAULT '#10B981',
        icon_name TEXT NOT NULL DEFAULT 'folder',
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_groups_name ON groups(name)
    ''');
  }
}
