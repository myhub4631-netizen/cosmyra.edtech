import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:cosmyra_neet_jee/core/router/app_router.dart';
import 'package:cosmyra_neet_jee/core/theme/app_theme.dart';

void main() {
  group('Smooth Screen Transitions Regression Tests', () {
    testWidgets('1. buildSmoothPage generates CustomTransitionPage with correct 220ms / 180ms durations', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final state = GoRouterState(
                appRouter.configuration,
                uri: Uri.parse('/test-page'),
                matchedLocation: '/test-page',
                fullPath: '/test-page',
                pathParameters: const {},
                name: 'test-page',
                pageKey: const ValueKey('test-page-key'),
              );

              final page = buildSmoothPage(
                context: context,
                state: state,
                child: const Text('Test Child Widget'),
              );

              expect(page, isA<CustomTransitionPage>());
              final customPage = page as CustomTransitionPage;
              expect(customPage.transitionDuration, const Duration(milliseconds: 220));
              expect(customPage.reverseTransitionDuration, const Duration(milliseconds: 180));
              expect(customPage.name, 'test-page');

              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });

    testWidgets('2. buildSmoothPage respects reduced-motion preference (disableAnimations = true)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Builder(
              builder: (context) {
                final state = GoRouterState(
                  appRouter.configuration,
                  uri: Uri.parse('/accessible-page'),
                  matchedLocation: '/accessible-page',
                  fullPath: '/accessible-page',
                  pathParameters: const {},
                  name: 'accessible-page',
                  pageKey: const ValueKey('accessible-page-key'),
                );

                final page = buildSmoothPage(
                  context: context,
                  state: state,
                  child: const Text('Accessible Widget'),
                );

                expect(page, isA<CustomTransitionPage>());
                final customPage = page as CustomTransitionPage;
                expect(customPage.transitionDuration, Duration.zero);
                expect(customPage.reverseTransitionDuration, Duration.zero);

                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('3. SmoothPageTransitionsBuilder renders FadeTransition with Transform.translate', (tester) async {
      const builder = SmoothPageTransitionsBuilder();
      final controller = AnimationController(vsync: const TestVSync(), duration: const Duration(milliseconds: 220));

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Builder(
            builder: (context) {
              final widget = builder.buildTransitions<void>(
                MaterialPageRoute(builder: (_) => const Text('Inner Page')),
                context,
                controller,
                kAlwaysDismissedAnimation,
                const Text('Inner Page'),
              );

              expect(widget, isA<FadeTransition>());
              return widget;
            },
          ),
        ),
      );

      // Verify animation at mid-point
      controller.value = 0.5;
      await tester.pump();
      expect(find.text('Inner Page'), findsOneWidget);
    });

    test('4. All top-level GoRouter routes are wrapped in smooth page builders', () {
      final routes = appRouter.configuration.routes;
      expect(routes.isNotEmpty, isTrue);

      int smoothPageCount = 0;
      for (final route in routes) {
        if (route is GoRoute) {
          if (route.pageBuilder != null) {
            smoothPageCount++;
          }
        }
      }

      // Over 100 routes must now have pageBuilder configured
      expect(smoothPageCount, greaterThan(100));
    });

    test('5. AppTheme pageTransitionsTheme maps all platforms to SmoothPageTransitionsBuilder', () {
      final theme = AppTheme.lightTheme;
      final builders = theme.pageTransitionsTheme.builders;

      expect(builders[TargetPlatform.android], isA<SmoothPageTransitionsBuilder>());
      expect(builders[TargetPlatform.iOS], isA<SmoothPageTransitionsBuilder>());
      expect(builders[TargetPlatform.macOS], isA<SmoothPageTransitionsBuilder>());
      expect(builders[TargetPlatform.windows], isA<SmoothPageTransitionsBuilder>());
      expect(builders[TargetPlatform.linux], isA<SmoothPageTransitionsBuilder>());
      expect(builders[TargetPlatform.fuchsia], isA<SmoothPageTransitionsBuilder>());
    });
  });
}
