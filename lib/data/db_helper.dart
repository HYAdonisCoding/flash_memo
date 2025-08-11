import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DBHelper {
  // 单例实例
  static final DBHelper _instance = DBHelper._internal();

  // 私有数据库实例
  Database? _database;

  // 工厂构造函数返回单例
  factory DBHelper() {
    return _instance;
  }

  // 私有命名构造函数
  DBHelper._internal();

  // 静态获取单例实例
  static DBHelper get instance => _instance;

  /// 异步获取数据库实例，若未初始化则进行初始化
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('flash_memo.db');
    return _database!;
  }

  /// 初始化数据库，设置版本号和回调函数
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 1, // 设置数据库版本为3，方便未来升级
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  /// 创建数据库表结构
  /// 包含笔记本、笔记、笔记标签关联、笔记内容表
  Future _createDB(Database db, int version) async {
    await db.execute('''
  CREATE TABLE notes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    notebook TEXT NOT NULL,
    title TEXT,
    content TEXT,
    color TEXT,
    is_deleted INTEGER DEFAULT 0,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
  );
  ''');

    await db.execute('''
  CREATE TABLE tags (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE
  );
  ''');

    await db.execute('''
  CREATE TABLE note_tags (
    note_id INTEGER NOT NULL,
    tag_id INTEGER NOT NULL,
    PRIMARY KEY (note_id, tag_id),
    FOREIGN KEY (note_id) REFERENCES notes(id) ON DELETE CASCADE,
    FOREIGN KEY (tag_id) REFERENCES tags(id) ON DELETE CASCADE
  );
  ''');
  }

  /// 数据库升级回调，调用升级逻辑
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await upgradeDB(db, oldVersion, newVersion);
  }

  /// 数据库升级逻辑，按版本差异执行相应迁移操作
  Future<void> upgradeDB(Database db, int oldVersion, int newVersion) async {
    // 示例升级逻辑：版本3新增笔记的优先级字段
    // if (oldVersion < 3) {
    //   await db.execute(
    //     'ALTER TABLE notes ADD COLUMN priority INTEGER DEFAULT 0',
    //   );
    // }

    // 可根据需要继续添加更多升级步骤
  }

  // ------------------ CRUD methods for notes table ------------------
  Future<int> insertNote(Map<String, dynamic> note) async {
    final db = await database;
    return await db.insert('notes', note);
  }

  Future<List<Map<String, dynamic>>> getNotes() async {
    final db = await database;
    return await db.query(
      'notes',
      where: 'is_deleted = ?',
      whereArgs: [0],
      orderBy: 'updated_at DESC',
    );
  }

  Future<int> updateNote(int id, Map<String, dynamic> note) async {
    final db = await database;
    return await db.update('notes', note, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteNote(int id) async {
    final db = await database;
    return await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }

  // ------------------ CRUD methods for tags table ------------------
  Future<int> insertTag(Map<String, dynamic> tag) async {
    final db = await database;
    return await db.insert(
      'tags',
      tag,
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<List<Map<String, dynamic>>> getTags() async {
    final db = await database;
    return await db.query('tags', orderBy: 'name ASC');
  }

  Future<int> deleteTag(int id) async {
    final db = await database;
    return await db.delete('tags', where: 'id = ?', whereArgs: [id]);
  }

  // ------------------ Methods for note_tags table ------------------
  Future<int> addTagToNote(int noteId, int tagId) async {
    final db = await database;
    return await db.insert('note_tags', {
      'note_id': noteId,
      'tag_id': tagId,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<int> removeTagFromNote(int noteId, int tagId) async {
    final db = await database;
    return await db.delete(
      'note_tags',
      where: 'note_id = ? AND tag_id = ?',
      whereArgs: [noteId, tagId],
    );
  }

  Future<List<Map<String, dynamic>>> getTagsForNote(int noteId) async {
    final db = await database;
    return await db.rawQuery(
      '''
      SELECT t.* FROM tags t
      JOIN note_tags nt ON t.id = nt.tag_id
      WHERE nt.note_id = ?
    ''',
      [noteId],
    );
  }

  Future<List<Map<String, dynamic>>> getNotesForTag(int tagId) async {
    final db = await database;
    return await db.rawQuery(
      '''
      SELECT n.* FROM notes n
      JOIN note_tags nt ON n.id = nt.note_id
      WHERE nt.tag_id = ? AND n.is_deleted = 0
      ORDER BY n.updated_at DESC
    ''',
      [tagId],
    );
  }
}
