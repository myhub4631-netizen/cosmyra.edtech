import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'core/theme/app_theme.dart';
import 'core/services/supabase_service.dart';
import 'features/navigation/main_navigation.dart';
import 'features/auth/signup_screen.dart';
import 'features/auth/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy(); // Removes # hash from Flutter Web URLs
  await SupabaseService.initialize();
  runApp(const CosmyraApp());
}

class CosmyraApp extends StatelessWidget {
  const CosmyraApp({Key? key}) : super(key: key);

  int _getInitialIndexFromPath(String path) {
    final cleanPath = path.toLowerCase();
    if (cleanPath.contains('predictions')) return 12;
    if (cleanPath.contains('admin/leaderboard')) return 11;
    if (cleanPath.contains('hierarchy')) return 10;
    if (cleanPath.contains('pricing')) return 9;
    if (cleanPath.contains('admin')) return 8;
    if (cleanPath.contains('profile')) return 7;
    if (cleanPath.contains('leaderboard') || cleanPath.contains('ranks')) return 6;
    if (cleanPath.contains('analytics') || cleanPath.contains('mastery')) return 5;
    if (cleanPath.contains('mistakes') || cleanPath.contains('bookmarks')) return 4;
    if (cleanPath.contains('pyq') || cleanPath.contains('nta')) return 3;
    if (cleanPath.contains('tests') || cleanPath.contains('mock')) return 2;
    if (cleanPath.contains('practice')) return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentPath = Uri.base.path;
    final initialIdx = _getInitialIndexFromPath(currentPath);

    return MaterialApp(
      title: 'Cosmyra Edu - NEET & JEE Exam Platform',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      initialRoute: currentPath.isEmpty || currentPath == '/' ? '/' : currentPath,
      routes: {
        '/': (context) => MainNavigationScreen(initialIndex: initialIdx),
        '/landing': (context) => const MainNavigationScreen(initialIndex: 0),
        '/signup': (context) => const SignUpScreen(),
        '/login': (context) => const LoginScreen(),
        '/practice': (context) => const MainNavigationScreen(initialIndex: 1),
        '/tests': (context) => const MainNavigationScreen(initialIndex: 2),
        '/mock-tests': (context) => const MainNavigationScreen(initialIndex: 2),
        '/pyq': (context) => const MainNavigationScreen(initialIndex: 3),
        '/mistakes': (context) => const MainNavigationScreen(initialIndex: 4),
        '/bookmarks': (context) => const MainNavigationScreen(initialIndex: 4),
        '/analytics': (context) => const MainNavigationScreen(initialIndex: 5),
        '/leaderboard': (context) => const MainNavigationScreen(initialIndex: 6),
        '/profile': (context) => const MainNavigationScreen(initialIndex: 7),
        '/admin': (context) => const MainNavigationScreen(initialIndex: 8),
        '/admin/pricing': (context) => const MainNavigationScreen(initialIndex: 9),
        '/pricing': (context) => const MainNavigationScreen(initialIndex: 9),
        '/admin/hierarchy': (context) => const MainNavigationScreen(initialIndex: 10),
        '/hierarchy': (context) => const MainNavigationScreen(initialIndex: 10),
        '/admin/leaderboard': (context) => const MainNavigationScreen(initialIndex: 11),
        '/admin/predictions': (context) => const MainNavigationScreen(initialIndex: 12),
        '/predictions': (context) => const MainNavigationScreen(initialIndex: 12),
      },
      onGenerateRoute: (settings) {
        final targetPath = (settings.name ?? Uri.base.path).toLowerCase();
        if (targetPath.contains('signup')) {
          return MaterialPageRoute(builder: (context) => const SignUpScreen(), settings: settings);
        }
        if (targetPath.contains('login')) {
          return MaterialPageRoute(builder: (context) => const LoginScreen(), settings: settings);
        }
        final targetIdx = _getInitialIndexFromPath(targetPath);
        return MaterialPageRoute(
          builder: (context) => MainNavigationScreen(initialIndex: targetIdx),
          settings: settings,
        );
      },
    );
  }
}
