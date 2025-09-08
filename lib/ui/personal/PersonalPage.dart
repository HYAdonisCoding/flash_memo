import 'dart:math';

import 'package:flash_memo/ui/Base/EasonBasePage.dart';
import 'package:flutter/material.dart';

class PersonalPage extends EasonBasePage {
  const PersonalPage({super.key});

  @override
  String get title => '个人中心';

  @override
  bool get showBack => false;

  @override
  State<PersonalPage> createState() => _PersonalPageState();
}

class _PersonalPageState extends BasePageState<PersonalPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget buildContent(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        // 霓虹动态背景
        AnimatedBuilder(
          animation: _controller,
          builder: (_, __) {
            return CustomPaint(
              size: size,
              painter: NeonBackgroundPainter(_controller.value),
            );
          },
        ),
        // 主体内容
        SafeArea(
          child: Column(
            children: [
              SizedBox(height: 20),
              // 发光头像，光晕随_controller律动并增加多彩渐变效果
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  // 计算光晕的动态强度，使用正弦函数实现律动效果
                  double glowIntensity = 0.6 + 0.4 * sin(_controller.value * 2 * pi);
                  // 计算渐变颜色，使用HSV色轮随时间变化实现多彩渐变
                  Color glowColor = HSVColor.fromAHSV(
                          1.0, (_controller.value * 360) % 360, 0.8, 1.0)
                      .toColor();

                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              // 使用动态计算的颜色和强度实现多彩光晕
                              color: glowColor.withOpacity(glowIntensity),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                      ),
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: AssetImage('lib/assets/images/avatar.png'),
                      ),
                    ],
                  );
                },
              ),
              SizedBox(height: 10),
              Text(
                'Eason',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w500,
                  color: Colors.cyanAccent,
                  shadows: [
                    Shadow(
                      color: Colors.cyanAccent.withOpacity(0.6),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 5),
              Text(
                '点亮未来，探索无限可能',
                style: TextStyle(
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: const Color.fromARGB(
                        255,
                        24,
                        120,
                        255,
                      ).withOpacity(0.6),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10),
              // 功能卡片
              Expanded(
                child: GridView.count(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  crossAxisCount: 3,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  children: [
                    _buildNeonCard(
                      icon: Icons.person,
                      label: '个人资料',
                      color: Colors.teal,
                      onTap: () {
                        // 处理点击事件
                      },
                    ),
                    _buildNeonCard(
                      icon: Icons.bookmark,
                      label: '收藏',
                      color: Colors.pink,
                      onTap: () {
                        // 处理点击事件
                      },
                    ),
                    _buildNeonCard(
                      icon: Icons.history,
                      label: '历史',
                      color: Colors.orange,
                      onTap: () {
                        // 处理点击事件
                      },
                    ),
                    _buildNeonCard(
                      icon: Icons.settings,
                      label: '设置',
                      color: Colors.cyan,
                      onTap: () {
                        // 处理点击事件
                      },
                    ),

                    _buildNeonCard(
                      icon: Icons.notifications,
                      label: '通知',
                      color: Colors.purple,
                      onTap: () {
                        // 处理点击事件
                      },
                    ),
                    _buildNeonCard(
                      icon: Icons.star,
                      label: '我的成就',
                      color: Colors.amber,
                      onTap: () {
                        // 处理点击事件
                      },
                    ),
                    _buildNeonCard(
                      icon: Icons.security,
                      label: '安全',
                      color: Colors.blueGrey,
                      onTap: () {
                        // 处理点击事件
                      },
                    ),
                    _buildNeonCard(
                      icon: Icons.logout,
                      label: '退出',
                      color: Colors.redAccent,
                      onTap: () {
                        // 处理点击事件
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNeonCard({
    required IconData icon,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: () {
        debugPrint('Tapped on $label');
        onTap?.call();
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.6), color],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.6),
              blurRadius: 15,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.white),
            SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 自定义霓虹线条背景
class NeonBackgroundPainter extends CustomPainter {
  final double animationValue;
  NeonBackgroundPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int i = 0; i < 5; i++) {
      paint.color = Colors.cyanAccent.withOpacity(0.1 + 0.2 * i);
      final path = Path();
      for (double x = 0; x < size.width; x += 2) {
        final y =
            size.height / 2 +
            50 *
                (i + 1) *
                sin((x / size.width * 2 * pi) + (animationValue * 2 * pi));
        if (x == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant NeonBackgroundPainter oldDelegate) => true;
}