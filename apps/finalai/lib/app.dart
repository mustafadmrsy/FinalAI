import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:core_ui/core_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'navigation/app_router.dart';
import 'core/services/theme_service.dart' show themeModeProvider;
import 'core/services/haptic_service.dart';
import 'features/notifications/services/notification_service.dart';
import 'features/notifications/providers/notification_provider.dart';
import 'features/stats/providers/user_stats_provider.dart';
import 'features/avatar/providers/avatar_provider.dart';
import 'core/services/supabase_service.dart';
import 'core/services/purchase_service.dart';

class FinalAIApp extends ConsumerStatefulWidget {
  const FinalAIApp({super.key});

  @override
  ConsumerState<FinalAIApp> createState() => _FinalAIAppState();
}

class _FinalAIAppState extends ConsumerState<FinalAIApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Bildirim izni iste (ilk acilista)
    NotificationService.requestPermission();
    // Haptic durumunu senkronize et
    final hapticEnabled = ref.read(hapticEnabledProvider);
    Haptic.init(hapticEnabled);
    // Auth degisikliginde avatar'i yenile
    _listenAuthChanges();
    // Satin alma callback'lerini bagla
    _connectPurchaseCallbacks();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      _onAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      _onAppResumed();
    }
  }

  Future<void> _onAppPaused() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      // user_stats tablosunu kontrol et
      final statsAsync = ref.read(userStatsProvider);
      final stats = statsAsync.valueOrNull;
      if (stats == null) return;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final lastActive = stats.lastActiveDate;
      final didStudyToday = lastActive != null &&
          DateTime(lastActive.year, lastActive.month, lastActive.day) == today;

      await NotificationService.onPauseCheck(
        energy: stats.energy,
        energyMax: stats.energyMax,
        lastActiveDate: stats.lastActiveDate,
        streak: stats.studyStreak ?? 0,
        didStudyToday: didStudyToday,
        streakFreezeAvailable: stats.streakFreezeAvailable,
      );
    } catch (_) {}
  }

  void _onAppResumed() {
    // Bildirimleri yenile
    ref.read(notificationsProvider.notifier).refresh();
  }

  void _connectPurchaseCallbacks() {
    final purchase = PurchaseService.instance;
    purchase.onSubscriptionPurchased = (productId) async {
      try {
        final repo = ref.read(userStatsRepositoryProvider);
        await repo.setPremium(true);
        ref.invalidate(userStatsProvider);
      } catch (_) {}
    };
    purchase.onConsumablePurchased = (productId) async {
      try {
        final repo = ref.read(userStatsRepositoryProvider);
        final tokens = ProductIds.tokensForProduct(productId);
        if (tokens > 0) await repo.rewardAiTokens(amount: tokens);
        ref.invalidate(userStatsProvider);
      } catch (_) {}
    };
  }

  void _listenAuthChanges() {
    SupabaseService.authStateChanges.listen((data) {
      // Hesap degistiginde avatar'i yeni hesaba gore yenile
      ref.read(avatarProvider.notifier).reload();
      // Hesap degistiginde kullanici istatistiklerini yenile
      ref.invalidate(userStatsProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'FinalAI',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
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

  @override
  RouteInformation get value {
    final v = _inner.value;
    final uri = v.uri;
    if (uri.scheme == 'com.finalai') {
      return RouteInformation(
        uri: Uri(path: '/auth', query: uri.query, fragment: uri.fragment),
        state: v.state,
      );
    }
    return v;
  }

  @override
  void routerReportsNewRouteInformation(
    RouteInformation routeInformation, {
    RouteInformationReportingType type = RouteInformationReportingType.none,
  }) {
    final uri = routeInformation.uri;
    if (uri.scheme == 'com.finalai') {
      _inner.routerReportsNewRouteInformation(
        RouteInformation(
          uri: Uri(path: '/auth', query: uri.query, fragment: uri.fragment),
          state: routeInformation.state,
        ),
        type: type,
      );
      return;
    }
    _inner.routerReportsNewRouteInformation(routeInformation, type: type);
  }

  @override
  void dispose() {
    _inner.removeListener(notifyListeners);
    super.dispose();
  }
}
