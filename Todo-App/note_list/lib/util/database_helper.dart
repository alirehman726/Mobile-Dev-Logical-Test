import 'dart:io';
import 'dart:async';
import 'package:note_list/model/note.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static DatabaseHelper _databaseHelper;
  static Database _database;

  DatabaseHelper._createInstance();

  //  Database Table Field
  String listTable = 'list_table';
  String colId = 'id';
  String colTitle = 'title';
  String colDescription = 'description';
  String colPriority = 'priority';
  String colDate = 'date';
  String colTime = 'time';

  //  Database Create
  factory DatabaseHelper() {
    if (_databaseHelper == null) {
      _databaseHelper = DatabaseHelper._createInstance();
    }
    return _databaseHelper;
  }

  Future<Database> get database async {
    if (_database == null) {
      _database = await initializeDatabase();
    }
    return _database;
  }

  // Initialze_Database
  Future<Database> initializeDatabase() async {
    Directory directory = await getApplicationDocumentsDirectory();
    String path = directory.path + 'notes.db';

    var notesDatabase =
        await openDatabase(path, version: 1, onCreate: _createDb);
    return notesDatabase;
  }

  // Table Created
  void _createDb(Database db, int newVersion) async {
    await db.execute(
        'CREATE TABLE $listTable($colId INTEGER PRIMARY KEY AUTOINCREMENT, $colTitle TEXT, '
        '$colDescription TEXT, $colPriority INTEGER, $colDate TEXT, $colTime TEXT)');
  }

  Future<List<Map<String, dynamic>>> getNoteMapList() async {
    Database db = await this.database;

    var result = await db.query(listTable, orderBy: '$colPriority ASC');
    return result;
  }

  //  Insert Note
  Future<int> insertNote(Note note) async {
    print("Time receving at Insert --> ${note.time}");
    Database db = await this.database;
    var result = await db.insert(listTable, note.toMap());
    return result;
  }

  //   Update Note
  Future<int> updateNote(Note note) async {
    print("Time receving at update --> ${note.time}");

    Database db = await this.database;
    var result = await db.update(listTable, note.toMap(),
        where: '$colId = ?', whereArgs: [note.id]);

    return result;
  }

  //   Delete Note
  Future<int> deleteNote(int id) async {
    var db = await this.database;

    int result =
        await db.rawDelete('DELETE FROM $listTable WHERE $colId = $id');
    return result;
  }

  //   Count Node
  Future<int> getCount() async {
    Database db = await this.database;
    List<Map<String, dynamic>> x =
        await db.rawQuery('SELECT COUNT (*) from $listTable');

    int result = Sqflite.firstIntValue(x);

    return result;
  }

  //   Table Show
  Future<int> getShow() async {
    Database db = await this.database;
    List<Map> list = await db.rawQuery('SELECT * FROM $listTable');
    int count = list.length;
    return count;
  }

  //  get Note
  Future<List<Note>> getNoteList() async {
    var noteMapList = await getNoteMapList();
    int count = noteMapList.length;

    List<Note> noteList = List<Note>();
    for (int i = 0; i < count; i++) {
      noteList.add(Note.fromMapObject(noteMapList[i]));
    }
    return noteList;
  }
}
