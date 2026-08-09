import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._(this.database);

  final Database database;

  static const int schemaVersion = 2;
  static const String productionDatabaseName = 'reality_diorama.sqlite3';
  static const String demoDatabaseName = 'reality_diorama_demo.sqlite3';

  static Future<AppDatabase> open({bool demoMode = false}) async {
    final root = await getDatabasesPath();
    final database = await openDatabase(
      p.join(root, demoMode ? demoDatabaseName : productionDatabaseName),
      version: schemaVersion,
      onConfigure: (Database db) async {
        await db.execute('PRAGMA foreign_keys = ON');
        await db.setJournalMode('WAL');
      },
      onCreate: _create,
      onUpgrade: _upgrade,
    );
    return AppDatabase._(database);
  }

  static Future<void> _create(Database db, int version) async {
    await db.execute('''
      CREATE TABLE capture_records (
        id TEXT PRIMARY KEY,
        captured_at INTEGER NOT NULL,
        coarse_cell_id TEXT,
        user_place_label TEXT,
        time_band TEXT NOT NULL,
        season TEXT NOT NULL,
        weather_basis TEXT NOT NULL,
        source_version TEXT NOT NULL,
        weather_material_id TEXT,
        surrounding_material_id TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE weather_materials (
        id TEXT PRIMARY KEY,
        kind TEXT NOT NULL,
        time_band TEXT NOT NULL,
        season TEXT NOT NULL,
        captured_at INTEGER NOT NULL,
        coarse_cell_id TEXT,
        source_record_id TEXT NOT NULL,
        visual_seed INTEGER NOT NULL,
        provider_name TEXT NOT NULL,
        trait_keys_json TEXT NOT NULL DEFAULT '[]',
        trait_schema_version TEXT NOT NULL DEFAULT 'legacy-none',
        consumed_at INTEGER,
        crafted_object_id TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE surrounding_materials (
        id TEXT PRIMARY KEY,
        kind TEXT NOT NULL,
        confidence REAL NOT NULL,
        captured_at INTEGER NOT NULL,
        coarse_cell_id TEXT,
        source_record_id TEXT NOT NULL,
        feature_schema_version TEXT NOT NULL,
        consumed_at INTEGER,
        crafted_object_id TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE step_buckets (
        day_key TEXT PRIMARY KEY,
        observed_steps INTEGER NOT NULL,
        spent_steps INTEGER NOT NULL,
        last_synced_at INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE crafted_objects (
        id TEXT PRIMARY KEY,
        recipe_id TEXT NOT NULL,
        kind TEXT NOT NULL,
        weather_material_id TEXT NOT NULL,
        weather_kind TEXT NOT NULL,
        surrounding_material_id TEXT,
        surrounding_kind TEXT,
        required_steps INTEGER NOT NULL,
        applied_steps INTEGER NOT NULL,
        lifecycle TEXT NOT NULL,
        visual_seed INTEGER NOT NULL,
        generator_version TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        focus_trait TEXT,
        variant_key TEXT NOT NULL DEFAULT 'base'
      )
    ''');
    await db.execute('''
      CREATE TABLE placements (
        id TEXT PRIMARY KEY,
        crafted_object_id TEXT NOT NULL UNIQUE,
        column_index INTEGER NOT NULL,
        row_index INTEGER NOT NULL,
        rotation INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE visitor_sightings (
        id TEXT PRIMARY KEY,
        visitor_id TEXT NOT NULL UNIQUE,
        first_seen_at INTEGER NOT NULL,
        last_seen_at INTEGER NOT NULL,
        variant_key TEXT NOT NULL,
        snapshot_json TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE metadata (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_capture_time ON capture_records(captured_at DESC)',
    );
    await db.execute(
      'CREATE INDEX idx_weather_available ON weather_materials(consumed_at, captured_at DESC)',
    );
    await db.execute(
      'CREATE INDEX idx_surrounding_available ON surrounding_materials(consumed_at, captured_at DESC)',
    );
  }

  static Future<void> _upgrade(Database db, int oldVersion, int _) async {
    if (oldVersion < 2) {
      await db.execute(
        "ALTER TABLE weather_materials ADD COLUMN trait_keys_json TEXT NOT NULL DEFAULT '[]'",
      );
      await db.execute(
        "ALTER TABLE weather_materials ADD COLUMN trait_schema_version TEXT NOT NULL DEFAULT 'legacy-none'",
      );
      await db.execute(
        'ALTER TABLE crafted_objects ADD COLUMN focus_trait TEXT',
      );
      await db.execute(
        "ALTER TABLE crafted_objects ADD COLUMN variant_key TEXT NOT NULL DEFAULT 'base'",
      );
    }
  }

  Future<void> close() => database.close();
}
