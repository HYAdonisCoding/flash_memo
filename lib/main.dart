import 'package:flash_memo/data/note_repository.dart';
import 'package:flash_memo/ui/Base/GuidePage.dart';
import 'package:flash_memo/ui/Base/WelcomePage.dart';
import 'package:flash_memo/ui/Root/AppRootPage.dart';
import 'package:flash_memo/ui/home/NoteEditPage.dart';
import 'package:flash_memo/ui/home/NoteFilterPage.dart';
import 'package:flash_memo/ui/home/NoteListPage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:async';
import 'package:flash_memo/data/note_models.dart';

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

Future<void> main() async {
  // 建议调试阶段先设为 true，方便发现 Zone 错误
  BindingBase.debugZoneErrorsAreFatal = true;

  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      // 调用初始化方法，确保默认笔记本和默认笔记存在
      final repo = NoteRepository();
      await repo.initializeAppData();
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
      localizationsDelegates: const [
        FlutterQuillLocalizations.delegate, // ✅ 必须加上
      ],
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
            case '/note_filter':
              if (settings.arguments is List<Note>) {
                final notes = settings.arguments as List<Note>;
                debugPrint('【笔记参数notes】$notes');
                return MaterialPageRoute(
                  builder: (_) => NoteFilterPage(notes: notes),
                );
              } else if (settings.arguments is String) {
                final noteCategory = settings.arguments as String;
                debugPrint('【笔记参数noteCategory】$noteCategory');
                return MaterialPageRoute(
                  builder: (_) => NoteFilterPage(notebook: noteCategory),
                );
              } else if (settings.arguments is Map) {
                // 允许传 Map 来同时包含 notes 和 notebook
                final args = settings.arguments as Map;
                debugPrint('【笔记参数】$args');
                return MaterialPageRoute(
                  builder: (_) => NoteFilterPage(
                    notes: args['notes'] as List<Note>?,
                    notebook: args['notebook'] as String?,
                  ),
                );
              } else {
                return _buildFallbackRoute('无效的笔记参数');
              }
            case '/note_list':
              if (settings.arguments is NoteCategory) {
                final notebook = settings.arguments as NoteCategory;
                return MaterialPageRoute(
                  builder: (_) => NoteListPage(notebook: notebook),
                );
              } else {
                return _buildFallbackRoute('无效的笔记本参数');
              }
            case '/create_note':
              if (settings.arguments is Note) {
                final note = settings.arguments as Note;
                return MaterialPageRoute(
                  builder: (_) => NoteEditPage(note: note),
                );
              } else if (settings.arguments is String) {
                final notebook = settings.arguments as String?;
                return MaterialPageRoute(
                  builder: (_) => NoteEditPage(notebook: notebook),
                );
              }
              return MaterialPageRoute(builder: (_) => NoteEditPage());
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
