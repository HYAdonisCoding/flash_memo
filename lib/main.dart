import 'package:flash_memo/ui/Base/GuidePage.dart';
import 'package:flash_memo/ui/Base/WelcomePage.dart';
import 'package:flash_memo/ui/Root/AppRootPage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:async';

const String kLastSeenVersion = 'last_seen_version';

Future<String> getInitialRoute() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;
    final lastVersion = prefs.getString(kLastSeenVersion);
    debugPrint('当前版本: $currentVersion, 上次版本: $lastVersion');
    if (lastVersion != currentVersion) {
      await prefs.setString(kLastSeenVersion, currentVersion);
      return '/guide';
    } else {
      return '/welcome';
    }
  } catch (e, stack) {
    debugPrint('初始化异常: $e\n$stack');
    return '/guide';
  }
}

void main() {
  // 建议调试阶段先设为 true，方便发现 Zone 错误
  BindingBase.debugZoneErrorsAreFatal = true;

  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        debugPrint('Flutter 异常捕获：${details.exception}');
        debugPrint('堆栈信息：\n${details.stack}');
      };
      final initialRoute = await getInitialRoute(); // 提前完成异步
      runApp(MyApp(initialRoute: initialRoute));
    },
    (error, stackTrace) {
      debugPrint('未捕获异常：$error');
      debugPrint('堆栈信息：\n$stackTrace');
    },
  );
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flash Memo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4FC3F7)),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.dark(
          primary: Colors.cyan,
          secondary: Colors.tealAccent,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      initialRoute: initialRoute,
      onGenerateRoute: (settings) {
        final routeName = settings.name ?? '/guide';
        debugPrint('【当前路由】$routeName');
        try {
          switch (routeName) {
            case '/guide':
              return MaterialPageRoute(builder: (_) => const GuidePage());
            case '/welcome':
              return MaterialPageRoute(builder: (_) => const WelcomePage());
            case '/home':
              final page = buildMainTabBarPage();
              return MaterialPageRoute(builder: (_) => page);
            default:
              return MaterialPageRoute(builder: (_) => const GuidePage());
          }
        } catch (e, st) {
          debugPrint('onGenerateRoute 构建页面异常: $e\n$st');
          return MaterialPageRoute(
            builder: (_) => Scaffold(
              appBar: AppBar(title: const Text('页面错误')),
              body: Center(child: Text('页面加载失败: $e')),
            ),
          );
        }
      },
    );
  }

  Route _buildFallbackRoute(String message) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('页面错误')),
        body: Center(child: Text(message)),
      ),
    );
  }
}
