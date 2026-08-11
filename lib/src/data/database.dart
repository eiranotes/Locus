import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._(this.database);

  final Database database;

  static const int schemaVersion = 5;
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
    await _createCollectedPatterns(db);
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
    await _createVisitorEncounters(db);
    await db.execute('''
      CREATE TABLE metadata (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
    await _createRequestFirstTables(db);
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
    if (oldVersion < 3) {
      await _createCollectedPatterns(db);
    }
    if (oldVersion < 4) {
      await _createVisitorEncounters(db);
      await db.execute('''
        INSERT OR IGNORE INTO visitor_encounters (
          id, visitor_id, seen_at, variant_key, snapshot_json
        )
        SELECT
          'legacy-' || id, visitor_id, last_seen_at, variant_key, snapshot_json
        FROM visitor_sightings
      ''');
    }
    if (oldVersion < 5) {
      await _createRequestFirstTables(db);
    }
  }

  static Future<void> _createVisitorEncounters(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS visitor_encounters (
        id TEXT PRIMARY KEY,
        visitor_id TEXT NOT NULL,
        seen_at INTEGER NOT NULL,
        variant_key TEXT NOT NULL,
        snapshot_json TEXT
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_visitor_encounter_time '
      'ON visitor_encounters(visitor_id, seen_at DESC)',
    );
  }

  static Future<void> _createCollectedPatterns(Database db) async {
    await db.execute('''
      CREATE TABLE collected_patterns (
        id TEXT PRIMARY KEY,
        pattern_key TEXT NOT NULL,
        scope TEXT NOT NULL,
        family TEXT NOT NULL,
        label_ko TEXT NOT NULL,
        description_ko TEXT NOT NULL,
        strength REAL NOT NULL,
        component_keys_json TEXT NOT NULL,
        captured_at INTEGER NOT NULL,
        source_record_id TEXT NOT NULL,
        schema_version TEXT NOT NULL,
        UNIQUE(source_record_id, pattern_key),
        FOREIGN KEY(source_record_id) REFERENCES capture_records(id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_pattern_time ON collected_patterns(captured_at DESC)',
    );
    await db.execute(
      'CREATE INDEX idx_pattern_key ON collected_patterns(pattern_key, captured_at DESC)',
    );
  }

  static Future<void> _createRequestFirstTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS specimens (
        id TEXT PRIMARY KEY,
        capture_record_id TEXT NOT NULL UNIQUE,
        captured_at INTEGER NOT NULL,
        channel_keys_json TEXT NOT NULL,
        feature_vector_json TEXT NOT NULL,
        context_json TEXT NOT NULL,
        confidence REAL NOT NULL,
        eligibility TEXT NOT NULL,
        preview_seed INTEGER NOT NULL,
        feature_schema_version TEXT NOT NULL,
        legacy_payload_json TEXT,
        FOREIGN KEY(capture_record_id) REFERENCES capture_records(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS visitor_requests (
        id TEXT PRIMARY KEY,
        visitor_id TEXT NOT NULL,
        template_id TEXT NOT NULL,
        prompt_ko TEXT NOT NULL,
        issued_at INTEGER NOT NULL,
        expires_at INTEGER,
        slot_index INTEGER NOT NULL,
        status TEXT NOT NULL,
        target_json TEXT NOT NULL,
        difficulty INTEGER NOT NULL,
        history_comparison TEXT NOT NULL,
        history_specimen_id TEXT,
        request_schema_version TEXT NOT NULL,
        completed_at INTEGER,
        FOREIGN KEY(history_specimen_id) REFERENCES specimens(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS specimen_matches (
        specimen_id TEXT NOT NULL,
        request_id TEXT NOT NULL,
        score REAL NOT NULL,
        passed INTEGER NOT NULL,
        verdict TEXT NOT NULL,
        breakdown_json TEXT NOT NULL,
        matcher_version TEXT NOT NULL,
        PRIMARY KEY(specimen_id, request_id),
        FOREIGN KEY(specimen_id) REFERENCES specimens(id) ON DELETE CASCADE,
        FOREIGN KEY(request_id) REFERENCES visitor_requests(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS specimen_assignments (
        id TEXT PRIMARY KEY,
        specimen_id TEXT NOT NULL UNIQUE,
        request_id TEXT NOT NULL UNIQUE,
        visitor_id TEXT NOT NULL,
        assigned_at INTEGER NOT NULL,
        accepted_score REAL NOT NULL,
        FOREIGN KEY(specimen_id) REFERENCES specimens(id),
        FOREIGN KEY(request_id) REFERENCES visitor_requests(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS visitor_relationships (
        visitor_id TEXT PRIMARY KEY,
        stage INTEGER NOT NULL,
        fulfilled_count INTEGER NOT NULL,
        last_fulfilled_at INTEGER,
        unlocked_reward_keys_json TEXT NOT NULL,
        state_json TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS relationship_events (
        id TEXT PRIMARY KEY,
        visitor_id TEXT NOT NULL,
        request_id TEXT,
        specimen_id TEXT,
        event_kind TEXT NOT NULL,
        occurred_at INTEGER NOT NULL,
        match_score REAL,
        snapshot_json TEXT NOT NULL,
        FOREIGN KEY(request_id) REFERENCES visitor_requests(id),
        FOREIGN KEY(specimen_id) REFERENCES specimens(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS scene_objects (
        id TEXT PRIMARY KEY,
        definition_id TEXT NOT NULL,
        origin_kind TEXT NOT NULL,
        source_visitor_id TEXT,
        source_request_id TEXT,
        visual_seed INTEGER NOT NULL,
        generator_version TEXT NOT NULL,
        variant_key TEXT NOT NULL,
        lifecycle TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        legacy_payload_json TEXT,
        FOREIGN KEY(source_request_id) REFERENCES visitor_requests(id)
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS scene_placements (
        id TEXT PRIMARY KEY,
        scene_object_id TEXT NOT NULL UNIQUE,
        column_index INTEGER NOT NULL,
        row_index INTEGER NOT NULL,
        rotation INTEGER NOT NULL,
        FOREIGN KEY(scene_object_id) REFERENCES scene_objects(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sense_profile (
        axis_key TEXT PRIMARY KEY,
        unlocked INTEGER NOT NULL,
        calibration_json TEXT NOT NULL,
        unlocked_at INTEGER,
        source_visitor_id TEXT
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_specimen_time '
      'ON specimens(captured_at DESC)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_request_status_time '
      'ON visitor_requests(status, issued_at DESC)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_relationship_event_time '
      'ON relationship_events(visitor_id, occurred_at DESC)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_scene_object_time '
      'ON scene_objects(created_at DESC)',
    );
  }

  Future<void> close() => database.close();
}
