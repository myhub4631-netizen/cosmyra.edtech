import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'core/theme/app_theme.dart';
import 'core/services/supabase_service.dart';
import 'core/services/crash_analytics_service.dart';
import 'core/router/app_router.dart';
import 'firebase_options.dart';

import 'core/router/safe_route_parser.dart';
import 'core/router/app_back_button_handler.dart';
import 'core/services/seo_tracking_service.dart';

import 'core/services/feature_config_service.dart';
import 'core/services/platform_time_tracker_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy(); // Removes # hash from Flutter Web URLs
  AppBackButtonHandler.initialize();

  // Fast client & local cached session initialization (< 60ms)
  await SupabaseService.initialize();

  // Instantly render application shell and first useful frame
  runApp(const CosmyraApp());

  // Concurrently run secondary and non-essential background initializations
  _initializeBackgroundServices();
}

void _initializeBackgroundServices() {
  Future.wait([
    CrashAnalyticsService.initialize(
      options: DefaultFirebaseOptions.currentPlatform,
    ),
    PlatformTimeTrackerService.initialize(),
    FeatureConfigService.init(),
    SeoTrackingService.initialize(),
  ]).catchError((e) {
    debugPrint('Background services initialization notice: $e');
    return <void>[];
  });
}

class CosmyraApp extends StatelessWidget {
  const CosmyraApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Cosmyra Neet Jee',
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      routeInformationParser: SafeRouteInformationParser(appRouter.routeInformationParser),
      routeInformationProvider: appRouter.routeInformationProvider,
      routerDelegate: appRouter.routerDelegate,
      backButtonDispatcher: SafeBackButtonDispatcher(appRouter.backButtonDispatcher),
      builder: (context, child) {
        return AppBackButtonHandler(
          child: SelectionArea(
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
