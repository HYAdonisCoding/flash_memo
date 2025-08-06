import 'package:flash_memo/ui/calendar/CalendarPage.dart';
import 'package:flash_memo/ui/home/HomePage.dart';
import 'package:flash_memo/ui/personal/PersonalPage.dart';
import 'package:flash_memo/utils/EasonTabBar.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flash Memo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF4FC3F7)),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.dark(
          primary: Colors.cyan,
          secondary: Colors.tealAccent,
        ),
        useMaterial3: true,
      ), // 添加暗黑主题
      themeMode: ThemeMode.system, // 关键：根据系统模式自动切换
      home: EasonTabBarPage(
        items: [
          EasonTabBarItem(label: '首页', icon: Icons.home, vc: HomePage()),
          EasonTabBarItem(
            label: '日历',
            icon: Icons.calendar_today,
            vc: CalendarPage(),
          ),
          EasonTabBarItem(label: '我的', icon: Icons.person, vc: PersonalPage()),
        ],
      ),
    );
  }
}
