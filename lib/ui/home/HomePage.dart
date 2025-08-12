import 'package:flash_memo/data/note_repository.dart';
import 'package:flash_memo/ui/Base/EasonBasePage.dart';
import 'package:flash_memo/ui/Base/empty_view.dart';
import 'package:flutter/material.dart';
import 'package:flash_memo/data/note_models.dart';

class HomePage extends EasonBasePage {
  const HomePage({super.key});

  @override
  String get title => 'HomePage';

  @override
  bool get showBack => false;
  @override
  State<HomePage> createState() => _HomePageState();

  
}

class _HomePageState extends BasePageState<HomePage> {
  final NoteRepository _repo = NoteRepository();
  late Future<List<NoteCategory>> _categories;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  void _loadCategories() {
    setState(() {
      _categories = _repo.getNoteCategoriesWithSpecial();
    });
  }

  // 优化日期格式化
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays >= 1) return '${diff.inDays}天前';
    if (diff.inHours >= 1) return '${diff.inHours}小时前';
    if (diff.inMinutes >= 1) return '${diff.inMinutes}分钟前';
    return '刚刚';
  }

  Widget _buildNoteCard(NoteCategory note) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          minVerticalPadding: 8,
          leading: CircleAvatar(
            backgroundColor: Colors.blue,
            radius: 18,
            child: const Icon(Icons.book, color: Colors.white),
          ),
          title: Text(
            note.title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            '${note.noteCount}笔记 · ${note.totalWords}字 · ${_formatDate(note.lastUpdated)}',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          trailing: Icon(Icons.chevron_right, color: Colors.grey[350]),
          onTap: () {
            // 跳转笔记列表页
            Navigator.pushNamed(context, '/note_list', arguments: note);
          },
        ),
      ),
    );
  }

  Future<void> _onRefresh() async {
    _loadCategories();
    await _categories;
  }

  @override
  Widget buildContent(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: FutureBuilder<List<NoteCategory>>(
        future: _categories,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return EmptyView(
              icon: Icons.note_alt_outlined,
              title: '暂无笔记',
              subtitle: '你还没有创建任何笔记，赶快开始吧！',
              onTap: () {
                Navigator.pushNamed(context, '/create_note');
              },
            );
          }
          final notes = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: notes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final note = notes[index];
              return _buildNoteCard(note);
            },
          );
        },
      ),
    );
  }
}