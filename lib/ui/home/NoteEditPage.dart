import 'package:flash_memo/common/constants.dart';
import 'package:flash_memo/data/note_models.dart';
import 'package:flash_memo/data/note_repository.dart';
import 'package:flash_memo/ui/Base/EasonBasePage.dart';
import 'package:flash_memo/utils/EasonAppBar.dart';
import 'package:flutter/material.dart';
import 'package:flash_memo/ui/home/TagEditPage.dart';
import 'package:intl/intl.dart';

class NoteEditPage extends EasonBasePage {
  static final GlobalKey<_NoteEditPageState> globalKey =
      GlobalKey<_NoteEditPageState>();
  // 可选参数，传入已有笔记进行编辑
  // 如果是新建笔记则为 null
  final Note? note;
  NoteEditPage({Key? key, this.note}) : super(key: key ?? globalKey);

  @override
  String get title => note == null ? '新建笔记' : '编辑笔记'; // 标题

  @override
  State<NoteEditPage> createState() => _NoteEditPageState();

  @override
  List<EasonMenuItem>? menuItems(BuildContext context) {
    final items = super.menuItems(context) ?? <EasonMenuItem>[];
    items.insert(
      0,
      EasonMenuItem(
        title: '保存',
        icon: Icons.save,
        iconColor: Colors.green,
        onTap: () {
          final state = NoteEditPage.globalKey.currentState;
          if (state != null) {
            state.saveNote(); // 改为公开方法
          } else {
            debugPrint('状态未准备好，无法保存');
          }
        },
      ),
    );
    return items;
  }
}

class _NoteEditPageState extends BasePageState<NoteEditPage> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  List<String> _tags = [];
  String _color = '#2196F3'; // 默认蓝色

  // 赤橙黄绿青蓝紫
  final List<String> _colorOptions = [
    '#FF4500', // 赤 - OrangeRed
    '#FFA500', // 橙 - Orange
    '#FFFF00', // 黄 - Yellow
    '#008000', // 绿 - Green
    '#00CED1', // 青 - DarkTurquoise
    '#0000FF', // 蓝 - Blue
    '#800080', // 紫 - Purple
  ];

  bool get isEditing => widget.note != null;

  @override
  void initState() {
    super.initState();
    // 如果是编辑模式，初始化已有笔记数据
    if (isEditing) {
      _initEditData();
    } else {
      _titleController = TextEditingController();
      _contentController = TextEditingController();
    }
  }

  void _initEditData() {
    // 初始化编辑模式下的笔记数据
    _selectedNotebook = widget.note?.notebook ?? '工作';
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(
      text: widget.note?.content ?? '',
    );
    _tags = widget.note?.tags.toList() ?? [];
    _color = widget.note?.color ?? _color;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void saveNote() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('标题不能为空')));
      return;
    }

    // 这里封装 Note 对象，可调用你的数据库保存逻辑
    final newNote = Note(
      id: widget.note?.id,
      notebook: _selectedNotebook,
      title: title,
      content: content,
      tags: _tags,
      color: _color,
      isDeleted: false,
      createdAt: widget.note?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    //  调用仓库保存newNote，保存成功后返回上一页
    // 这里可以调用 NoteRepository 的方法保存笔记
    // 调用仓库保存newNote，保存成功后返回上一页
    NoteRepository().saveNote(newNote);
    debugPrint('保存笔记：$newNote');

    Navigator.of(context).pop(newNote);
  }

  Future<void> _refreshTags() async {
    if (widget.note?.id == null) return; // 如果没有笔记ID，直接返回
    List<String> tags = await NoteRepository().getTagsByNoteId(
      widget.note!.id!,
    );
    setState(() {
      _tags = tags;
    });
  }

  Widget _buildTagEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _tags.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final tag = _tags[index];
              return Chip(
                label: Text(tag),
                onDeleted: () {
                  setState(() {
                    _tags.removeAt(index);
                  });
                },
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final result = await Navigator.push<bool>(
              context,
              MaterialPageRoute(
                builder: (_) => TagEditPage(note: widget.note!),
              ),
            );
            if (result == true) {
              // 调用刷新标签方法，比如重新拉取标签显示
              _refreshTags();
            }
          },
          child: Chip(
            label: const Text('编辑标签'),
            avatar: const Icon(Icons.edit, size: 18),
          ),
        ),
      ],
    );
  }

  Future<String?> _showAddTagDialog() async {
    String? input;
    return showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('添加标签'),
          contentPadding: EdgeInsets.zero,
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            child: SingleChildScrollView(
              // shrinkWrap: true,  // Removed as per instruction
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Default tags as selectable chips
                  if (kDefaultTags.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          ...kDefaultTags.map(
                            (tag) => ChoiceChip(
                              label: Text(tag),
                              selected: false,
                              onSelected: (_) {
                                Navigator.of(context).pop(tag);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (kDefaultTags.isNotEmpty) const Divider(),
                  // TextField for custom tag
                  TextField(
                    autofocus:
                        false, // Changed from true to false as per instruction
                    decoration: const InputDecoration(hintText: '输入标签名'),
                    onChanged: (value) => input = value.trim(),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(input),
              child: const Text('确定'),
            ),
          ],
        );
      },
    );
  }

  late String _selectedNotebook; // 默认笔记本
  // 笔记本选择器
  Widget _buildNotebookSelector() {
    return Row(
      children: [
        const Text('笔记本：', style: TextStyle(fontSize: 16)),
        const SizedBox(width: 5),
        DropdownButton<String>(
          value: _selectedNotebook,
          items: kDefaultNotebooks.map((notebook) {
            return DropdownMenuItem<String>(
              value: notebook,
              child: Text(notebook),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedNotebook = value;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildColorSelector() {
    return Wrap(
      spacing: 6,
      children: _colorOptions.map((colorHex) {
        final isSelected = colorHex == _color;
        final color = Color(
          int.parse('FF${colorHex.replaceFirst('#', '')}', radix: 16),
        );
        return GestureDetector(
          onTap: () => setState(() => _color = colorHex),
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: Colors.black, width: 2)
                  : null,
              boxShadow: isSelected
                  ? [BoxShadow(color: Colors.black26, blurRadius: 4)]
                  : null,
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget buildContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _buildNotebookSelector()),
              const SizedBox(width: 10),
              Expanded(child: _buildColorSelector()),
            ],
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '创建时间: ${widget.note?.createdAt != null ? DateFormat('yyyy-MM-dd HH:mm').format(widget.note!.createdAt!) : '-'}',
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
                Expanded(
                  child: Text(
                    '更新时间: ${widget.note?.updatedAt != null ? DateFormat('yyyy-MM-dd HH:mm').format(widget.note!.updatedAt!) : '-'}',
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: '标题',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
            ),
            maxLines: 1,
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: TextField(
              controller: _contentController,
              decoration: InputDecoration(
                labelText: '内容',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
              maxLines: null,
              expands: true,
              keyboardType: TextInputType.multiline,
              textAlignVertical: TextAlignVertical.top,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '标签',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildTagEditor(),
        ],
      ),
    );
  }
}
