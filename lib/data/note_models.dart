class NoteCategory {
  final String title;
  final int noteCount;
  final int totalWords;
  DateTime lastUpdated;

  NoteCategory({
    required this.title,
    required this.noteCount,
    required this.totalWords,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();
}

class Note {
  int? id;
  String notebook;
  String title;
  String content;
  List<String> tags; // 标签列表
  String color; // 颜色字符串，例如 "#FF0000"
  bool isDeleted;
  DateTime createdAt;
  DateTime updatedAt;

  Note({
    this.id,
    required this.notebook,
    required this.title,
    required this.content,
    this.tags = const [],
    this.color = '',
    this.isDeleted = false,
    required this.createdAt,
    required this.updatedAt,
  });
  // 添加copyWith方法
  Note copyWith({
    int? id,
    String? notebook,
    String? title,
    String? content,
    List<String>? tags,
    String? color,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Note(
      id: id ?? this.id,
      notebook: notebook ?? this.notebook,
      title: title ?? this.title,
      content: content ?? this.content,
      tags: tags ?? this.tags,
      color: color ?? this.color,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as int?,
      notebook: map['notebook'] as String,
      title: map['title'] as String? ?? '',
      content: map['content'] as String? ?? '',
      tags: (map['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      color: map['color'] as String? ?? '',
      isDeleted: (map['is_deleted'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'notebook': notebook,
      'title': title,
      'content': content,
      'tags': tags,
      'color': color,
      'is_deleted': isDeleted ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
