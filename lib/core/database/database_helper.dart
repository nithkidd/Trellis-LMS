import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static const _databaseName = "TeacherLMS.db";
  static const _databaseVersion = 10;

  // Table Names
  static const tableSchools = 'schools';
  static const tableClasses = 'classes';
  static const tableSubjects = 'subjects';
  static const tableTeachers = 'teachers';
  static const tableClassTeacherSubject = 'class_teacher_subject';
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
    final String path;
    if (!kIsWeb &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      // Use a stable app-specific directory on desktop to avoid
      // CWD-dependent paths from getDatabasesPath() on Windows.
      final dir = await getApplicationSupportDirectory();
      path = join(dir.path, _databaseName);
    } else {
      final dbPath = await getDatabasesPath();
      path = join(dbPath, _databaseName);
    }
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
    } else if (oldVersion < 7) {
      // Add new columns to students table
      await db.execute('ALTER TABLE $tableStudents ADD COLUMN sex TEXT');
      await db.execute(
        'ALTER TABLE $tableStudents ADD COLUMN date_of_birth TEXT',
      );
      await db.execute('ALTER TABLE $tableStudents ADD COLUMN address TEXT');
    }
    if (oldVersion < 8) {
      await db.execute(
        'ALTER TABLE $tableClasses ADD COLUMN is_adviser INTEGER DEFAULT 0',
      );
    }
    if (oldVersion < 9) {
      // Create teachers and class_teacher_subject tables for v9
      await db.execute('''
        CREATE TABLE $tableTeachers (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          school_id INTEGER NOT NULL,
          name TEXT NOT NULL,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (school_id) REFERENCES $tableSchools (id) ON DELETE CASCADE
        )
      ''');

      await db.execute('''
        CREATE TABLE $tableClassTeacherSubject (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          class_id INTEGER NOT NULL,
          teacher_id INTEGER NOT NULL,
          subject_id INTEGER NOT NULL,
          FOREIGN KEY (class_id) REFERENCES $tableClasses (id) ON DELETE CASCADE,
          FOREIGN KEY (teacher_id) REFERENCES $tableTeachers (id) ON DELETE CASCADE,
          FOREIGN KEY (subject_id) REFERENCES $tableSubjects (id) ON DELETE CASCADE,
          UNIQUE(class_id, teacher_id, subject_id)
        )
      ''');
    }
    if (oldVersion < 10) {
      await db.execute(
        'ALTER TABLE $tableSubjects ADD COLUMN display_order INTEGER DEFAULT 0',
      );

      // Backfill existing records in deterministic order.
      final subjects = await db.query(
        tableSubjects,
        columns: ['id', 'class_id'],
        orderBy: 'class_id ASC, id ASC',
      );

      int? currentClassId;
      int order = 0;
      for (final row in subjects) {
        final classId = row['class_id'] as int;
        if (currentClassId != classId) {
          currentClassId = classId;
          order = 0;
        }

        await db.update(
          tableSubjects,
          {'display_order': order},
          where: 'id = ?',
          whereArgs: [row['id']],
        );
        order++;
      }
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
        is_adviser INTEGER DEFAULT 0,
        FOREIGN KEY (school_id) REFERENCES $tableSchools (id) ON DELETE CASCADE
      )
    ''');

    // Subjects Table
    await db.execute('''
      CREATE TABLE $tableSubjects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        class_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        display_order INTEGER DEFAULT 0,
        FOREIGN KEY (class_id) REFERENCES $tableClasses (id) ON DELETE CASCADE
      )
    ''');

    // Teachers Table
    await db.execute('''
      CREATE TABLE $tableTeachers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        school_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (school_id) REFERENCES $tableSchools (id) ON DELETE CASCADE
      )
    ''');

    // Class-Teacher-Subject Assignment Table
    await db.execute('''
      CREATE TABLE $tableClassTeacherSubject (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        class_id INTEGER NOT NULL,
        teacher_id INTEGER NOT NULL,
        subject_id INTEGER NOT NULL,
        FOREIGN KEY (class_id) REFERENCES $tableClasses (id) ON DELETE CASCADE,
        FOREIGN KEY (teacher_id) REFERENCES $tableTeachers (id) ON DELETE CASCADE,
        FOREIGN KEY (subject_id) REFERENCES $tableSubjects (id) ON DELETE CASCADE,
        UNIQUE(class_id, teacher_id, subject_id)
      )
    ''');

    // Students Table
    await db.execute('''
      CREATE TABLE $tableStudents (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        class_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        sex TEXT,
        date_of_birth TEXT,
        address TEXT,
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
