import 'dart:async';

import 'package:flash_memo/ui/Base/EasonBasePage.dart';
import 'package:flash_memo/ui/Root/AppRootPage.dart';
import 'package:flutter/material.dart';
class WelcomePage extends EasonBasePage {
  const WelcomePage({Key? key}) : super(key: key);

  @override
  String get title => 'WelcomePage';

  @override
  bool get showBack => false;

  @override
  State<WelcomePage> createState() => _WelcomePageState();

  @override
  get useCustomAppBar => true;
}

class _WelcomePageState extends BasePageState<WelcomePage> with TickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..reverse(from: 1.0);
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        _goToMainPage();
      }
    });
    _animationController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  int get _countdown => (_animationController.value * 3).ceil();

  void _goToMainPage() {
    _animationController.stop();
    final mainPage = buildMainTabBarPage();
    if (mainPage == null) {
      debugPrint('⚠️ buildMainTabBarPage 返回 null，无法跳转');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('页面加载失败，请重启应用')));
      return;
    }

    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => mainPage));
  }

  @override
  Widget buildContent(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1D2671), Color(0xFFC33764)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.flash_on, size: 100, color: Colors.white),
              const SizedBox(height: 40),
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Colors.white, Colors.yellowAccent],
                ).createShader(bounds),
                child: const Text(
                  '欢迎来到 FlashMemo',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 340),
              ElevatedButton(
                onPressed: _goToMainPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Color(0xFF1D2671),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text('立即进入应用', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
        Positioned(
          top: 40,
          right: 20,
          child: Stack(
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator(
                      value: _animationController.value,
                      strokeWidth: 4,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  );
                },
              ),
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$_countdown',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
