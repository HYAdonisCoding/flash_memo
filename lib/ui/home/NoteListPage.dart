import 'package:flash_memo/data/note_models.dart';
import 'package:flash_memo/data/note_repository.dart';
import 'package:flash_memo/ui/Base/EasonBasePage.dart';
import 'package:flash_memo/ui/Base/empty_view.dart';
import 'package:flash_memo/ui/home/NoteEditPage.dart';
import 'package:flash_memo/ui/home/TagEditPage.dart';
import 'package:flash_memo/utils/EasonAppBar.dart';
import 'package:flash_memo/utils/EasonDialog.dart';
import 'package:flash_memo/utils/EasonMessenger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

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
    // 增加筛选
    items.insert(
      0,
      EasonMenuItem(
        title: '筛选',
        icon: Icons.filter_list,
        iconColor: Colors.blue,
        onTap: () {
          // 进入筛选页
          final state = NoteListPage.globalKey.currentState;
          final myNotesList = state?._notes;
          final arguments = {'notes': myNotesList, 'notebook': notebook.title};
          debugPrint('arguments: $arguments');
          Navigator.pushNamed(context, '/note_filter', arguments: arguments);
        },
      ),
    );
    // 批量删除笔记
    items.insert(
      0,
      EasonMenuItem(
        title: '批量删除',
        icon: Icons.delete_sweep,
        iconColor: Colors.red,
        onTap: () {
          // 弹出批量删除对话框

          // 如果用户确认删除，执行删除操作
          final state = NoteListPage.globalKey.currentState;
          state?._enterBatchDeleteMode();
        },
      ),
    );

    // 添加“新建笔记”按钮
    if (notebook.title == '回收站') {
      // 如果是回收站，不显示新建笔记按钮
      return items;
    }
    items.insert(
      0,
      EasonMenuItem(
        title: '新建笔记',
        icon: Icons.note_add,
        iconColor: Colors.green,
        onTap: () {
          // 传入当前的类型
          Navigator.pushNamed(
            context,
            '/create_note',
            arguments: notebook.title, // 传当前笔记本名称
          ).then((shouldRefresh) {
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

  bool _isBatchDeleteMode = false; // 是否处于批量删除模式
  Set<int> _selectedNoteIds = {}; // 选中的笔记ID集合

  @override
  void initState() {
    super.initState();
    _loadNotes(); // 页面初始化时加载笔记
  }

  /// 从数据库异步获取指定笔记本的笔记列表
  Future<void> _loadNotes() async {
    try {
      final notes = await NoteRepository().fetchNotesByNotebook(widget.notebook.title);

      // 一次性查出所有 tags
      final noteIds = notes.map((n) => n.id!).toList();
      final tagsMap = await NoteRepository().getTagsForNotes(noteIds);

      for (var note in notes) {
        note.tags = tagsMap[note.id] ?? [];
      }
      if (!mounted) return;
      setState(() {
        _notes = notes;
        _loading = false;
        if (_isBatchDeleteMode) {
          _selectedNoteIds.clear();
        }
      });
    } catch (e) {
      debugPrint('加载笔记失败: $e');
    }
  }

  

  void _enterBatchDeleteMode() {
    setState(() {
      _isBatchDeleteMode = true;
      _selectedNoteIds.clear();
    });
  }

  void _exitBatchDeleteMode() {
    setState(() {
      _isBatchDeleteMode = false;
      _selectedNoteIds.clear();
    });
  }

  Future<void> _batchDeleteSelectedNotes() async {
    if (_selectedNoteIds.isEmpty) {
      return;
    }
    int count = _selectedNoteIds.length;
    final confirmed = await showCustomConfirmDialog(
      context,
      '确定要删除选中的$count条笔记吗？',
    );
    if (confirmed == true) {
      final repo = NoteRepository();
      final isRecycleBin = widget.notebook.title == '回收站';

      for (var id in _selectedNoteIds) {
        if (isRecycleBin) {
          await repo.hardDeleteNoteById(id); // 回收站，硬删除
        } else {
          await repo.deleteNoteById(id); // 非回收站，软删除
        }
      }

      _exitBatchDeleteMode();

      if (!mounted) return;
      EasonMessenger.showSuccess(
        context,
        message: '成功删除$count条笔记',
        onComplete: () async {
          if (!mounted) return;
          await _loadNotes();
        },
      );
    }
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

    Widget listView = RefreshIndicator(
      onRefresh: _loadNotes,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _notes.length,
        separatorBuilder: (context, index) => const SizedBox(height: 5),
        itemBuilder: (context, index) {
          final note = _notes[index];
          return _isBatchDeleteMode
              ? _buildNoteCardWithCheckbox(note)
              : Dismissible(
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
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                      size: 28,
                    ),
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

    if (_isBatchDeleteMode) {
      return Stack(
        children: [
          Positioned.fill(child: listView),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBatchDeleteBar(),
          ),
        ],
      );
    } else {
      return listView;
    }
  }

  Widget _buildNoteCardWithCheckbox(Note note) {
    Color color;
    try {
      color = Color(
        int.parse('FF${note.color.replaceFirst('#', '')}', radix: 16),
      );
    } catch (_) {
      color = Colors.blueAccent;
    }

    final tags = note.tags;
    final isSelected = _selectedNoteIds.contains(note.id);

    return InkWell(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedNoteIds.remove(note.id);
          } else {
            _selectedNoteIds.add(note.id!);
          }
        });
      },
      borderRadius: BorderRadius.circular(20),
      splashColor: color.withOpacity(0.3),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 8,
        shadowColor: color.withOpacity(0.4),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [color.withOpacity(0.5), color.withOpacity(0.85)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Row(
            children: [
              Checkbox(
                value: isSelected,
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      _selectedNoteIds.add(note.id!);
                    } else {
                      _selectedNoteIds.remove(note.id);
                    }
                  });
                },
                activeColor: Colors.white,
                checkColor: color,
              ),
              Expanded(
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBatchDeleteBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      height: 56,
      decoration: BoxDecoration(
        color: Colors.grey.shade900.withOpacity(0.9),
        boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 8)],
      ),
      child: Row(
        children: [
          Text(
            '已选择 ${_selectedNoteIds.length} 条',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          const Spacer(),
          TextButton(
            onPressed: _exitBatchDeleteMode,
            child: const Text('取消', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: _selectedNoteIds.isEmpty
                ? null
                : _batchDeleteSelectedNotes,
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  Widget buildTag(String tag, Color cardColor) {
    final brightness = ThemeData.estimateBrightnessForColor(cardColor);
    final isLight = brightness == Brightness.light;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isLight
            ? Colors.black.withOpacity(0.25)
            : Colors.white.withOpacity(0.25),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        tag,
        style: TextStyle(
          color: isLight ? Colors.white : Colors.black87,
          fontSize: 14,
          shadows: isLight
              ? [
                  Shadow(
                    offset: Offset(0.5, 0.5),
                    blurRadius: 1,
                    color: Colors.black38,
                  ),
                ]
              : null,
        ),
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

    return Slidable(
      key: Key(note.id.toString()),

      // 定义右侧滑动按钮组
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        children: [
          // 只有当笔记本不是“回收站”时才显示“标签”按钮
          // 只有回收站以外才显示标签按钮
          if (widget.notebook.title != '回收站')
            SlidableAction(
              onPressed: (context) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => TagEditPage(note: note)),
                ).then((shouldRefresh) {
                  if (shouldRefresh == true) {
                    final state = NoteListPage.globalKey.currentState;
                    state?._loadNotes();
                  }
                });
              },
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              icon: Icons.label,
              label: '标签',
              flex: 1, // 让标签按钮宽度灵活
            ),
          SlidableAction(
            onPressed: (context) async {
              // 点击删除按钮，弹出确认对话框
              String msg = '确定要删除这条笔记吗？';
              if (note.isDeleted) {
                //
                msg = '确定要彻底删除这条笔记吗？';
              }
              showConfirmDialogWithCallback(
                context,
                msg,
                onConfirm: () async {
                  final repo = NoteRepository();
                  if (note.isDeleted) {
                    await repo.hardDeleteNoteById(note.id!);
                  } else {
                    await repo.deleteNoteById(note.id!);
                  }

                  final state = NoteListPage.globalKey.currentState;
                  state?.setState(() {
                    state._notes.removeWhere((n) => n.id == note.id);
                  });

                  final scaffoldContext = NoteListPage.globalKey.currentContext;
                  if (scaffoldContext != null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      EasonMessenger.showSuccess(
                        scaffoldContext,
                        message: '笔记已删除',
                        onComplete: () async {
                          if (!mounted) return;
                          await _loadNotes();
                        },
                      );
                    });
                  }
                },
              );
            },
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: '删除',
            flex: 1, // 限制宽度为1份，避免撑满
          ),
        ],
      ),

      child: InkWell(
        onTap: () async {
          final shouldRefresh = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => NoteEditPage(note: note)),
          );
          if (shouldRefresh == true) {
            _loadNotes();
          }
        },
        borderRadius: BorderRadius.circular(20),
        splashColor: color.withOpacity(0.3),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 8,
          shadowColor: color.withOpacity(0.3),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [color.withOpacity(0.5), color.withOpacity(0.718)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note.title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 2,
                        color: Colors.black26,
                        offset: Offset(1, 1),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6, // 减小横向间距
                    runSpacing: 6, // 减小换行间距
                    children: tags.map((tag) => buildTag(tag, color)).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
