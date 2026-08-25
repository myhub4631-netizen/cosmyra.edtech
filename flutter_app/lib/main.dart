import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'core/theme/app_theme.dart';
import 'core/services/supabase_service.dart';
import 'features/navigation/main_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy(); // Removes # hash from Flutter Web URLs
  await SupabaseService.initialize();
  runApp(const CosmyraApp());
}

class CosmyraApp extends StatelessWidget {
  const CosmyraApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ExamPrep - Practice | Analyze | Succeed',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      initialRoute: Uri.base.path.contains('predictions')
          ? '/admin/predictions'
          : (Uri.base.path.contains('leaderboard')
              ? '/admin/leaderboard'
              : (Uri.base.path.contains('hierarchy')
                  ? '/admin/hierarchy'
                  : (Uri.base.path.contains('pricing')
                      ? '/admin/pricing'
                      : (Uri.base.path.contains('admin') ? '/admin' : '/')))),
      routes: {
        '/': (context) => const MainNavigationScreen(initialIndex: 0),
        '/landing': (context) => const MainNavigationScreen(initialIndex: 0),
        '/admin': (context) => const MainNavigationScreen(initialIndex: 8),
        '/admin/pricing': (context) => const MainNavigationScreen(initialIndex: 9),
        '/pricing': (context) => const MainNavigationScreen(initialIndex: 9),
        '/admin/hierarchy': (context) => const MainNavigationScreen(initialIndex: 10),
        '/hierarchy': (context) => const MainNavigationScreen(initialIndex: 10),
        '/admin/leaderboard': (context) => const MainNavigationScreen(initialIndex: 11),
        '/leaderboard': (context) => const MainNavigationScreen(initialIndex: 11),
        '/admin/predictions': (context) => const MainNavigationScreen(initialIndex: 12),
        '/predictions': (context) => const MainNavigationScreen(initialIndex: 12),
      },
      onUnknownRoute: (settings) => MaterialPageRoute(
        builder: (context) => MainNavigationScreen(
          initialIndex: settings.name?.contains('predictions') == true
              ? 12
              : (settings.name?.contains('leaderboard') == true
                  ? 11
                  : (settings.name?.contains('hierarchy') == true
                      ? 10
                      : (settings.name?.contains('pricing') == true
                          ? 9
                          : (settings.name?.contains('admin') == true ? 8 : 0)))),
        ),
      ),
    );
  }
}
