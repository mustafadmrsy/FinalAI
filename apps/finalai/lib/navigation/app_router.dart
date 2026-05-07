import 'dart:async';

import 'package:core_ui/core_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/services/supabase_service.dart';
import '../core/ui/widgets/pixel_nav_icons.dart';
import '../features/auth/screens/auth_screen.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/home/screens/home_screen.dart';
import '../features/pdf_upload/screens/pdf_upload_screen.dart';
import '../features/pdf_upload/screens/ai_processing_screen.dart';
import '../features/ai_result/screens/ai_result_screen.dart';
import '../features/quiz/screens/quiz_screen.dart';
import '../features/quiz/screens/quiz_list_screen.dart';
import '../features/stats/screens/stats_screen.dart';
import '../features/premium/screens/premium_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/learning_path/providers/learning_path_providers.dart';
import '../features/learning_path/screens/onboarding_screen.dart';
import '../features/learning_path/screens/learning_path_screen.dart';
import '../features/learning_path/screens/unit_detail_screen.dart';
import '../features/learning_path/screens/lesson_screen.dart';
import '../features/stats/screens/achievements_screen.dart';
import '../features/learning_path/widgets/tasks/task_helpers.dart';
import '../core/ui/widgets/pixel_menu_icons.dart';
import '../core/ui/widgets/pixel_confirm_dialog.dart';
import '../core/services/haptic_service.dart';
import '../features/notifications/screens/notifications_screen.dart';
import '../features/notifications/providers/notification_provider.dart';
import '../core/ui/widgets/pixel_loading_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authStateChanges = SupabaseService.authStateChanges;

  return GoRouter(
    initialLocation: '/home',
    refreshListenable: GoRouterRefreshStream(authStateChanges),
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isLoggedIn = session != null;
      final isAuthRoute = state.matchedLocation == '/auth';

      if (!isLoggedIn) {
        return isAuthRoute ? null : '/auth';
      }

      if (isAuthRoute) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/auth', builder: (_, __) => const AuthScreen()),
      ShellRoute(
        builder: (context, state, child) => OnboardingGate(child: MainShell(child: child)),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/upload', builder: (_, __) => const PdfUploadScreen()),
          GoRoute(path: '/ai-processing', builder: (_, __) => const AiProcessingScreen()),
          GoRoute(
            path: '/result/:id',
            builder: (_, state) => AiResultScreen(noteId: state.pathParameters['id']!),
          ),
          GoRoute(path: '/quiz', builder: (_, __) => const QuizListScreen()),
          GoRoute(
            path: '/quiz/:id',
            builder: (_, state) => QuizScreen(noteId: state.pathParameters['id']!),
          ),
          GoRoute(path: '/path', builder: (_, __) => const LearningPathScreen()),
          GoRoute(
            path: '/path/unit/:index',
            builder: (_, state) => UnitDetailScreen(unitIndex: int.parse(state.pathParameters['index']!)),
          ),
          GoRoute(
            path: '/path/unit/:index/lesson/:lessonIndex',
            builder: (_, state) => LessonScreen(
              unitIndex: int.parse(state.pathParameters['index']!),
              lessonIndex: int.parse(state.pathParameters['lessonIndex']!),
            ),
          ),
          GoRoute(path: '/stats', pageBuilder: (_, __) => _pxPage(const StatsScreen())),
          GoRoute(path: '/premium', pageBuilder: (_, __) => _pxPage(const PremiumScreen())),
          GoRoute(path: '/profile', pageBuilder: (_, __) => _pxPage(const ProfileScreen())),
          GoRoute(path: '/achievements', pageBuilder: (_, __) => _pxPage(const AchievementsScreen())),
        ],
      ),
    ],
  );
});

// ── Custom page transition with fade+slide ──
CustomTransitionPage<void> _pxPage(Widget child) {
  return CustomTransitionPage(
    child: child,
    transitionDuration: const Duration(milliseconds: 250),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: SlideTransition(
          position: Tween(begin: const Offset(0, 0.04), end: Offset.zero)
              .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: child,
        ),
      );
    },
  );
}

class OnboardingGate extends ConsumerWidget {
  const OnboardingGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboarded = ref.watch(onboardingCompletedProvider);
    return onboarded.when(
      loading: () => const PixelLoadingScreen(message: 'Yukleniyor...'),
      error: (_, __) => const OnboardingScreen(),
      data: (done) => done ? child : const OnboardingScreen(),
    );
  }
}

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final tabIndex = _locationToIndex(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: _DuoNavBar(
        currentIndex: tabIndex,
        onTap: (i) => _onTap(context, i),
      ),
    );
  }

  int _locationToIndex(String location) {
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/upload')) return 1;
    if (location.startsWith('/path')) return 2;
    // Profile and sub-pages keep index 3 but don't highlight
    if (location.startsWith('/profile')) return 3;
    if (location.startsWith('/stats')) return 3;
    if (location.startsWith('/quiz')) return 3;
    if (location.startsWith('/achievements')) return 3;
    if (location.startsWith('/premium')) return 3;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    const routes = ['/home', '/upload', '/path'];
    if (index < 3) {
      context.go(routes[index]);
    }
    // index == 3 is handled by the dropdown in _DuoNavBar
  }
}

class _DuoNavBar extends StatelessWidget {
  const _DuoNavBar({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final safeBottom = MediaQuery.of(context).padding.bottom;

    final tabs = <({Widget Function({double size, bool active}) iconBuilder, String label, Color color})>[
      (iconBuilder: PixelNavIcons.home, label: 'Ana Sayfa', color: const Color(0xFF58CC02)),
      (iconBuilder: PixelNavIcons.documents, label: 'Belgeler', color: const Color(0xFFCE82FF)),
      (iconBuilder: PixelNavIcons.path, label: 'Ogren', color: const Color(0xFF1CB0F6)),
    ];

    return Container(
      padding: EdgeInsets.fromLTRB(AppSpacing.md, 6, AppSpacing.md, 6 + safeBottom),
      decoration: const BoxDecoration(color: Colors.transparent),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 3 normal tabs
          ...List.generate(tabs.length, (i) {
            final item = tabs[i];
            final selected = i == currentIndex;
            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () { Haptic.light(); onTap(i); },
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: selected ? 1 : 0),
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutBack,
                  builder: (context, t, _) {
                    final lift = -4.0 * t;
                    final scale = 1.0 + (0.06 * t);
                    final iconColor = Color.lerp(theme.colorScheme.onSurface.withOpacity(0.55), item.color, t)!;
                    final textColor = Color.lerp(theme.colorScheme.onSurface.withOpacity(0.55), item.color, t)!;
                    return Transform.translate(
                      offset: Offset(0, lift),
                      child: Transform.scale(
                        scale: scale,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              item.iconBuilder(size: 26, active: selected),
                              const SizedBox(height: 4),
                              Text(item.label, maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: AppTypography.labelMedium.copyWith(color: textColor, fontWeight: FontWeight.w900)),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          }),
          // Profile dropdown tab
          Expanded(
            child: _ProfileDropdownButton(
              isActive: currentIndex == 3,
              theme: theme,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  PROFILE DROPDOWN — Upward popup menu from nav bar
// ═══════════════════════════════════════════════════════════
class _ProfileDropdownButton extends ConsumerWidget {
  const _ProfileDropdownButton({required this.isActive, required this.theme});
  final bool isActive;
  final ThemeData theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const profileColor = Color(0xFFFF6FAE);
    final baseColor = theme.colorScheme.onSurface.withOpacity(0.55);
    final iconColor = isActive ? profileColor : baseColor;
    final textColor = isActive ? profileColor : baseColor;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () { Haptic.light(); _showProfileMenu(context, ref); },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PixelNavIcons.menu(size: 26, active: isActive),
            const SizedBox(height: 4),
            Text('Menu', maxLines: 1, overflow: TextOverflow.ellipsis,
              style: AppTypography.labelMedium.copyWith(color: textColor, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }

  void _showProfileMenu(BuildContext context, WidgetRef ref) {
    final px = Px.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _ProfileMenuSheet(px: px, parentContext: context),
    );
  }
}

class _ProfileMenuSheet extends ConsumerWidget {
  const _ProfileMenuSheet({required this.px, required this.parentContext});
  final Px px;
  final BuildContext parentContext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadCountProvider).valueOrNull ?? 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: px.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: px.border, width: 2),
        boxShadow: [BoxShadow(color: px.shadow, offset: const Offset(0, 4), blurRadius: 0)],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle
        const SizedBox(height: 12),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: px.border, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        // Menu items — pixel art icons
        _buildPixelItem(context, ref, 'Profilim', PixelMenuIcons.profile(), '/profile'),
        _buildPixelItem(context, ref, 'Bildirimler', PixelMenuIcons.notifications(unreadCount: unread), '_notifications', badge: unread),
        _buildPixelItem(context, ref, 'Istatistik', PixelMenuIcons.stats(), '/stats'),
        _buildPixelItem(context, ref, 'Quiz Coz', PixelMenuIcons.quiz(), '/quiz'),
        _buildPixelItem(context, ref, 'Basarimlar', PixelMenuIcons.achievements(), '/achievements'),
        _buildPixelItem(context, ref, 'Premium', PixelMenuIcons.premium(), '/premium'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Divider(height: 1, color: px.border),
        ),
        _buildPixelItem(context, ref, 'Cikis Yap', PixelMenuIcons.signout(), '_signout'),
        SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
      ]),
    );
  }

  Widget _buildPixelItem(BuildContext context, WidgetRef ref, String label, Widget icon, String route, {int badge = 0}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        Haptic.light();
        if (route == '_signout') {
          final authNotifier = ref.read(authProvider.notifier);
          Navigator.of(context).pop();
          final confirmed = await PixelConfirmDialog.show(
            parentContext,
            icon: Icons.logout_rounded,
            iconColor: PxDecor.red,
            title: 'Cikis Yap?',
            message: 'Hesabindan cikis yapmak istediginize emin misiniz?',
            confirmLabel: 'Cikis Yap',
            cancelLabel: 'Iptal',
            confirmColor: PxDecor.red,
            confirmDark: PxDecor.redDark,
          );
          if (confirmed) {
            authNotifier.signOut();
          }
          return;
        }
        Navigator.of(context).pop();
        if (route == '_notifications') {
          Navigator.of(parentContext).push(MaterialPageRoute(builder: (_) => const NotificationsScreen()));
        } else {
          parentContext.go(route);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          icon,
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: px.text))),
          if (badge > 0) Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            margin: const EdgeInsets.only(right: 6),
            decoration: BoxDecoration(color: PxDecor.red, borderRadius: BorderRadius.circular(10)),
            child: Text('$badge', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11)),
          ),
          Icon(Icons.chevron_right_rounded, color: px.textMuted, size: 20),
        ]),
      ),
    );
  }
}

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
