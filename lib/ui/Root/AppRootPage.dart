import 'package:flutter/material.dart';
import 'package:flash_memo/ui/home/HomePage.dart';
import 'package:flash_memo/ui/calendar/CalendarPage.dart';
import 'package:flash_memo/ui/personal/PersonalPage.dart';
import 'package:flash_memo/utils/EasonTabBar.dart';

Widget buildMainTabBarPage() {
  debugPrint('开始构建 MainTabBarPage');
  try {
    final items = [
      EasonTabBarItem(
        label: '首页',
        icon: Icons.home,
        vc: _buildSafePage(() => HomePage(), 'HomePage'),
      ),
      EasonTabBarItem(
        label: '日历',
        icon: Icons.calendar_today,
        vc: _buildSafePage(() => CalendarPage(), 'CalendarPage'),
      ),
      EasonTabBarItem(
        label: '我的',
        icon: Icons.person,
        vc: _buildSafePage(() => PersonalPage(), 'PersonalPage'),
      ),
    ];

    if (items.isEmpty || items.any((item) => item.vc == null)) {
      debugPrint('Tab 页面为空或含有 vc 为 null 的项');
      return Scaffold(
        body: Center(child: Text('页面加载失败，请重启应用')),
      );
    }

    final page = EasonTabBarPage(items: items);
    if (page == null) {
      debugPrint('EasonTabBarPage 返回了 null');
      return Scaffold(
        body: Center(child: Text('主页构建失败')),
      );
    }

    return page;
  } catch (e, stack) {
    debugPrint('构建 MainTabBarPage 异常: $e\n$stack');
    return Scaffold(
      body: Center(child: Text('构建主页失败: $e')),
    );
  }
}

Widget _buildSafePage(Widget Function() builder, String label) {
  try {
    debugPrint('构建页面: $label');
    return builder();
  } catch (e, stack) {
    debugPrint('$label 构建失败: $e\n$stack');
    return Scaffold(
      body: Center(child: Text('$label 构建失败')),
    );
  }
}
