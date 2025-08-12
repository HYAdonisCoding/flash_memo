import 'package:flash_memo/ui/SearchPage.dart';
import 'package:flutter/material.dart';

class EasonToolBar extends StatelessWidget {
  final List<IconData> icons;
  final void Function(int index)? onTap;
  final Map<int, GlobalKey>? keys; // 添加索引到Key的映射

  const EasonToolBar({super.key, required this.icons, this.onTap, this.keys});

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: statusBarHeight + 56, // 自定义 toolbar 高度
      padding: EdgeInsets.only(top: statusBarHeight, left: 16, right: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [Colors.grey.shade900, Colors.grey.shade800, Colors.grey.shade700]
              : [Colors.blue.shade800, Colors.blueAccent, Colors.cyan],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black87 : Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            key: keys?[0],  // 根据索引给按钮赋key
            onTap: () {
              if (onTap != null) onTap!(0);
            },
            child: Icon(icons[0], size: 28, color: isDark ? Colors.grey[300] : Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white12 : Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, size: 18, color: isDark ? Colors.white54 : Colors.white70),
                  const SizedBox(width: 6),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => SearchPage()),
                        );
                      },
                      child: Text(
                        '搜索',
                        style: TextStyle(
                          color: isDark ? Colors.white54 : Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            key: keys?[1],  // 根据索引给按钮赋key
            onTap: () {
              if (onTap != null) onTap!(1);
            },
            child: Icon(icons[1], size: 28, color: isDark ? Colors.grey[300] : Colors.white),
          ),
        ],
      ),
    );
  }
}
