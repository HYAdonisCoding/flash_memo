import 'package:flash_memo/data/note_models.dart';
import 'package:flash_memo/data/note_repository.dart';
import 'package:flash_memo/ui/Base/EasonBasePage.dart';
import 'package:flash_memo/ui/Base/empty_view.dart';
import 'package:flash_memo/ui/home/NoteDetailPage.dart';
import 'package:flash_memo/utils/EasonAppBar.dart';
import 'package:flutter/material.dart';

/// 笔记列表页面，显示某个笔记本分类下的所有笔记
class NoteListPage extends EasonBasePage {
  static final GlobalKey<_NoteListPageState> globalKey =
      GlobalKey<_NoteListPageState>();
  final NoteCategory notebook; // 当前笔记本分类对象

  /// 构造函数，传入笔记本分类
  NoteListPage({Key? key, required this.notebook})
    : super(key: key ?? globalKey);

  @override
  String get title => notebook.title; // 页面标题显示当前笔记本名称

  @override
  State<NoteListPage> createState() => _NoteListPageState();
  @override
  List<EasonMenuItem>? menuItems(BuildContext context) {
    final items = super.menuItems(context) ?? <EasonMenuItem>[];
    // 批量删除笔记
    items.add(
      EasonMenuItem(
        title: '批量删除',
        icon: Icons.delete_sweep,
        iconColor: Colors.red,
        onTap: () {
          // 弹出批量删除对话框

          // 如果用户确认删除，执行删除操作
          // ...
        },
      ),
    );

    // 添加“新建笔记”按钮
    if (notebook.title == '回收站') {
      // 如果是回收站，不显示新建笔记按钮
      return items;
    }
    items.add(
      EasonMenuItem(
        title: '新建笔记',
        icon: Icons.note_add,
        iconColor: Colors.green,
        onTap: () {
          Navigator.pushNamed(context, '/create_note', arguments: null).then((
            shouldRefresh,
          ) {
            if (shouldRefresh == true) {
              // 如果新建笔记后需要刷新列表
              final state = NoteListPage.globalKey.currentState;
              if (state != null) {
                state._loadNotes(); // 改为公开方法
              } else {
                debugPrint('状态未准备好，无法保存');
              }
            }
          });
        },
      ),
    );
    return items;
  }
}

/// 页面状态类，负责加载和展示笔记列表
class _NoteListPageState extends BasePageState<NoteListPage> {
  List<Note> _notes = []; // 笔记列表数据
  bool _loading = true; // 是否正在加载数据

  @override
  void initState() {
    super.initState();
    _loadNotes(); // 页面初始化时加载笔记
  }

  /// 从数据库异步获取指定笔记本的笔记列表
  Future<void> _loadNotes() async {
    final notes = await fetchNotesByNotebook(widget.notebook.title);
    setState(() {
      _notes = notes; // 更新笔记数据
      _loading = false; // 结束加载状态
    });
  }

  /// 调用仓库方法，获取指定笔记本名称的笔记列表
  Future<List<Note>> fetchNotesByNotebook(String notebook) async {
    // 如果是所有笔记
    if (notebook == '所有笔记') {
      final repo = NoteRepository();
      final notes = await repo.getAllNotes();
      return notes;
    } else if (notebook == '回收站') {
      final repo = NoteRepository();
      final notes = await repo.getDeletedNotes();
      return notes;
    }
    final repo = NoteRepository();
    final notes = await repo.getNotesByNotebookName(notebook);
    return notes;
  }

  @override
  Widget buildContent(BuildContext context) {
    // 加载中显示圆形进度指示器
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    // 没有笔记时显示空视图，并提供“新建笔记”入口
    if (_notes.isEmpty) {
      return EmptyView(
        title: '暂无笔记',
        subtitle: '你还没有创建任何笔记，赶快开始吧！',
        icon: Icons.note_alt_outlined,
        onTap: () async {
          final shouldRefresh = await Navigator.pushNamed(
            context,
            '/create_note',
          );
          if (shouldRefresh == true) {
            _loadNotes(); // 新建笔记后刷新列表
          }
        },
      );
    }

    // 有笔记时显示笔记列表，支持滑动删除
    return RefreshIndicator(
      onRefresh: _loadNotes,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _notes.length,
        separatorBuilder: (context, index) => const SizedBox(height: 16),
        itemBuilder: (context, index) {
          final note = _notes[index];
          return Dismissible(
            key: Key(note.id.toString()), // 唯一Key，确保列表项可识别
            direction: DismissDirection.endToStart, // 只允许向左滑动删除
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.redAccent, Colors.red],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
              child: const Icon(Icons.delete, color: Colors.white, size: 28),
            ),
            onDismissed: (direction) async {
              final deletedNote = _notes[index];
              setState(() {
                _notes.removeAt(index); // 删除UI列表项
              });
              final repo = NoteRepository();
              await repo.deleteNoteById(deletedNote.id!); // 数据库软删除笔记

              // 显示SnackBar，支持撤销删除操作
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('笔记已删除'),
                  action: SnackBarAction(
                    label: '撤销',
                    onPressed: () async {
                      final repo = NoteRepository();
                      await repo.insertNote(deletedNote); // 重新插入笔记
                      setState(() {
                        _notes.insert(index, deletedNote); // 恢复UI列表
                      });
                    },
                  ),
                ),
              );
            },
            child: _buildNoteCard(note), // 构建单条笔记卡片
          );
        },
      ),
    );
  }

  /// 构建单个笔记卡片的UI
  Widget _buildNoteCard(Note note) {
    Color color;
    try {
      color = Color(
        int.parse('FF${note.color.replaceFirst('#', '')}', radix: 16),
      );
    } catch (_) {
      color = Colors.blueAccent;
    }

    final tags = note.tags;

    return InkWell(
      onTap: () async {
        final shouldRefresh = await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => NoteDetailPage(note: note)),
        );
        if (shouldRefresh == true) {
          _loadNotes();
        }
      },
      borderRadius: BorderRadius.circular(20),
      splashColor: color.withOpacity(0.3),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
        shadowColor: color.withOpacity(0.4),
        child: Container(
          width: double.infinity, // 关键：让卡片宽度撑满
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.5), color.withOpacity(0.85)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                note.title,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      blurRadius: 3,
                      color: Colors.black26,
                      offset: Offset(1, 1),
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
