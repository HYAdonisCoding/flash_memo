import 'package:flash_memo/common/constants.dart';
import 'package:flash_memo/data/note_models.dart';
import 'package:flash_memo/ui/Base/EasonBasePage.dart';
import 'package:flash_memo/utils/EasonAppBar.dart';
import 'package:flutter/material.dart';
import 'package:flash_memo/data/note_repository.dart';

class TagEditPage extends EasonBasePage {
  static final GlobalKey<_TagEditPageState> globalKey =
      GlobalKey<_TagEditPageState>();
  final Note note; // 传入的笔记对象，用于编辑或新建时使用

  TagEditPage({Key? key, required this.note}) : super(key: key ?? globalKey);

  @override
  String get title => '标签编辑';

  @override
  State<TagEditPage> createState() => _TagEditPageState();
  @override
  List<EasonMenuItem>? menuItems(BuildContext context) {
    final items = super.menuItems(context) ?? <EasonMenuItem>[];
    // 保存
    items.insert(
      0,
      EasonMenuItem(
        title: '保存',
        icon: Icons.save,
        iconColor: Colors.green,
        onTap: () async {
          final state = TagEditPage.globalKey.currentState;
          if (state != null) {
            await NoteRepository().updateNoteTags(note.id!, state.addedTags);
            // ignore: use_build_context_synchronously
            Navigator.of(context).pop(true);
          } else {
            debugPrint('状态未准备好，无法保存');
          }
        },
      ),
    );
    return items;
  }
}

class _TagEditPageState extends BasePageState<TagEditPage> {
  List<String> addedTags = [];
  List<String> myTags = [];
  @override
  void initState() {
    super.initState();
    _loadMyTags();
  }

  Future<void> _loadMyTags() async {
    NoteRepository noteRepository = NoteRepository();
    List<String> tags = await noteRepository.getAllCustomTags();
    if (widget.note.id == null) {
      // 处理异常情况，比如直接返回空列表或提示
      setState(() {
        myTags = tags;
        addedTags = [];
      });
      return;
    }

    List<String> tagsAdded = await noteRepository.getTagsByNoteId(
      widget.note.id!,
    );

    setState(() {
      myTags = tags;
      addedTags = tagsAdded;
    });
  }

  final TextEditingController _tagController = TextEditingController();

  void _addTag() {
    final newTag = _tagController.text.trim();
    if (newTag.isNotEmpty && !addedTags.contains(newTag)) {
      setState(() {
        addedTags.add(newTag);
      });
      _tagController.clear();
    }
  }

  void _toggleTag(String tag) {
    setState(() {
      if (addedTags.contains(tag)) {
        addedTags.remove(tag);
      } else {
        addedTags.add(tag);
      }
    });
  }

  final sectionHeight = 10.0;
  @override
  Widget buildContent(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(sectionHeight),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('已添加的标签', style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: sectionHeight),
            Wrap(
              spacing: 2,
              runSpacing: 2,
              children: addedTags.map((tag) {
                return Chip(
                  label: Text(tag, style: const TextStyle(fontSize: 12)),
                  backgroundColor: Colors.blue.shade100,
                  deleteIcon: const Icon(Icons.close, size: 14),
                  onDeleted: () {
                    setState(() {
                      addedTags.remove(tag);
                    });
                  },
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                );
              }).toList(),
            ),
            SizedBox(height: sectionHeight),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagController,
                    decoration: InputDecoration(
                      hintText: '输入新标签',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: sectionHeight,
                        horizontal: sectionHeight,
                      ),
                    ),
                    style: const TextStyle(fontSize: 14),
                    onSubmitted: (_) => _addTag(),
                  ),
                ),
                SizedBox(width: sectionHeight),
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.blue,
                  child: IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    onPressed: _addTag,
                    tooltip: '添加标签',
                    splashRadius: 20,
                  ),
                ),
              ],
            ),
            SizedBox(height: sectionHeight),
            Text('默认标签', style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: sectionHeight),
            Wrap(
              spacing: 8,
              children: kDefaultTags
                  .map(
                    (tag) => ChoiceChip(
                      label: Text(tag),
                      selected: addedTags.contains(tag),
                      onSelected: (_) => _toggleTag(tag),
                    ),
                  )
                  .toList(),
            ),
            SizedBox(height: sectionHeight),
            Text('我的标签', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: myTags
                  .map(
                    (tag) => ChoiceChip(
                      label: Text(tag),
                      selected: addedTags.contains(tag),
                      onSelected: (_) => _toggleTag(tag),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
