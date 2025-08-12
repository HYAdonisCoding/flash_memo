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
    final colors = getNotebookColors(note.title);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            colors.backgroundStart.withOpacity(0.3),
            colors.backgroundEnd.withOpacity(0.3),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.backgroundStart.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Card(
        color: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.pushNamed(context, '/note_list', arguments: note);
          },
          // 统一左右内边距
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              children: [
                // 左侧图标不加额外padding
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [colors.backgroundStart, colors.backgroundEnd],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colors.backgroundStart.withOpacity(0.5),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  // 把图标padding改成内边距
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    _getNotebookIcon(note).icon,
                    color: colors.iconColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (note.noteCount > 0)
                        Row(
                          children: [
                            _buildInfoItem('${note.noteCount}篇笔记'),
                            _buildDot(),
                            _buildInfoItem('${note.totalWords}字'),
                            _buildDot(),
                            _buildInfoItem(_formatDate(note.lastUpdated)),
                          ],
                        ),
                    ],
                  ),
                ),
                // 右侧箭头用 Padding 给右侧留白
                Padding(
                  padding: const EdgeInsets.only(right: 0),
                  child: const Icon(
                    Icons.chevron_right,
                    color: Colors.grey,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Icon _getNotebookIcon(NoteCategory note) {
    switch (note.title) {
      case '工作':
        return const Icon(Icons.work, color: Colors.white, size: 28);
      case '学习':
        return const Icon(Icons.school, color: Colors.white, size: 28);
      case '梦想笔记本':
        return const Icon(Icons.home, color: Colors.white, size: 28);
      case '随笔':
        return const Icon(Icons.note, color: Colors.white, size: 28);
      case '人生大事记':
        return const Icon(Icons.date_range, color: Colors.white, size: 28);
      case '回收站':
        return const Icon(Icons.delete_outline, color: Colors.white, size: 28);
      default:
        return const Icon(Icons.book, color: Colors.white, size: 28);
    }
  }

  // 分隔小圆点
  Widget _buildDot() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: Colors.grey.shade400,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildInfoItem(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        color: Colors.grey.shade600,
        fontWeight: FontWeight.w500,
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
            padding: const EdgeInsets.all(10),
            itemCount: notes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 1),
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
