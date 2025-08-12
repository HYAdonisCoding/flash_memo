import 'package:flash_memo/ui/Base/EasonBasePage.dart';
import 'package:flash_memo/ui/Base/WelcomePage.dart';
import 'package:flash_memo/ui/Root/AppRootPage.dart';
import 'package:flash_memo/ui/calendar/CalendarPage.dart';
import 'package:flash_memo/ui/home/HomePage.dart';
import 'package:flash_memo/ui/personal/PersonalPage.dart';
import 'package:flash_memo/utils/EasonTabBar.dart';
import 'package:flutter/material.dart';

class GuidePage extends EasonBasePage {
  const GuidePage({super.key});

  @override
  String get title => 'GuidePage';

  @override
  bool get showBack => false;

  @override
  State<GuidePage> createState() => _GuidePageState();

  @override
  get useCustomAppBar => true;
}

class _GuidePageState extends BasePageState<GuidePage> {
  int _currentPage = 0;
  final PageController _controller = PageController();

  @override
  Widget buildContent(BuildContext context) {
    final pages = [
      _buildPage("欢迎使用", "这是一个高效的记忆工具", Icons.flash_on),
      _buildPage("随时记录", "快速添加灵感与笔记", Icons.edit),
      _buildPage("高效复习", "科学安排复习节奏", Icons.calendar_today),
    ];

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo.shade900, Colors.indigo.shade400],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(
              top: 0,
              bottom: 100,
            ), // 底部加100间距，上面不变
            child: PageView.builder(
              controller: _controller,
              itemCount: pages.length,
              onPageChanged: (index) {
                setState(() => _currentPage = index);
              },
              itemBuilder: (context, index) => pages[index],
            ),
          ),
        ),
        Positioned(
          bottom: 180,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(pages.length, (index) {
              return AnimatedContainer(
                duration: Duration(milliseconds: 300),
                margin: EdgeInsets.symmetric(horizontal: 6),
                width: _currentPage == index ? 16 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == index ? Colors.white : Colors.white60,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ),
        if (_currentPage == pages.length - 1)
          Positioned(
            bottom: 80,
            left: 40,
            right: 40,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const WelcomePage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.indigo,
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text("立即开始", style: TextStyle(fontSize: 16)),
            ),
          ),
      ],
    );
  }

  Widget _buildPage(String title, String subtitle, IconData icon) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 100, color: Colors.white),
        SizedBox(height: 40),
        Text(
          title,
          style: TextStyle(
            fontSize: 28,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        Text(subtitle, style: TextStyle(fontSize: 18, color: Colors.white70)),
      ],
    );
  }
}
