import 'dart:io';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'uecfi.db');

    final prefs = await SharedPreferences.getInstance();
    final packageInfo = await PackageInfo.fromPlatform();
    
    // Get the build number (e.g., "27") as an integer for comparison
    final int currentBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;
    final int lastCopiedBuildNumber = prefs.getInt('lastCopiedDbBuildNumber') ?? 0;

    // Check if the database exists
    final exists = await databaseExists(path);

    // If DB is missing OR the app has been updated to a new build number
    if (!exists || lastCopiedBuildNumber < currentBuildNumber) {
      debugPrint('Database update detected (Build $lastCopiedBuildNumber -> $currentBuildNumber). Syncing assets...');
      
      // Make sure the parent directory exists
      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (_) {}

      // If an old DB already exists and we are upgrading, delete it first
      if (exists) {
        await deleteDatabase(path);
      }

      // Copy from assets
      try {
        ByteData data = await rootBundle.load('assets/db/uecfi.db');
        List<int> bytes = data.buffer.asUint8List(
          data.offsetInBytes,
          data.lengthInBytes,
        );

        // Write and flush the bytes written
        await File(path).writeAsBytes(bytes, flush: true);

        // Save the current build number to prevent re-copying until the next Play Store update
        await prefs.setInt('lastCopiedDbBuildNumber', currentBuildNumber);
        debugPrint('Database synced successfully for Build $currentBuildNumber');
      } catch (e) {
        debugPrint('Error copying database from assets: $e');
        // If copy fails and DB doesn't exist, this will cause issues, but we log it.
      }
    }

    // Open the database
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

    final List<Map<String, dynamic>> allResults = [];
    allResults.addAll(prayers);
    allResults.addAll(songs);
    allResults.addAll(centers);

    return allResults;
  }

}
