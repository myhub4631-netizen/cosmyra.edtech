import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Wraps GoRouter's RouteInformationParser to safely handle non-HTTP/HTTPS custom scheme
/// deep links (such as `cosmyraneetjee://login-callback`).
///
/// Prevents the Dart Uri `Bad state: Origin is only applicable to schemes http and https` crash
/// that occurs in GoRouter when an absolute custom-scheme URI with empty path is evaluated.
class SafeRouteInformationParser extends RouteInformationParser<RouteMatchList> {
  final RouteInformationParser<RouteMatchList> delegate;

  SafeRouteInformationParser(this.delegate);

  @override
  Future<RouteMatchList> parseRouteInformationWithDependencies(
    RouteInformation routeInformation,
    BuildContext context,
  ) {
    RouteInformation sanitized = routeInformation;
    final uri = routeInformation.uri;

    // Check for custom non-http schemes (e.g., cosmyraneetjee, io.supabase.cosmyra)
    if (uri.scheme.isNotEmpty && uri.scheme != 'http' && uri.scheme != 'https') {
      debugPrint('[DeepLink Parser] Intercepted custom scheme URI: $uri');
      String path = uri.path;
      if (uri.host.isNotEmpty && (path.isEmpty || path == '/')) {
        path = '/${uri.host}';
      } else if (uri.host.isNotEmpty && !path.startsWith('/${uri.host}')) {
        path = '/${uri.host}$path';
      }
      if (!path.startsWith('/')) {
        path = '/$path';
      }

      final safeUri = Uri(
        path: path,
        queryParameters: uri.queryParameters.isNotEmpty ? uri.queryParameters : null,
        fragment: uri.fragment.isNotEmpty ? uri.fragment : null,
      );
      debugPrint('[DeepLink Parser] Sanitized to internal route: $safeUri');

      sanitized = RouteInformation(
        uri: safeUri,
        state: routeInformation.state,
      );
    }

    return delegate.parseRouteInformationWithDependencies(sanitized, context);
  }

  @override
  RouteInformation? restoreRouteInformation(RouteMatchList configuration) {
    return delegate.restoreRouteInformation(configuration);
  }
}
