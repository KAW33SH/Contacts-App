import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

class SQLHelper {
  static Future<void> createTables(Database database) async {
    await database.execute("""CREATE TABLE contactTable(
        id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        name TEXT,
        phoneNumber TEXT,
        email TEXT,
        address TEXT,
        photoUrl TEXT
      )
      """);
  }

  static Future<Database> db() async {
    return openDatabase(
      'cb_database.db',
      version: 1,
      onCreate: (Database database, int version) async {
        print(
            "...Creating a table"); // Print statement to check if the table is created
        await createTables(database);
      },
    );
  }

  static Future<int> createContact(
    String name,
    String phoneNumber,
    String email,
    String address,
    String photoUrl,
  ) async {
    final db = await SQLHelper.db();

    final data = {
      'name': name,
      'phoneNumber': phoneNumber,
      'email': email,
      'address': address,
      'photoUrl': photoUrl,
    };
    final id = await db.insert('contactTable', data,
        conflictAlgorithm: ConflictAlgorithm.replace);
    return id;
  }

  static Future<List<Map<String, dynamic>>> getContacts() async {
    final db = await SQLHelper.db();
    return db.query('contactTable', orderBy: "id");
  }

  static Future<List<Map<String, dynamic>>> getContact(int id) async {
    final db = await SQLHelper.db();
    return db.query('contactTable', where: "id = ?", whereArgs: [id], limit: 1);
  }

  static Future<int> updateContact(
    int id,
    String name,
    String phoneNumber,
    String email,
    String address,
    String photoUrl,
  ) async {
    final db = await SQLHelper.db();

    // map the data to be updated
    final data = {
      'name': name,
      'phoneNumber': phoneNumber,
      'email': email,
      'address': address,
      'photoUrl': photoUrl,
    };

    final result =
        await db.update('contactTable', data, where: "id = ?", whereArgs: [id]);
    return result;
  }

  static Future<void> deleteContact(int id) async {
    final db = await SQLHelper.db();
    try {
      await db.delete("contactTable", where: "id = ?", whereArgs: [id]);
    } catch (e) {
      debugPrint("Contact could not be deleted: $e");
    }
  }

  // Image Encoding and Decoding Functions were added by my colleague..

  static String imageToBase64String(String path) {
    final bytes = File(path).readAsBytesSync();
    return base64.encode(bytes);
  }

  static void deleteBase64Image(String base64Image) {
    final RegExp regex = RegExp(r'^data:image/[^;]+;base64,');
    final String base64Str = base64Image.replaceAll(regex, '');
    final Uint8List bytes = base64.decode(base64Str);
    File.fromRawPath(bytes).deleteSync();
  }

  static String encodePhoto(String path) {
    final String base64Image = imageToBase64String(path);
    print('Imaged Encoded');
    return base64Image;
  }

  static File decodePhoto(String base64Image, String fileName) {
    final RegExp regex = RegExp(r'^data:image/[^;]+;base64,');
    final String base64Str = base64Image.replaceAll(regex, '');
    final Uint8List bytes = base64.decode(base64Str);
    final file = File(fileName)..writeAsBytesSync(bytes);
    print('Image Decoded');
    return file;
  }
}
