import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/auth/screens/auth_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/pdf_upload/screens/pdf_upload_screen.dart';
import '../features/pdf_upload/screens/ai_processing_screen.dart';
import '../features/ai_result/screens/ai_result_screen.dart';
import '../features/quiz/screens/quiz_screen.dart';
import '../features/quiz/screens/quiz_list_screen.dart';
import '../features/stats/screens/stats_screen.dart';
import '../features/premium/screens/premium_screen.dart';
import '../features/profile/screens/profile_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authStateChanges = Supabase.instance.client.auth.onAuthStateChange;

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
        builder: (context, state, child) => MainShell(child: child),
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
          GoRoute(path: '/stats', builder: (_, __) => const StatsScreen()),
          GoRoute(path: '/premium', builder: (_, __) => const PremiumScreen()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        ],
      ),
    ],
  );
});

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final tabIndex = _locationToIndex(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: tabIndex,
        onTap: (i) => _onTap(context, i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Ana Sayfa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.description_outlined),
            activeIcon: Icon(Icons.description),
            label: 'Belgelerim',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.psychology_outlined),
            activeIcon: Icon(Icons.psychology),
            label: 'Quiz',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'İstatistik',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  int _locationToIndex(String location) {
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/upload')) return 1;
    if (location.startsWith('/quiz')) return 2;
    if (location.startsWith('/stats')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    const routes = ['/home', '/upload', '/quiz', '/stats', '/profile'];
    context.go(routes[index]);
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
