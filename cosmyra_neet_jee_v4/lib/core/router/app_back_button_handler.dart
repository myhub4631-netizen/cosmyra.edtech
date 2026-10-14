import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../services/supabase_service.dart';
import 'app_router.dart';

/// Global Messenger key for scaffold notifications if needed.
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class AppBackButtonHandler extends StatefulWidget {
  final Widget child;

  const AppBackButtonHandler({
    Key? key,
    required this.child,
  }) : super(key: key);

  /// Initialize MethodChannel listener as early as main()
  static void initialize() {
    const MethodChannel('com.cosmyra.neetjee/back_button')
        .setMethodCallHandler((call) async {
      if (call.method == 'onBackPressed') {
        return await handleBackPress();
      }
      return false;
    });
  }

  static Future<bool> handleBackPress() async {
    // 1. Check if a modal dialog, bottom sheet, or sub-route can pop on the root navigator
    final navigator = rootNavigatorKey.currentState;
    if (navigator != null && navigator.canPop()) {
      navigator.pop();
      return true; // Handled, do not exit app
    }

    // 2. Check if GoRouter has an active sub-route that can pop
    if (appRouter.canPop()) {
      appRouter.pop();
      return true; // Handled, do not exit app
    }

    // 3. Inspect current route location
    final currentPath = appRouter.routeInformationProvider.value.uri.path;

    // 4. If on an inner page (e.g. /login, /courses, /profile, /quiz, etc.),
    // navigate back to /dashboard (if authenticated) or / (if guest) instead of leaving the app.
    final isRoot = currentPath == '/' ||
        currentPath == '/dashboard' ||
        currentPath.isEmpty;

    if (!isRoot) {
      if (SupabaseService.activeUserSession != null) {
        appRouter.go('/dashboard');
      } else {
        appRouter.go('/');
      }
      return true; // Handled, do not exit app
    }

    // 5. At root (/ or /dashboard): return false to let native Android double-back toast handler run.
    return false;
  }

  @override
  State<AppBackButtonHandler> createState() => _AppBackButtonHandlerState();
}

class _AppBackButtonHandlerState extends State<AppBackButtonHandler> {
  @override
  void initState() {
    super.initState();
    AppBackButtonHandler.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        await AppBackButtonHandler.handleBackPress();
      },
      child: widget.child,
    );
  }
}

/// Custom RootBackButtonDispatcher that wraps appRouter's back button handling
/// to prevent abrupt Android OS app termination.
class SafeBackButtonDispatcher extends RootBackButtonDispatcher {
  final BackButtonDispatcher delegate;

  SafeBackButtonDispatcher(this.delegate);

  @override
  Future<bool> didPopRoute() async {
    final handled = await AppBackButtonHandler.handleBackPress();
    if (handled) return true;
    if (delegate is RootBackButtonDispatcher) {
      return (delegate as RootBackButtonDispatcher).didPopRoute();
    }
    return super.didPopRoute();
  }
}
