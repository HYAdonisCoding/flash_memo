import 'package:flash_memo/common/constants.dart';
import 'package:flash_memo/data/db_helper.dart';
import 'package:flash_memo/data/note_models.dart';

/// NoteRepository
/// 负责笔记数据的增删改查（CRUD）及相关数据处理。
/// 提供便捷的方法管理笔记、分类（笔记本）、标签等。
class NoteRepository {
  final DBHelper _dbHelper = DBHelper.instance;

  Future<int> insertNote(Note note) async {
    final db = await _dbHelper.database;
    // Insert note into 'notes' table (excluding tags)
    final noteMap = Map<String, dynamic>.from(note.toMap());
    noteMap.remove('tags'); // Remove tags field if present
    noteMap.remove('id'); // Remove id field to avoid UNIQUE constraint errors
    final noteId = await db.insert('notes', noteMap);

    // Insert tags and mappings
    if (note.tags is List<String>) {
      for (final tag in note.tags) {
        // Insert tag if not exists
        final tagRes = await db.query(
          'tags',
          where: 'name = ?',
          whereArgs: [tag],
          limit: 1,
        );
        int tagId;
        if (tagRes.isEmpty) {
          tagId = await db.insert('tags', {'name': tag});
        } else {
          tagId = tagRes.first['id'] as int;
        }
        // Insert into note_tags
        await db.insert('note_tags', {'note_id': noteId, 'tag_id': tagId});
      }
    }
    return noteId;
  }

  Future<int> updateNote(Note note) async {
    final db = await _dbHelper.database;
    // Update note in 'notes' table (excluding tags)
    final noteMap = Map<String, dynamic>.from(note.toMap());
    noteMap.remove('tags');
    final result = await db.update(
      'notes',
      noteMap,
      where: 'id = ?',
      whereArgs: [note.id],
    );
    // Remove all existing mappings in note_tags
    await db.delete('note_tags', where: 'note_id = ?', whereArgs: [note.id]);
    // Re-insert mappings for current tags
    if (note.tags is List<String>) {
      for (final tag in note.tags) {
        // Insert tag if not exists
        final tagRes = await db.query(
          'tags',
          where: 'name = ?',
          whereArgs: [tag],
          limit: 1,
        );
        int tagId;
        if (tagRes.isEmpty) {
          tagId = await db.insert('tags', {'name': tag});
        } else {
          tagId = tagRes.first['id'] as int;
        }
        // Insert into note_tags
        await db.insert('note_tags', {'note_id': note.id, 'tag_id': tagId});
      }
    }
    return result;
  }

  /// 保存笔记：有id则更新，无id则新增
  Future<int> saveNote(Note note) async {
    if (note.id != null) {
      // 已存在笔记，执行更新
      return await updateNote(note);
    } else {
      // 新笔记，执行插入
      return await insertNote(note);
    }
  }

  Future<int> deleteNote(int id) async {
    final db = await _dbHelper.database;
    // 软删除，更新is_deleted字段
    final result = await db.update(
      'notes',
      {'is_deleted': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
    // 可选：删除note_tags映射
    await db.delete('note_tags', where: 'note_id = ?', whereArgs: [id]);
    return result;
  }

  /// 获取笔记列表的方法。
  ///
  /// 功能：从数据库中查询所有笔记，支持选择是否包含已删除的笔记。
  /// 
  /// 参数：
  /// - [includeDeleted]：是否包含已删除的笔记，默认为 false（即只返回未删除的笔记）。
  ///
  /// 返回值：
  /// - 返回一个 [Future]，其结果为 [List<Note>]，即笔记对象列表。
  Future<List<Note>> getNotes({bool includeDeleted = false}) async {
    final db = await _dbHelper.database;
    // 根据参数决定查询条件，includeDeleted 为 true 时查询所有笔记，否则只查未删除的笔记
    String whereClause = includeDeleted ? '1=1' : 'is_deleted = 0';
    // 查询 notes 表，获取所有符合条件的笔记数据
    final result = await db.query('notes', where: whereClause);
    List<Note> notes = [];
    for (final noteMap in result) {
      // 针对每条笔记，查询其关联的标签
      final tagRows = await db.rawQuery(
        '''
        SELECT t.name FROM tags t
        INNER JOIN note_tags nt ON nt.tag_id = t.id
        WHERE nt.note_id = ?
      ''',
        [noteMap['id']],
      );
      // 将标签名称提取为字符串列表
      final tags = tagRows.map((row) => row['name'] as String).toList();
      // 合并笔记和标签数据，构造 Note 实例
      final note = Note.fromMap({...noteMap, 'tags': tags});
      notes.add(note);
    }
    // 返回所有组装好的笔记对象列表
    return notes;
  }

  Future<List<Note>> getAllNotes() async {
    return getNotes(includeDeleted: false);
  }

  // 获取回收站的笔记
  Future<List<Note>> getDeletedNotes() async {
    return getNotes(includeDeleted: true);
  }

  /// 获取数据库中所有存在的笔记本名称（去重）
  /// 获取带统计信息的所有笔记本列表
  Future<List<NoteCategory>> getNoteCategories() async {
    final db = await _dbHelper.database;

    // SQL聚合查询
    final result = await db.rawQuery('''
    SELECT 
      notebook AS title,
      COUNT(*) AS noteCount,
      SUM(LENGTH(content)) AS totalWords,
      MAX(updated_at) AS lastUpdated
    FROM notes
    WHERE is_deleted = 0 AND notebook IS NOT NULL AND notebook != ''
    GROUP BY notebook
    ORDER BY lastUpdated DESC
  ''');

    return result.map((map) {
      return NoteCategory(
        title: map['title'] as String,
        noteCount: (map['noteCount'] as int?) ?? 0,
        totalWords: (map['totalWords'] as int?) ?? 0,
        lastUpdated:
            DateTime.tryParse(map['lastUpdated'] as String? ?? '') ??
            DateTime.now(),
      );
    }).toList();
  }

  Future<List<NoteCategory>> getNoteCategoriesWithSpecial() async {
    final db = await _dbHelper.database;

    // 1. 查询所有未删除笔记的统计数据（“所有笔记”）
    final allNotesResult = await db.rawQuery('''
  SELECT 
    COUNT(*) AS noteCount,
    SUM(LENGTH(content)) AS totalWords,
    MAX(updated_at) AS lastUpdated
  FROM notes
  WHERE is_deleted = 0
  ''');

    final allNotesData = allNotesResult.first;
    final allNotesCategory = NoteCategory(
      title: '所有笔记',
      noteCount: (allNotesData['noteCount'] as int?) ?? 0,
      totalWords: (allNotesData['totalWords'] as int?) ?? 0,
      lastUpdated:
          DateTime.tryParse(allNotesData['lastUpdated'] as String? ?? '') ??
          DateTime.now(),
    );

    // 2. 预设默认笔记本名称列表
    final placeholders = List.filled(kDefaultNotebooks.length, '?').join(',');

    // 3. 按默认笔记本名称过滤查询
    final notebooksResult = await db.rawQuery('''
SELECT 
  notebook AS title,
  COUNT(*) AS noteCount,
  SUM(LENGTH(content)) AS totalWords,
  MAX(updated_at) AS lastUpdated
FROM notes
WHERE is_deleted = 0 AND notebook IN ($placeholders)
GROUP BY notebook
ORDER BY lastUpdated DESC
''', kDefaultNotebooks);

    // 转成Map方便查找
    final notebooksMap = <String, NoteCategory>{};
    for (final map in notebooksResult) {
      notebooksMap[map['title'] as String] = NoteCategory(
        title: map['title'] as String,
        noteCount: (map['noteCount'] as int?) ?? 0,
        totalWords: (map['totalWords'] as int?) ?? 0,
        lastUpdated:
            DateTime.tryParse(map['lastUpdated'] as String? ?? '') ??
            DateTime.now(),
      );
    }

    // 对默认笔记本列表进行补齐
    final notebooks = kDefaultNotebooks.map((title) {
      if (notebooksMap.containsKey(title)) {
        return notebooksMap[title]!;
      } else {
        return NoteCategory(
          title: title,
          noteCount: 0,
          totalWords: 0,
          lastUpdated: DateTime.now(),
        );
      }
    }).toList();

    // 4. 查询回收站统计数据
    final recycleResult = await db.rawQuery('''
  SELECT 
    COUNT(*) AS noteCount,
    SUM(LENGTH(content)) AS totalWords,
    MAX(updated_at) AS lastUpdated
  FROM notes
  WHERE is_deleted = 1
  ''');

    final recycleData = recycleResult.first;
    final recycleCategory = NoteCategory(
      title: '回收站',
      noteCount: (recycleData['noteCount'] as int?) ?? 0,
      totalWords: (recycleData['totalWords'] as int?) ?? 0,
      lastUpdated:
          DateTime.tryParse(recycleData['lastUpdated'] as String? ?? '') ??
          DateTime.now(),
    );

    // 5. 拼接列表，确保“所有笔记”第一个，“回收站”最后
    return [allNotesCategory, ...notebooks, recycleCategory];
  }

  // 根据标签查询笔记（多表关联）
  Future<List<Note>> getNotesByTag(String tag) async {
    final db = await _dbHelper.database;
    // Find notes joined with note_tags and tags
    final result = await db.rawQuery(
      '''
      SELECT n.* FROM notes n
      INNER JOIN note_tags nt ON n.id = nt.note_id
      INNER JOIN tags t ON nt.tag_id = t.id
      WHERE n.is_deleted = 0 AND t.name = ?
    ''',
      [tag],
    );
    List<Note> notes = [];
    for (final noteMap in result) {
      // Fetch tags for this note
      final tagRows = await db.rawQuery(
        '''
        SELECT t.name FROM tags t
        INNER JOIN note_tags nt ON nt.tag_id = t.id
        WHERE nt.note_id = ?
      ''',
        [noteMap['id']],
      );
      final tags = tagRows.map((row) => row['name'] as String).toList();
      final note = Note.fromMap({...noteMap, 'tags': tags});
      notes.add(note);
    }
    return notes;
  }

  /// 根据笔记ID软删除笔记，更新is_deleted字段
  Future<int> deleteNoteById(int id) async {
    final db = await _dbHelper.database;
    // 软删除，设置is_deleted为1
    final result = await db.update(
      'notes',
      {'is_deleted': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
    // 同时删除note_tags关联
    await db.delete('note_tags', where: 'note_id = ?', whereArgs: [id]);
    return result;
  }

  /// 硬删除笔记，彻底从数据库删除，不仅仅是软删除
  Future<int> hardDeleteNoteById(int id) async {
    final db = await _dbHelper.database;
    // 先删除关联的标签映射
    await db.delete('note_tags', where: 'note_id = ?', whereArgs: [id]);
    // 再删除笔记记录
    final result = await db.delete('notes', where: 'id = ?', whereArgs: [id]);
    return result;
  }

  Future<List<Note>> getNotesByNotebookName(String notebook) async {
    final db = await _dbHelper.database;
    final notesMaps = await db.query(
      'notes',
      where: 'notebook = ? AND is_deleted = 0',
      whereArgs: [notebook],
    );

    // 遍历笔记，查询对应标签
    final notes = <Note>[];
    for (final noteMap in notesMaps) {
      final noteId = noteMap['id'] as int;
      final tagMaps = await db.rawQuery(
        '''
      SELECT t.name FROM tags t
      JOIN note_tags nt ON t.id = nt.tag_id
      WHERE nt.note_id = ?
    ''',
        [noteId],
      );

      final tags = tagMaps.map((e) => e['name'] as String).toList();

      notes.add(Note.fromMap(noteMap).copyWith(tags: tags));
    }
    return notes;
  }

  /// 应用启动时初始化数据，确保默认笔记本和默认欢迎笔记存在
  Future<void> initializeAppData() async {
    final repo = NoteRepository();

    // 确认“工作”笔记本中是否有欢迎笔记
    final hasWelcomeNote = await repo.hasWelcomeNoteInWork();

    if (!hasWelcomeNote) {
      final now = DateTime.now();
      const welcomeContent = '''
欢迎使用
灵光一现 · Flash Memo

Everything Begins with an Idea.
一切从灵感开始。
And Ideas can Change the World.
灵感改变世界。

Everything Begins with an Idea.
一切从灵感开始。
And Ideas can Change the World.
灵感改变世界。
''';
      await repo.insertNote(
        Note(
          notebook: '工作',
          title: '欢迎使用',
          content: welcomeContent,
          tags: <String>[],
          color: '',
          isDeleted: false,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
  }

  Future hasWelcomeNoteInWork() async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'notes',
      where: 'notebook = ? AND title = ?',
      whereArgs: ['工作', '欢迎使用'],
      limit: 1,
    );
    return result.isNotEmpty;
  }
}
