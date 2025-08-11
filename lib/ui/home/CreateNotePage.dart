import 'package:flash_memo/common/constants.dart';
import 'package:flash_memo/data/note_models.dart';
import 'package:flash_memo/data/note_repository.dart';
import 'package:flash_memo/ui/Base/EasonBasePage.dart';
import 'package:flash_memo/utils/EasonAppBar.dart';
import 'package:flutter/material.dart';

class CreateNotePage extends EasonBasePage {
  static final GlobalKey<_CreateNotePageState> globalKey =
      GlobalKey<_CreateNotePageState>();
  // 可选参数，传入已有笔记进行编辑
  // 如果是新建笔记则为 null
  final Note? note;
  CreateNotePage({Key? key, this.note}) : super(key: key ?? globalKey);

  @override
  String get title => note == null ? '新建笔记' : '编辑笔记'; // 标题

  @override
  State<CreateNotePage> createState() => _CreateNotePageState();

  @override
  menuItems(BuildContext context) {
    final items = super.menuItems(context) ?? <EasonMenuItem>[];
    items.add(
      EasonMenuItem(
        title: '保存',
        icon: Icons.save,
        iconColor: Colors.green,
        onTap: () {
          final state = CreateNotePage.globalKey.currentState;
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

class _CreateNotePageState extends BasePageState<CreateNotePage> {
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

  Widget _buildTagEditor() {
    return Wrap(
      spacing: 8,
      children: [
        ..._tags.map(
          (tag) => Chip(
            label: Text(tag),
            onDeleted: () {
              setState(() {
                _tags.remove(tag);
              });
            },
          ),
        ),
        ActionChip(
          label: const Text('添加标签'),
          onPressed: () async {
            final newTag = await _showAddTagDialog();
            if (newTag != null &&
                newTag.isNotEmpty &&
                !_tags.contains(newTag)) {
              setState(() {
                _tags.add(newTag);
              });
            }
          },
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
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(hintText: '输入标签名'),
            onChanged: (value) => input = value.trim(),
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
        const Text('笔记本：'),
        const SizedBox(width: 12),
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
    return Row(
      children: _colorOptions.map((colorHex) {
        final isSelected = colorHex == _color;
        final color = Color(
          int.parse('FF${colorHex.replaceFirst('#', '')}', radix: 16),
        );
        return GestureDetector(
          onTap: () {
            setState(() {
              _color = colorHex;
            });
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 6),
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: Colors.black, width: 2)
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : null,
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget buildContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildNotebookSelector(),
        const SizedBox(height: 12),
        const Text('颜色：'),
        const SizedBox(height: 8),
        _buildColorSelector(),
        const SizedBox(height: 12),
        TextField(
          controller: _titleController,
          decoration: const InputDecoration(labelText: '标题'),
          maxLines: 1,
        ),
        const SizedBox(height: 12),
        Expanded(
          child: TextField(
            controller: _contentController,
            decoration: const InputDecoration(labelText: '内容'),
            maxLines: null,
            expands: true,
            keyboardType: TextInputType.multiline,
          ),
        ),
        const SizedBox(height: 12),
        const Text('标签'),
        _buildTagEditor(),
      ],
    );
  }
}
