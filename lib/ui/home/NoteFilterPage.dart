import 'package:flash_memo/data/note_models.dart';
import 'package:flash_memo/data/note_repository.dart';
import 'package:flash_memo/ui/Base/EasonBasePage.dart';
import 'package:flash_memo/ui/Base/empty_view.dart';
import 'package:flash_memo/ui/home/NoteEditPage.dart';
import 'package:flash_memo/ui/home/NoteListPage.dart';
import 'package:flash_memo/ui/home/TagEditPage.dart';
import 'package:flash_memo/utils/EasonAppBar.dart';
import 'package:flash_memo/utils/EasonDialog.dart';
import 'package:flash_memo/utils/EasonMessenger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

class NoteFilterPage extends EasonBasePage {
  static final GlobalKey<_NoteFilterPageState> globalKey =
      GlobalKey<_NoteFilterPageState>();
  List<Note>? notes; // 笔记数组 可选参数
  String? notebook; // 笔记本 可选参数
  NoteFilterPage({Key? key, this.notes, this.notebook})
    : super(key: key ?? globalKey);

  @override
  String get title => 'Note筛选';

  @override
  State<NoteFilterPage> createState() => _NoteFilterPageState();

  @override
  List<EasonMenuItem>? menuItems(BuildContext context) {
    final items = super.menuItems(context) ?? <EasonMenuItem>[];
    // 编辑和删除操作
    // 添加编辑和删除按钮
    items.insertAll(0, [
      EasonMenuItem(
        title: '编辑',
        icon: Icons.edit,
        iconColor: Colors.blue,
        onTap: () {
          // 切换编辑状态
          final state = context.findAncestorStateOfType<_NoteFilterPageState>();
          state?._toggleEdit();
          // 进入编辑页
          Navigator.pushNamed(
            context,
            '/create_note',
            arguments: notes != null && notes!.isNotEmpty ? notes!.first : null,
          );
        },
      ),
      EasonMenuItem(
        title: '删除',
        icon: Icons.delete,
        iconColor: Colors.red,
        onTap: () {
          // 删除笔记
          if (notes != null && notes!.isNotEmpty && notes!.first.id != null) {
            NoteRepository().deleteNote(notes!.first.id!);
            // 返回上一页 并刷新页面
            Navigator.pop(context, true);
          } else {
            // 处理 id 为空的情况，比如日志或提示
            debugPrint('警告：尝试删除的笔记 ID 为 null');
          }
        },
      ),
    ]);
    return items;
  }
}

class _NoteFilterPageState extends BasePageState<NoteFilterPage> {
  String? _selectedTag;
  Color? _selectedColor;
  String? _selectedType;
  List<String> _availableTags = [];
  List<Color> _availableColors = [];
  List<String> _availableTypes = [];

  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool _isEditing = false;

  bool _isBatchDeleteMode = false; // 是否处于批量删除模式
  Set<int> _selectedNoteIds = {}; // 选中的笔记ID集合

  List<Note> _allNotes = [];
  List<Note> _filteredNotes = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(
      text: widget.notes != null && widget.notes!.isNotEmpty
          ? widget.notes!.first.title
          : '',
    );
    _contentController = TextEditingController(
      text: widget.notes != null && widget.notes!.isNotEmpty
          ? widget.notes!.first.content
          : '',
    );
    _fetchNotes(fromRepo: widget.notes == null);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  // 加载和筛选方法
  Future<void> _fetchNotes({bool fromRepo = false}) async {
    List<Note> notes = [];
    var tagsMap = {};
    if (fromRepo || widget.notes == null) {
      try {
        notes = await NoteRepository().fetchNotesByNotebook(
          widget.notebook ?? '所有笔记',
        );
        // 查询所有 tags
        final noteIds = notes.map((n) => n.id!).toList();
        tagsMap = await NoteRepository().getTagsForNotes(noteIds);
        for (var note in notes) {
          note.tags = tagsMap[note.id] ?? [];
        }
        debugPrint('加载了 $tagsMap  标签');
      } catch (e) {
        debugPrint('加载笔记失败: $e');
      }
    } else {
      notes = List<Note>.from(widget.notes!);
      // 查询所有 tags
      final noteIds = notes.map((n) => n.id!).toList();
      tagsMap = await NoteRepository().getTagsForNotes(noteIds);
      for (var note in notes) {
        note.tags = tagsMap[note.id] ?? [];
      }
      debugPrint('加载了 $tagsMap  标签');
    }
    _allNotes = notes;
    _filteredNotes = List<Note>.from(_allNotes);
    // 设置可用筛选项
    final notebookNotes = _allNotes
        .where((n) => widget.notebook == null || n.notebook == widget.notebook)
        .toList();
    _availableTags = tagsMap.values
        .expand((list) => List<String>.from(list))
        .toSet()
        .toList();
    _availableTags.insert(0, '所有标签');
    _availableColors = notes
        .map((n) {
          final colorStr = (n.color ?? '').trim();
          debugPrint('颜色:$colorStr');
          if (colorStr.isEmpty) return null;
          try {
            return Color(
              int.parse('FF${colorStr.replaceFirst('#', '')}', radix: 16),
            );
          } catch (_) {
            return null;
          }
        })
        .whereType<Color>() // 去掉 null
        .toSet()
        .toList();
    _availableColors.insert(0, Colors.black);
    _availableTypes = _allNotes
        .map((n) => n.notebook)
        .where((t) => t != null && t.isNotEmpty)
        .toSet()
        .toList();
    _availableTypes.insert(0, '所有笔记');
    debugPrint(
      '可用标签:$_availableTags 可用颜色:$_availableColors 可用笔记本:$_availableTypes',
    );
    setState(() {});
  }

  // 筛选方法
  Future<void> filterNotes() async {
    setState(() {
      // 根据选中的标签、颜色和笔记本进行筛选
      // 如果是所有笔记
      if (_selectedType == '所有笔记') {
        _selectedType = null;
      }
      if (_selectedTag == '所有标签') {
        _selectedTag = null;
      }

      if (_selectedColor == Colors.black) {
        _selectedColor = null;
      }
      _filteredNotes = _allNotes
          .where(
            (n) =>
                (_selectedTag == null || n.tags.contains(_selectedTag)) &&
                (_selectedColor == null ||
                    (() {
                      try {
                        return Color(
                              int.parse(
                                'FF${(n.color ?? '#2196F3').replaceFirst('#', '')}',
                                radix: 16,
                              ),
                            ) ==
                            _selectedColor;
                      } catch (_) {
                        return Colors.blue == _selectedColor;
                      }
                    })()) &&
                (_selectedType == null || n.notebook == _selectedType),
          )
          .toList();
      _isEditing = false;
    });
  }

  Widget _buildFilterBar() {
    const textStyle = TextStyle(
      inherit: false,
      fontSize: 12,
      fontFamily: 'Montserrat',
      color: Colors.white,
      fontWeight: FontWeight.w600,
    );
    final borderRadius = BorderRadius.circular(16);
    var count = 3;
    if (widget.notebook == '所有笔记') {
      count = 4;
    }
    final gradient = LinearGradient(
      colors: [
        const Color.fromARGB(255, 151, 207, 235),
        const Color.fromARGB(255, 177, 255, 68),
      ],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      stops: const [0.4, 0.9],
    );
    final totalSpacing = (count + 1) * 5;
    final btnWidth = (MediaQuery.of(context).size.width - totalSpacing) / count;
    final sizeIcon = 16.0;
    final dropdownMaxHeight = 250.0;
    final downOffset = Offset(0, 4);
    final dropdownDecoration = BoxDecoration(
      gradient: gradient,
      borderRadius: borderRadius,
      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
    );
    // Tag DropdownButton2
    Widget tagDropdown = Center(
      child: DropdownButtonHideUnderline(
        child: DropdownButton2<String>(
          value: _selectedTag,
          hint: Center(
            child: Text(
              '选择标签',
              style: textStyle.copyWith(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ),
          iconStyleData: IconStyleData(
            icon: Icon(
              Icons.keyboard_arrow_down,
              color: Colors.white,
              size: sizeIcon,
            ),
          ),
          style: textStyle,
          isExpanded: true,
          buttonStyleData: ButtonStyleData(
            height: 40,
            width: btnWidth,
            decoration: dropdownDecoration,
            padding: EdgeInsets.zero,
          ),
          dropdownStyleData: DropdownStyleData(
            maxHeight: dropdownMaxHeight,
            decoration: dropdownDecoration,
            elevation: 2,
            offset: downOffset,
          ),
          menuItemStyleData: MenuItemStyleData(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: _availableTags.map((tag) {
            return DropdownMenuItem<String>(
              value: tag,
              child: Center(child: Text(tag, style: textStyle)),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedTag = value;
            });
          },
        ),
      ),
    );

    // Color DropdownButton2
    Widget colorDropdown = Center(
      child: DropdownButtonHideUnderline(
        child: DropdownButton2<Color>(
          value: _selectedColor,
          hint: Center(child: Text('选择颜色', style: textStyle)),
          iconStyleData: IconStyleData(
            icon: Icon(
              Icons.keyboard_arrow_down,
              color: Colors.white,
              size: sizeIcon,
            ),
          ),
          style: textStyle,
          isExpanded: true,
          buttonStyleData: ButtonStyleData(
            height: 40,
            width: btnWidth,
            decoration: dropdownDecoration,
            padding: EdgeInsets.zero,
          ),
          dropdownStyleData: DropdownStyleData(
            maxHeight: dropdownMaxHeight,
            decoration: dropdownDecoration,
            elevation: 2,
            offset: downOffset,
          ),
          menuItemStyleData: MenuItemStyleData(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: _availableColors.map((color) {
            return DropdownMenuItem<Color>(
              value: color,
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey.shade300, width: 1),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedColor = value;
            });
          },
        ),
      ),
    );

    // Type DropdownButton2 (if needed)
    Widget? typeDropdown;
    if (widget.notebook == '所有笔记') {
      typeDropdown = Center(
        child: DropdownButtonHideUnderline(
          child: DropdownButton2<String>(
            value: _selectedType,
            hint: Center(child: Text('选择类型', style: textStyle)),
            iconStyleData: IconStyleData(
              icon: Icon(
                Icons.keyboard_arrow_down,
                color: Colors.white,
                size: sizeIcon,
              ),
            ),
            style: textStyle,
            isExpanded: true,
            buttonStyleData: ButtonStyleData(
              height: 40,
              width: btnWidth,
              decoration: dropdownDecoration,
              padding: EdgeInsets.zero,
            ),
            dropdownStyleData: DropdownStyleData(
              maxHeight: dropdownMaxHeight,
              decoration: dropdownDecoration,
              elevation: 2,
              offset: downOffset,
            ),
            menuItemStyleData: MenuItemStyleData(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: _availableTypes.map((type) {
              return DropdownMenuItem<String>(
                value: type,
                child: Center(child: Text(type, style: textStyle)),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedType = value;
              });
            },
          ),
        ),
      );
    }
    final height = 40.0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        SizedBox(
          width: btnWidth,
          height: height,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: tagDropdown,
          ),
        ),
        SizedBox(
          width: btnWidth,
          height: height,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2.0),
            child: colorDropdown,
          ),
        ),
        if (typeDropdown != null)
          SizedBox(
            width: btnWidth,
            height: height,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2.0),
              child: typeDropdown,
            ),
          ),
        SizedBox(
          width: btnWidth,
          height: height,
          child: Padding(
            padding: const EdgeInsets.only(left: 2.0, right: 0.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(
                  inherit: false, // 保持一致
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                debugPrint(
                  '确认筛选: tag=$_selectedTag, color=$_selectedColor, type=$_selectedType',
                );
                filterNotes();
              },
              child: Ink(
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  alignment: Alignment.center,
                  constraints: BoxConstraints(minHeight: 40),
                  child: const Text(
                    '确认',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTags() {
    final note = _filteredNotes.isNotEmpty ? _filteredNotes.first : null;
    if (note == null || note.tags == null || note.tags!.isEmpty) {
      return const SizedBox.shrink();
    }

    Color baseColor;
    try {
      final colorStr = note.color ?? '#2196F3'; // fallback color blue
      baseColor = Color(
        int.parse('FF${colorStr.replaceFirst('#', '')}', radix: 16),
      );
    } catch (_) {
      baseColor = Colors.blue;
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: note.tags!.map((tag) {
        return Chip(
          label: Text(tag, style: const TextStyle(color: Colors.white)),
          backgroundColor: baseColor.withOpacity(0.7),
          shadowColor: baseColor.withOpacity(0.5),
          elevation: 2,
        );
      }).toList(),
    );
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

  @override
  Widget buildContent(BuildContext context) {
    // 没有笔记时显示空视图，并提供“新建笔记”入口
    if (_filteredNotes.isEmpty) {
      return EmptyView(
        title: '暂无笔记',
        subtitle: '赶快重置筛选条件吧！',
        icon: Icons.note_alt_outlined,
        onTap: () async {
          _selectedTag = null;
          _selectedColor = null;
          _selectedType = null;
          _selectedNoteIds.clear();
          await _fetchNotes(fromRepo: true);
          setState(() {});
        },
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: _buildFilterBar(), // 这里加入筛选栏
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _fetchNotes(fromRepo: true),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredNotes.length,
              separatorBuilder: (context, index) => const SizedBox(height: 5),
              itemBuilder: (context, index) {
                final note = _filteredNotes[index];
                return _isBatchDeleteMode
                    ? _buildNoteCardWithCheckbox(note)
                    : _buildNoteCard(note);
              },
            ),
          ),
        ),
      ],
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
          if (widget.notebook != '回收站')
            SlidableAction(
              onPressed: (context) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => TagEditPage(note: note)),
                ).then((shouldRefresh) {
                  if (shouldRefresh == true) {
                    _fetchNotes(fromRepo: true);
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
                  setState(() {
                    _allNotes.removeWhere((n) => n.id == note.id);
                    _filteredNotes.removeWhere((n) => n.id == note.id);
                  });

                  final scaffoldContext = NoteListPage.globalKey.currentContext;
                  if (scaffoldContext != null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      EasonMessenger.showSuccess(
                        scaffoldContext,
                        message: '笔记已删除',
                        onComplete: () async {
                          if (!mounted) return;
                          await _fetchNotes(fromRepo: true);
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
            await _fetchNotes(fromRepo: true);
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
                    children: tags
                        .map(
                          (tag) => Chip(
                            label: Text(
                              tag,
                              style: const TextStyle(color: Colors.white),
                            ),
                            backgroundColor: color.withOpacity(0.7),
                            shadowColor: color.withOpacity(0.5),
                            elevation: 2,
                          ),
                        )
                        .toList(),
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
