import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static const _databaseName = "TeacherLMS.db";
  static const _databaseVersion = 6;

  // Table Names
  static const tableSchools = 'schools';
  static const tableClasses = 'classes';
  static const tableSubjects = 'subjects';
  static const tableStudents = 'students';
  static const tableAssignments = 'assignments';
  static const tableScores = 'scores';

  // Singleton instance
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);
    debugPrint('📂 DATABASE: $path');

    return await openDatabase(
      path,
      version: _databaseVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Enable foreign keys for cascading deletes
  Future _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future _onCreate(Database db, int version) async {
    await _createTables(db);
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 6) {
      await db.execute('DROP TABLE IF EXISTS $tableScores');
      await db.execute('DROP TABLE IF EXISTS $tableAssignments');
      await db.execute('DROP TABLE IF EXISTS $tableStudents');
      await db.execute('DROP TABLE IF EXISTS $tableSubjects');
      await db.execute('DROP TABLE IF EXISTS $tableClasses');
      await db.execute('DROP TABLE IF EXISTS $tableSchools');
      await _createTables(db);
    }
  }

  Future _createTables(Database db) async {
    // Schools Table
    await db.execute('''
      CREATE TABLE $tableSchools (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        display_order INTEGER DEFAULT 0
      )
    ''');

    // Classes Table
    await db.execute('''
      CREATE TABLE $tableClasses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        school_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        academic_year TEXT NOT NULL,
        FOREIGN KEY (school_id) REFERENCES $tableSchools (id) ON DELETE CASCADE
      )
    ''');

    // Subjects Table
    await db.execute('''
      CREATE TABLE $tableSubjects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        class_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        FOREIGN KEY (class_id) REFERENCES $tableClasses (id) ON DELETE CASCADE
      )
    ''');

    // Students Table
    await db.execute('''
      CREATE TABLE $tableStudents (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        class_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        remarks TEXT,
        FOREIGN KEY (class_id) REFERENCES $tableClasses (id) ON DELETE CASCADE
      )
    ''');

    // Assignments Table
    await db.execute('''
      CREATE TABLE $tableAssignments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        class_id INTEGER NOT NULL,
        subject_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        month TEXT NOT NULL,
        year TEXT NOT NULL,
        max_points REAL NOT NULL,
        FOREIGN KEY (class_id) REFERENCES $tableClasses (id) ON DELETE CASCADE,
        FOREIGN KEY (subject_id) REFERENCES $tableSubjects (id) ON DELETE CASCADE
      )
    ''');

    // Scores Table
    // Added a UNIQUE constraint on student_id and assignment_id so we can safely UPSERT
    await db.execute('''
      CREATE TABLE $tableScores (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id INTEGER NOT NULL,
        assignment_id INTEGER NOT NULL,
        points_earned REAL NOT NULL,
        FOREIGN KEY (student_id) REFERENCES $tableStudents (id) ON DELETE CASCADE,
        FOREIGN KEY (assignment_id) REFERENCES $tableAssignments (id) ON DELETE CASCADE,
        UNIQUE(student_id, assignment_id)
      )
    ''');
  }

  Future close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  /// Reset singleton for tests
  static void resetDatabase() {
    _database = null;
  }
}
