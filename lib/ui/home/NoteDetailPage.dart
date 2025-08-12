import 'package:flash_memo/data/note_models.dart';
import 'package:flash_memo/data/note_repository.dart';
import 'package:flash_memo/ui/Base/EasonBasePage.dart';
import 'package:flash_memo/utils/EasonAppBar.dart';
import 'package:flutter/material.dart';

class NoteDetailPage extends EasonBasePage {
  Note? note; // 笔记
  String? notebook; // 笔记本 可选参数
  NoteDetailPage({super.key, this.note, this.notebook});

  @override
  String get title => 'NoteDetailPage';

  @override
  State<NoteDetailPage> createState() => _NoteDetailPageState();

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
          final state = context.findAncestorStateOfType<_NoteDetailPageState>();
          state?._toggleEdit();
          // 进入编辑页
          Navigator.pushNamed(context, '/create_note', arguments: note);
        },
      ),
      EasonMenuItem(
        title: '删除',
        icon: Icons.delete,
        iconColor: Colors.red,
        onTap: () {
          // 删除笔记
          if (note != null && note?.id != null) {
            NoteRepository().deleteNote(note!.id!);
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

class _NoteDetailPageState extends BasePageState<NoteDetailPage> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');
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

  Widget _buildTags() {
    final note = widget.note;
    if (note == null || note.tags == null || note.tags!.isEmpty) {
      return const SizedBox.shrink();
    }

    Color baseColor;
    try {
      final colorStr = note.color ?? '#2196F3'; // fallback color blue
      baseColor = Color(int.parse('FF${colorStr.replaceFirst('#', '')}', radix: 16));
    } catch (_) {
      baseColor = Colors.blue;
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: note.tags!.map((tag) {
        return Chip(
          label: Text(
            tag,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: baseColor.withOpacity(0.7),
          shadowColor: baseColor.withOpacity(0.5),
          elevation: 2,
        );
      }).toList(),
    );
  }

  @override
  Widget buildContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTags(),
          const SizedBox(height: 16),
          Expanded(
            child: _isEditing
                ? TextField(
                    controller: _contentController,
                    maxLines: null,
                    expands: true,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: '输入内容...',
                    ),
                    style: const TextStyle(fontSize: 16),
                  )
                : SingleChildScrollView(
                    child: Text(
                      widget.note?.content ?? '',
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
