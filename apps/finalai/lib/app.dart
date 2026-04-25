import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_ui/core_ui.dart';

import 'navigation/app_router.dart';

class FinalAIApp extends ConsumerWidget {
  const FinalAIApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'FinalAI',
      theme: AppTheme.dark,
      routerDelegate: router.routerDelegate,
      routeInformationParser: router.routeInformationParser,
      routeInformationProvider: FilteringRouteInformationProvider(
        router.routeInformationProvider,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class FilteringRouteInformationProvider extends RouteInformationProvider with ChangeNotifier {
  FilteringRouteInformationProvider(this._inner) {
    _inner.addListener(notifyListeners);
  }

  final RouteInformationProvider _inner;

  bool _isUnsupportedScheme(Uri uri) {
    final scheme = uri.scheme;
    return scheme.isNotEmpty && scheme != 'http' && scheme != 'https';
  }

  @override
  RouteInformation get value {
    final v = _inner.value;
    final uri = v.uri;
    if (_isUnsupportedScheme(uri)) {
      return RouteInformation(uri: Uri(path: '/'), state: v.state);
    }

    return v;
  }

  @override
  void routerReportsNewRouteInformation(
    RouteInformation routeInformation, {
    RouteInformationReportingType type = RouteInformationReportingType.none,
  }) {
    _inner.routerReportsNewRouteInformation(routeInformation, type: type);
  }

  @override
  void dispose() {
    _inner.removeListener(notifyListeners);
    super.dispose();
  }
}
