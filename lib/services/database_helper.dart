import 'dart:io';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;
  static Completer<Database>? _initCompleter;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    
    // If initialization is already in progress, wait for it
    if (_initCompleter != null) return _initCompleter!.future;

    _initCompleter = Completer<Database>();
    try {
      _database = await _initDatabase();
      _initCompleter!.complete(_database);
      return _database!;
    } catch (e) {
      _initCompleter!.completeError(e);
      _initCompleter = null; // Reset so next call can try again
      rethrow;
    }
  }

  Future<bool> _isDatabaseEmptyOrInvalid(String path) async {
    try {
      final db = await openDatabase(path);
      final List<Map<String, dynamic>> tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='Songs';",
      );
      if (tables.isEmpty) {
        await db.close();
        return true;
      }
      final countResult = await db.rawQuery("SELECT COUNT(*) as count FROM Songs;");
      final count = Sqflite.firstIntValue(countResult) ?? 0;
      await db.close();
      return count == 0;
    } catch (_) {
      return true;
    }
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'uecfi.db');

    final prefs = await SharedPreferences.getInstance();
    final packageInfo = await PackageInfo.fromPlatform();
    
    // Clean build number: remove any non-digits (e.g. "32-beta" -> "32")
    final String cleanBuildNumberStr = packageInfo.buildNumber.replaceAll(RegExp(r'[^0-9]'), '');
    final int currentBuildNumber = int.tryParse(cleanBuildNumberStr) ?? 0;
    final int lastCopiedBuildNumber = prefs.getInt('lastCopiedDbBuildNumber') ?? 0;

    // Check if the database exists
    final exists = await databaseExists(path);

    bool shouldCopy = !exists || (currentBuildNumber > 0 && lastCopiedBuildNumber < currentBuildNumber);

    if (!shouldCopy && exists) {
      // If database is empty or invalid on disk, we must re-copy it.
      shouldCopy = await _isDatabaseEmptyOrInvalid(path);
    }

    if (kDebugMode) {
      // In debug mode, we always copy to make sure development database assets are updated seamlessly.
      shouldCopy = true;
    }

    // If DB is missing OR the app has been updated to a new build number OR empty/invalid OR in debug mode
    if (shouldCopy) {
      debugPrint('Database initialization/update detected (exists: $exists, Build: $lastCopiedBuildNumber -> $currentBuildNumber, debug: $kDebugMode).');
      
      // Load from assets FIRST before deleting anything
      try {
        ByteData data = await rootBundle.load('assets/db/uecfi.db');
        List<int> bytes = data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );

        // Make sure the parent directory exists
        await Directory(dirname(path)).create(recursive: true);

        // If an old DB already exists, delete it safely before writing the new one
        if (exists) {
          debugPrint('Deleting old database to apply update...');
          await deleteDatabase(path);
        }

        // Write and flush the bytes written
        await File(path).writeAsBytes(bytes, flush: true);

        // Save the current build number to prevent re-copying until the next update
        await prefs.setInt('lastCopiedDbBuildNumber', currentBuildNumber);
        debugPrint('Database synced successfully for Build $currentBuildNumber');
      } catch (e) {
        debugPrint('CRITICAL: Error copying database from assets: $e');
        // If the database doesn't exist and the copy failed, we have a problem.
        // But we don't delete the old one if it exists until we have the bytes.
        if (!exists) {
          rethrow; // Re-throw if we can't even initialize the first time
        }
      }
    }

    // Open the database
    debugPrint('Opening database at $path');
    return await openDatabase(path);
  }

  Future<List<Map<String, dynamic>>> getSongs() async {
    final db = await database;
    try {
      return await db.query('Songs', orderBy: 'title ASC');
    } catch (e) {
      debugPrint("Error fetching songs: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getPrayers() async {
    final db = await database;
    try {
      return await db.query('Prayers', orderBy: 'page ASC');
    } catch (e) {
      debugPrint("Error fetching prayers: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getBylaws() async {
    final db = await database;
    try {
      return await db.query('bylaws', orderBy: 'chapters ASC');
    } catch (e) {
      debugPrint("Error fetching bylaws: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getCenters() async {
    final db = await database;
    try {
      return await db.query(
        'Centers',
        orderBy: 'centerdistrict ASC, centername ASC',
      );
    } catch (e) {
      debugPrint("Error fetching centers: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> searchTable(
    String table,
    String type,
    String query,
    List<String> fields,
  ) async {
    final db = await database;
    try {
      final whereClause = fields.map((f) => "$f LIKE ?").join(" OR ");
      final whereArgs = List.filled(fields.length, '%$query%');

      final results = await db.query(
        table,
        where: whereClause,
        whereArgs: whereArgs,
      );

      return results.map((row) {
        final mutableRow = Map<String, dynamic>.from(row);
        mutableRow['type'] = type;
        return mutableRow;
      }).toList();
    } catch (e) {
      debugPrint("Error searching $table: $e");
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> searchAll(String query) async {
    final prayers = await searchTable('Prayers', 'Prayer', query, [
      'title',
      'content',
      'title1',
      'content1',
    ]);
    final songs = await searchTable('Songs', 'Song', query, [
      'title',
      'content',
      'chords',
    ]);
    final centers = await searchTable('Centers', 'Center', query, [
      'centername',
      'centeraddress',
      'centerlocation',
      'centerdistrict',
    ]);
    final bylaws = await searchTable('bylaws', 'Bylaw', query, [
      'chapters',
      'title',
      'content',
    ]);

    final List<Map<String, dynamic>> allResults = [];
    allResults.addAll(prayers);
    allResults.addAll(songs);
    allResults.addAll(centers);
    allResults.addAll(bylaws);

    return allResults;
  }

}
