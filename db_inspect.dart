import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  sqfliteFfiInit();
  var databaseFactory = databaseFactoryFfi;
  
  var dbPath = 'c:/Users/cjmai/Project/uecfi_flutter_app_vanilla/assets/db/uecfi.db';
  var db = await databaseFactory.openDatabase(dbPath);
  
  try {
    print('Listing all tables:');
    var tables = await db.rawQuery("SELECT name FROM sqlite_master WHERE type='table';");
    for (var tbl in tables) {
      print('- ${tbl['name']}');
    }
  } catch (e) {
    print('Error: $e');
  } finally {
    await db.close();
  }
}
