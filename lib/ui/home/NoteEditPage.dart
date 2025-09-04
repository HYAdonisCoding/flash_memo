import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flash_memo/ui/Base/SimpleVideoPlayer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'package:flash_memo/common/constants.dart';
import 'package:flash_memo/data/note_models.dart';
import 'package:flash_memo/data/note_repository.dart';
import 'package:flash_memo/ui/Base/EasonBasePage.dart';
import 'package:flash_memo/utils/EasonAppBar.dart';
import 'package:flutter/material.dart';
import 'package:flash_memo/ui/home/TagEditPage.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:intl/intl.dart';
import 'package:flutter_quill_extensions/flutter_quill_extensions.dart';

class LocalVideoEmbedBuilder implements EmbedBuilder {
  @override
  String get key => BlockEmbed.videoType;

  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    final videoPath = embedContext.node.value.data?.toString() ?? '';

    return FutureBuilder<String>(
      future: _resolveVideoPath(videoPath),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SizedBox(
            width: double.infinity,
            height: 200,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        final resolvedPath = snapshot.data!;
        final videoWidget = resolvedPath.startsWith('http')
            ? SimpleVideoPlayer(url: resolvedPath)
            : SimpleVideoPlayer(file: File(resolvedPath));
        return LayoutBuilder(
          builder: (context, constraints) {
            // 可以固定宽度填满父容器，高度按16:9比例
            final width = constraints.maxWidth;
            final height = width * 9 / 16;

            return SizedBox(width: width, height: height, child: videoWidget);
          },
        );
      },
    );
  }

  @override
  String toPlainText(Embed node) => '[视频]';

  @override
  bool get expanded => true;

  @override
  WidgetSpan buildWidgetSpan(Widget widget) {
    return WidgetSpan(child: widget, alignment: PlaceholderAlignment.middle);
  }

  Future<String> _resolveVideoPath(String path) async {
    if (path.isEmpty) return '';
    if (path.startsWith('http') || path.startsWith('https')) return path;
    final docs = await getApplicationDocumentsDirectory();
    debugPrint('解析视频路径: $path -> ${docs.path}/$path');
    return '${docs.path}/$path';
  }
}

class LocalImageEmbedBuilder implements EmbedBuilder {
  @override
  String get key => BlockEmbed.imageType;

  /// 新版本只传入 BuildContext + EmbedContext
  @override
  Widget build(BuildContext context, EmbedContext embedContext) {
    final String imagePath = embedContext.node.value.data?.toString() ?? '';

    return FutureBuilder<String>(
      future: _resolveImagePath(imagePath),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const SizedBox(
            width: 56,
            height: 56,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        final resolved = snap.data ?? '';

        if (resolved.startsWith('http')) {
          return Image.network(
            resolved,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => _buildMissingWidget(),
          );
        }

        try {
          final file = File(resolved);
          if (file.existsSync()) {
            return Image.file(
              file,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => _buildMissingWidget(),
            );
          } else {
            return _buildMissingWidget();
          }
        } catch (_) {
          return _buildMissingWidget();
        }
      },
    );
  }

  @override
  String toPlainText(Embed node) => '[图片]';

  @override
  bool get expanded => true;

  Widget _buildMissingWidget() {
    return Container(
      width: 120,
      height: 80,
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.broken_image, size: 28, color: Colors.grey),
          SizedBox(height: 6),
          Text('图片丢失', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Future<String> _resolveImagePath(String path) async {
    if (path.isEmpty) return '';
    if (path.startsWith('http') ||
        path.startsWith('https') ||
        path.startsWith('data:')) {
      return path;
    }
    if (path.startsWith('/')) {
      return path; // 兼容旧数据
    }
    final docs = await getApplicationDocumentsDirectory();
    return '${docs.path}/$path';
  }

  @override
  WidgetSpan buildWidgetSpan(Widget widget) {
    // TODO: implement buildWidgetSpan
    throw UnimplementedError();
  }
}

class NoteEditPage extends EasonBasePage {
  // 可选参数，传入已有笔记进行编辑
  // 如果是新建笔记则为 null
  Note? note;
  String? notebook; // 笔记本 可选参数

  NoteEditPage({Key? key, this.note, this.notebook}) : super(key: key);

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
          // 找到 state 并调用内部的 saveNote 方法
          final state = context.findAncestorStateOfType<_NoteEditPageState>();
          state?.saveNote();
          Navigator.pop(context, true); // 表示需要刷新
        },
      ),
    );

    return items;
  }
}

class _NoteEditPageState extends BasePageState<NoteEditPage> {
  late TextEditingController _titleController;
  final _toolbarScrollController = ScrollController();
  final _editorScrollController = ScrollController();
  late QuillController _contentController;
  final FocusNode _editorFocusNode = FocusNode();
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
  bool _isInitialized = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    debugPrint("ModalRoute【笔记本】$args");
  }

  @override
  /*************  ✨ Windsurf Command ⭐  *************/
  /// initState
  /// initState 方法是 Flutter Framework 在构建小部件树时调用的。
  /// 在这里，我们可以进行一些初始化工作，例如：
  /// - 如果是编辑模式，初始化已有笔记数据
  /// - 监听内容变化和标题变化
  /*******  c27b143c-809e-4782-8701-637629c37379  *******/
  void initState() {
    super.initState();
    debugPrint('【笔记本】${widget.notebook} ');
    // 先初始化控制器，保证不会报 LateInitializationError
    _titleController = TextEditingController();
    _contentController = QuillController.basic();
    // 如果是编辑模式，初始化已有笔记数据
    if (isEditing) {
      _initEditData();
      _isInitialized = true;
      // 监听内容变化
      _contentController.addListener(_autoSave);

      // 监听标题变化
      _titleController.addListener(_autoSave);
    } else {
      _initNewNote();
    }
  }

  Timer? _saveDebounce;

  void _autoSave() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(seconds: 2), () {
      saveNote();
      debugPrint("【自动保存】笔记已保存");
    });
  }

  Future<void> _initNewNote() async {
    final emptyNote = Note(
      notebook: widget.notebook != null
          ? widget.notebook!
          : (kDefaultNotebooks.isNotEmpty ? kDefaultNotebooks[0] : '工作'),
      title: '',
      content: '',
      tags: [],
      color: _color,
      isDeleted: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final savedNote = await NoteRepository().saveNote(emptyNote);
    setState(() {
      widget.note = savedNote; // 这里是 Note 类型，避免类型错误
      _tags = savedNote.tags.toList();
      _initEditData(); // 初始化 _contentController
      _contentController.addListener(_autoSave); // ✅ 在初始化完成后添加监听
      _titleController.addListener(_autoSave); // 同样处理标题
      _isInitialized = true;
    });
  }

  void _initEditData() {
    // 初始化编辑模式下的笔记数据
    _selectedNotebook = widget.note?.notebook ?? '工作';
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = QuillController.basic();
    // 如果 content 是 json 字符串（Delta）
    try {
      var myJSON = jsonDecode(widget.note?.content ?? '');
      debugPrint('解析内容为 JSON: $myJSON');
      _contentController = QuillController(
        document: Document.fromJson(myJSON),
        selection: const TextSelection.collapsed(offset: 0),
      );
    } catch (e) {
      // 如果 content 是纯文本
      _contentController = QuillController(
        document: Document()..insert(0, widget.note?.content ?? ''),
        selection: const TextSelection.collapsed(offset: 0),
      );
    }
    debugPrint('Document 文本预览: ${_contentController.document.toPlainText()}');
    _tags = widget.note?.tags.toList() ?? [];
    _color = widget.note?.color ?? _color;
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _contentController.removeListener(_autoSave);
    _titleController.removeListener(_autoSave); // 移除监听
    _handleEmptyNoteCleanup();
    _titleController.dispose();
    _contentController.dispose();
    _editorFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleEmptyNoteCleanup() async {
    // 判断标题和内容是否均为空
    final titleEmpty = _titleController.text.trim().isEmpty;
    final isContentEmpty = _contentController.document.isEmpty();

    if (titleEmpty && isContentEmpty) {
      // 调用硬删除删除空白笔记
      await NoteRepository().hardDeleteNoteById(widget.note!.id!);
    }
  }

  Future<void> saveNote() async {
    final title = _titleController.text.trim();
    final contentJson = jsonEncode(
      _contentController.document.toDelta().toJson(),
    );

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
      content: contentJson,
      tags: _tags,
      color: _color,
      isDeleted: false,
      createdAt: widget.note?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    //  调用仓库保存newNote，保存成功后返回上一页
    // 这里可以调用 NoteRepository 的方法保存笔记
    // 调用仓库保存newNote，保存成功后返回上一页
    // 真正写库
    final savedNote = await NoteRepository().saveNote(newNote);

    // 更新 widget.note，避免继续用旧对象
    setState(() {
      widget.note = savedNote;
      _tags = savedNote.tags.toList();
    });
    // Navigator.pop(context, true); // 表示需要刷新
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
    return Container(
      height: 72, // 固定高度，两行标签
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, -1),
          ),
        ],
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 左侧标签列表，可左右滚动
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                alignment: WrapAlignment.start,
                children: _tags
                    .map(
                      (tag) => Chip(
                        label: Text(tag),
                        backgroundColor: Colors.grey.shade200,
                        onDeleted: () {
                          setState(() {
                            _tags.remove(tag);
                          });
                        },
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    )
                    .toList(),
              ),
            ),
          ),

          // 右侧编辑按钮
          GestureDetector(
            onTap: () async {
              if (widget.note == null) return; // ⚠ 避免 Null check
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => TagEditPage(note: widget.note!),
                ),
              );
              if (result == true) {
                _refreshTags();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.shade600,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: const [
                  Icon(Icons.edit, size: 18, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    '编辑',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
  @override
  Widget buildContent(BuildContext context) {
    if (!_isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // 顶部信息区（不可滚动）
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 笔记本 & 颜色选择
              Row(
                children: [
                  Expanded(child: _buildNotebookSelector()),
                  const SizedBox(width: 10),
                  Expanded(child: _buildColorSelector()),
                ],
              ),
              const SizedBox(height: 10),

              // 时间信息
              Row(
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
              const SizedBox(height: 10),

              // 标题输入
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
            ],
          ),
        ),

        const SizedBox(height: 1),

        // 中间编辑区（工具栏 + 编辑器，占满剩余空间）
        Expanded(
          child: Column(
            children: [
              // 工具栏
              QuillSimpleToolbar(
                controller: _contentController,
                config: QuillSimpleToolbarConfig(
                  multiRowsDisplay: false,
                  showAlignmentButtons: true,
                  embedButtons: FlutterQuillEmbeds.toolbarButtons(
                    imageButtonOptions: QuillToolbarImageButtonOptions(
                      imageButtonConfig: QuillToolbarImageConfig(
                        onImageInsertCallback: (image, controller) async {
                          debugPrint('onImageInsertCallback插入图片:$image');
                          String noteId = widget.note?.id.toString() ?? '';
                          final savedPath = await saveImageToAppDir(
                            image,
                            noteId,
                          );

                          final index = _contentController.selection.baseOffset;
                          final docLength = _contentController.document.length;
                          final insertIndex = (index < 0 || index > docLength)
                              ? docLength
                              : index;

                          _contentController.replaceText(
                            insertIndex,
                            0,
                            BlockEmbed.image(savedPath!),
                            TextSelection.collapsed(offset: insertIndex + 1),
                          );
                          return Future.value();
                        },
                      ),
                    ),

                    videoButtonOptions: QuillToolbarVideoButtonOptions(
                      videoConfig: QuillToolbarVideoConfig(
                        onVideoInsertCallback: (video, controller) async {
                          debugPrint('onVideoInsertCallback插入视频:$video');
                          String noteId = widget.note?.id.toString() ?? '';
                          final savedPath = await saveVideoToAppDir(
                            video,
                            noteId,
                          );

                          final index = _contentController.selection.baseOffset;
                          final docLength = _contentController.document.length;
                          final insertIndex = (index < 0 || index > docLength)
                              ? docLength
                              : index;

                          _contentController.replaceText(
                            insertIndex,
                            0,
                            BlockEmbed.video(savedPath!),
                            TextSelection.collapsed(offset: insertIndex + 1),
                          );
                          return Future.value();
                        },
                      ),
                    ),
                  ),
                ),
              ),

              const Divider(height: 1),

              // 编辑器
              Expanded(
                child: QuillEditor(
                  controller: _contentController,
                  scrollController: _editorScrollController,
                  focusNode: _editorFocusNode,
                  config: QuillEditorConfig(
                    embedBuilders: [
                      LocalImageEmbedBuilder(),
                      LocalVideoEmbedBuilder(),
                      ...FlutterQuillEmbeds.editorBuilders(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // 底部标签栏
        _buildTagEditor(),
        const SizedBox(height: 0),
      ],
    );
  }

  /// 将图片从临时路径拷贝到应用的 Documents/images 目录下，并返回相对路径。
  ///
  /// - originalPath: 原始图片的绝对路径（通常是 ImagePicker 返回的临时文件路径）
  /// - noteId: 当前笔记的 ID，用于文件名唯一性区分
  ///
  /// 处理流程：
  /// 1. 检查原始文件是否存在，不存在直接返回 null。
  /// 2. 读取文件内容并计算 MD5，用于避免同一张图片重复保存。
  /// 3. 保留原始文件扩展名（jpg/png 等），生成新的文件名：`noteId-md5.ext`。
  /// 4. 确保 `Documents/images` 目录存在，不存在则递归创建。
  /// 5. 将文件写入目标目录，并生成新的文件。
  /// 6. 返回相对路径（如 `images/xxx.png`），避免存绝对路径导致重启后 UUID 目录失效。
  Future<String?> saveImageToAppDir(String originalPath, String noteId) async {
    final file = File(originalPath);
    if (!await file.exists()) return null; // 1. 校验原始文件是否存在

    final bytes = await file.readAsBytes();
    final md5Hash = md5.convert(bytes).toString(); // 2. 基于内容计算 MD5，避免重复
    final extension = originalPath.split('.').last; // 3. 保留扩展名

    final docsDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${docsDir.path}/images');
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true); // 4. 确保 images 目录存在
    }

    // 5. 新的文件名：笔记 ID + MD5 + 扩展名
    final fileName = '$noteId-$md5Hash.$extension';
    final newFile = await File(
      '${imagesDir.path}/$fileName',
    ).writeAsBytes(bytes);

    // 6. 只返回相对路径，避免 iOS/Android 重启后绝对路径失效
    return 'images/$fileName';
  }

  Future<String?> saveVideoToAppDir(String originalPath, String noteId) async {
    final file = File(originalPath);
    if (!await file.exists()) return null;

    final bytes = await file.readAsBytes();
    final md5Hash = md5.convert(bytes).toString();
    final extension = originalPath.split('.').last;

    final docsDir = await getApplicationDocumentsDirectory();
    final videosDir = Directory('${docsDir.path}/videos');
    if (!await videosDir.exists()) {
      await videosDir.create(recursive: true);
    }

    final fileName = '$noteId-$md5Hash.$extension';
    await File('${videosDir.path}/$fileName').writeAsBytes(bytes);

    return 'videos/$fileName';
  }
}
