import 'package:flutter/material.dart';

class EasonTabBarItem {
  final String label;
  final Widget vc;
  final IconData? icon;
  final Widget? customIcon;

  EasonTabBarItem({
    required this.label,
    required this.vc,
    this.icon,
    this.customIcon,
  });
}

class EasonTabBar extends StatelessWidget {
  final List<EasonTabBarItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Color activeColor;
  final Color inactiveColor;
  final double height;
  final double indicatorHeight;
  final List<Color>? indicatorGradient;

  const EasonTabBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.activeColor = Colors.deepPurple,
    this.inactiveColor = Colors.grey,
    this.height = 56,
    this.indicatorHeight = 4,
    this.indicatorGradient,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      color: Colors.white,
      child: SizedBox(
        height: height + indicatorHeight,
        child: Stack(
          children: [
            Row(
              children: List.generate(items.length, (index) {
                final selected = index == currentIndex;
                return Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => onTap(index),
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      padding: EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: selected
                            ? activeColor.withOpacity(0.08)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min, // 关键
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (items[index].customIcon != null)
                            items[index].customIcon!
                          else if (items[index].icon != null)
                            AnimatedScale(
                              scale: selected ? 1.2 : 1.0,
                              duration: Duration(milliseconds: 300),
                              curve: Curves.easeOutBack,
                              child: Icon(
                                items[index].icon,
                                color: selected ? activeColor : inactiveColor,
                                size: 24,
                              ),
                            ),
                          SizedBox(height: 2),
                          AnimatedDefaultTextStyle(
                            duration: Duration(milliseconds: 300),
                            style: TextStyle(
                              color: selected ? activeColor : inactiveColor,
                              fontWeight: selected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 12,
                              letterSpacing: 0.5,
                              shadows: selected
                                  ? [
                                      Shadow(
                                        color: activeColor.withOpacity(0.2),
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Text(
                              items[index].label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
            // 酷炫渐变指示器
            AnimatedPositioned(
              duration: Duration(milliseconds: 300),
              curve: Curves.elasticOut,
              left:
                  currentIndex *
                  (MediaQuery.of(context).size.width / items.length),
              bottom: 0,
              width: MediaQuery.of(context).size.width / items.length,
              height: indicatorHeight,
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 18),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    colors:
                        indicatorGradient ??
                        [Colors.deepPurple, Colors.blueAccent, Colors.cyan],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (indicatorGradient?.first ?? activeColor)
                          .withOpacity(0.18),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EasonTabBarPage extends StatefulWidget {
  final List<EasonTabBarItem> items;
  final Color activeColor;
  final Color inactiveColor;
  final double height;

  const EasonTabBarPage({
    super.key,
    required this.items,
    this.activeColor = Colors.deepPurple,
    this.inactiveColor = Colors.grey,
    this.height = 56,
  });

  @override
  State<EasonTabBarPage> createState() => _EasonTabBarPageState();
}

class _EasonTabBarPageState extends State<EasonTabBarPage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.items[_currentIndex].vc,
      bottomNavigationBar: EasonTabBar(
        items: widget.items,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        activeColor: widget.activeColor,
        inactiveColor: widget.inactiveColor,
        height: widget.height,
      ),
    );
  }
}
