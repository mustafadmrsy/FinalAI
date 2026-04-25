# FinalAI — Windsurf Mega Prompt
# Kopyala → Windsurf'e yapıştır → Çalıştır

---

## GÖREV

Flutter ile "FinalAI" adında bir öğrenci sınav hazırlık uygulaması geliştir.
Ama önce yeniden kullanılabilir bir **design system + core altyapı** kur.
Bu altyapı başka Flutter projelerine de taşınabilir olmalı.

---

## MİMARİ: KLASÖR YAPISI

Aşağıdaki klasör yapısını EKSIKSIZ oluştur:

```
finalai/
├── packages/
│   └── core_ui/                        ← Başka projelerde de kullanılacak
│       └── lib/
│           ├── core_ui.dart            ← Barrel export (hepsini tek yerden export eder)
│           ├── tokens/
│           │   ├── app_colors.dart
│           │   ├── app_typography.dart
│           │   ├── app_spacing.dart
│           │   └── app_radius.dart
│           ├── theme/
│           │   └── app_theme.dart
│           └── widgets/
│               ├── buttons/
│               │   ├── primary_button.dart
│               │   └── ghost_button.dart
│               ├── cards/
│               │   └── base_card.dart
│               ├── inputs/
│               │   └── app_text_field.dart
│               └── feedback/
│                   ├── loading_indicator.dart
│                   └── empty_state.dart
│
└── apps/
    └── finalai/                        ← Ana uygulama
        ├── pubspec.yaml
        └── lib/
            ├── main.dart
            ├── app.dart
            ├── core/
            │   ├── constants/
            │   │   └── app_constants.dart
            │   ├── services/
            │   │   ├── gemini_service.dart
            │   │   ├── supabase_service.dart
            │   │   └── storage_service.dart
            │   └── utils/
            │       └── extensions.dart
            ├── features/
            │   ├── auth/
            │   │   ├── screens/
            │   │   │   └── auth_screen.dart
            │   │   └── providers/
            │   │       └── auth_provider.dart
            │   ├── home/
            │   │   ├── screens/
            │   │   │   └── home_screen.dart
            │   │   └── widgets/
            │   │       ├── quick_action_card.dart
            │   │       ├── daily_goal_card.dart
            │   │       └── recent_notes_list.dart
            │   ├── pdf_upload/
            │   │   ├── screens/
            │   │   │   └── pdf_upload_screen.dart
            │   │   └── providers/
            │   │       └── upload_provider.dart
            │   ├── ai_result/
            │   │   ├── screens/
            │   │   │   └── ai_result_screen.dart
            │   │   └── widgets/
            │   │       ├── summary_tab.dart
            │   │       ├── quiz_tab.dart
            │   │       └── flashcard_tab.dart
            │   ├── quiz/
            │   │   ├── screens/
            │   │   │   └── quiz_screen.dart
            │   │   └── providers/
            │   │       └── quiz_provider.dart
            │   ├── stats/
            │   │   └── screens/
            │   │       └── stats_screen.dart
            │   └── premium/
            │       └── screens/
            │           └── premium_screen.dart
            ├── models/
            │   ├── note_model.dart
            │   ├── quiz_model.dart
            │   └── user_model.dart
            └── navigation/
                └── app_router.dart
```

---

## ADIM 1: core_ui PACKAGE — DESIGN TOKENS

### `packages/core_ui/lib/tokens/app_colors.dart`
```dart
// Tüm renkler burada. Başka projede sadece bu dosyayı değiştirirsin.
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand
  static const primary = Color(0xFF7F77DD);
  static const primaryLight = Color(0xFFAFA9EC);
  static const primaryDark = Color(0xFF534AB7);

  // Semantic
  static const success = Color(0xFF5DCAA5);
  static const successDark = Color(0xFF0F6E56);
  static const warning = Color(0xFFEF9F27);
  static const warningDark = Color(0xFF854F0B);
  static const error = Color(0xFFE24B4A);

  // Neutral (dark theme)
  static const bg = Color(0xFF0F0F13);
  static const surface = Color(0xFF1A1A22);
  static const surfaceElevated = Color(0xFF22222E);
  static const border = Color(0xFF2A2A36);

  // Text
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFAAAAAA);
  static const textMuted = Color(0xFF555555);
}
```

### `packages/core_ui/lib/tokens/app_typography.dart`
```dart
// Font stilleri burada. Başka projede fontFamily'i değiştirirsin, boyutlar kalır.
import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  static const _base = 'Inter'; // pubspec'e ekle

  static const displayLarge = TextStyle(
    fontFamily: _base,
    fontSize: 32,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );

  static const headlineMedium = TextStyle(
    fontFamily: _base,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const titleMedium = TextStyle(
    fontFamily: _base,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static const bodyMedium = TextStyle(
    fontFamily: _base,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.6,
  );

  static const bodySmall = TextStyle(
    fontFamily: _base,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textMuted,
    height: 1.5,
  );

  static const labelMedium = TextStyle(
    fontFamily: _base,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
    letterSpacing: 0.5,
  );
}
```

### `packages/core_ui/lib/tokens/app_spacing.dart`
```dart
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
}
```

### `packages/core_ui/lib/tokens/app_radius.dart`
```dart
import 'package:flutter/material.dart';

class AppRadius {
  AppRadius._();

  static const sm = BorderRadius.all(Radius.circular(8));
  static const md = BorderRadius.all(Radius.circular(12));
  static const lg = BorderRadius.all(Radius.circular(16));
  static const xl = BorderRadius.all(Radius.circular(24));
  static const full = BorderRadius.all(Radius.circular(999));
}
```

---

## ADIM 2: core_ui PACKAGE — THEME

### `packages/core_ui/lib/theme/app_theme.dart`
```dart
import 'package:flutter/material.dart';
import '../tokens/app_colors.dart';
import '../tokens/app_typography.dart';
import '../tokens/app_radius.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.success,
      surface: AppColors.surface,
      error: AppColors.error,
    ),
    textTheme: const TextTheme(
      displayLarge: AppTypography.displayLarge,
      headlineMedium: AppTypography.headlineMedium,
      titleMedium: AppTypography.titleMedium,
      bodyMedium: AppTypography.bodyMedium,
      bodySmall: AppTypography.bodySmall,
      labelMedium: AppTypography.labelMedium,
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.md,
        side: const BorderSide(color: AppColors.border, width: 0.5),
      ),
      elevation: 0,
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: AppRadius.sm,
        borderSide: const BorderSide(color: AppColors.border, width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.sm,
        borderSide: const BorderSide(color: AppColors.border, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.sm,
        borderSide: const BorderSide(color: AppColors.primary, width: 1),
      ),
      hintStyle: AppTypography.bodyMedium,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.sm),
        textStyle: AppTypography.titleMedium,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF0D0D12),
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textMuted,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
  );
}
```

---

## ADIM 3: core_ui PACKAGE — REUSABLE WIDGETS

### `packages/core_ui/lib/widgets/buttons/primary_button.dart`
```dart
import 'package:flutter/material.dart';
import '../../tokens/app_colors.dart';
import '../../tokens/app_radius.dart';
import '../../tokens/app_typography.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.color,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? AppColors.primary,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.sm),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: Colors.white),
                    const SizedBox(width: 8),
                  ],
                  Text(label, style: AppTypography.titleMedium.copyWith(color: Colors.white)),
                ],
              ),
      ),
    );
  }
}
```

### `packages/core_ui/lib/widgets/cards/base_card.dart`
```dart
import 'package:flutter/material.dart';
import '../../tokens/app_colors.dart';
import '../../tokens/app_radius.dart';
import '../../tokens/app_spacing.dart';

class BaseCard extends StatelessWidget {
  const BaseCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.color,
    this.borderColor,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: color ?? AppColors.surface,
          borderRadius: AppRadius.md,
          border: Border.all(
            color: borderColor ?? AppColors.border,
            width: 0.5,
          ),
        ),
        child: child,
      ),
    );
  }
}
```

### `packages/core_ui/lib/widgets/inputs/app_text_field.dart`
```dart
import 'package:flutter/material.dart';
import '../../tokens/app_typography.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.onChanged,
    this.maxLines = 1,
    this.keyboardType,
    this.prefixIcon,
  });

  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final int maxLines;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(label!, style: AppTypography.labelMedium),
          const SizedBox(height: 6),
        ],
        TextField(
          controller: controller,
          onChanged: onChanged,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: AppTypography.bodyMedium,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 18) : null,
          ),
        ),
      ],
    );
  }
}
```

### `packages/core_ui/lib/widgets/feedback/loading_indicator.dart`
```dart
import 'package:flutter/material.dart';
import '../../tokens/app_colors.dart';
import '../../tokens/app_typography.dart';

class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key, this.message});
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!, style: AppTypography.bodyMedium, textAlign: TextAlign.center),
          ],
        ],
      ),
    );
  }
}
```

### `packages/core_ui/lib/core_ui.dart` — BARREL EXPORT
```dart
// Başka projede sadece şunu import edersin:
// import 'package:core_ui/core_ui.dart';

export 'tokens/app_colors.dart';
export 'tokens/app_typography.dart';
export 'tokens/app_spacing.dart';
export 'tokens/app_radius.dart';
export 'theme/app_theme.dart';
export 'widgets/buttons/primary_button.dart';
export 'widgets/buttons/ghost_button.dart';
export 'widgets/cards/base_card.dart';
export 'widgets/inputs/app_text_field.dart';
export 'widgets/feedback/loading_indicator.dart';
export 'widgets/feedback/empty_state.dart';
```

---

## ADIM 4: ANA UYGULAMA

### `apps/finalai/pubspec.yaml`
```yaml
name: finalai
description: FinalAI - Sınavlara akıllı hazırlan

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # Design System (yerel package)
  core_ui:
    path: ../../packages/core_ui

  # State Management
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5

  # Navigation
  go_router: ^13.2.0

  # Supabase (auth + db + storage)
  supabase_flutter: ^2.5.3

  # PDF
  file_picker: ^8.0.3
  syncfusion_flutter_pdf: ^25.1.35   # PDF okuma (ücretsiz community)

  # AI
  google_generative_ai: ^0.4.3       # Gemini API

  # Utils
  intl: ^0.19.0
  shared_preferences: ^2.2.3

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.9
  riverpod_generator: ^2.4.3
  flutter_lints: ^3.0.0
```

### `apps/finalai/lib/main.dart`
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:core_ui/core_ui.dart';
import 'core/constants/app_constants.dart';
import 'navigation/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );

  runApp(const ProviderScope(child: FinalAIApp()));
}

class FinalAIApp extends ConsumerWidget {
  const FinalAIApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'FinalAI',
      theme: AppTheme.dark,        // core_ui'den geliyor
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
```

### `apps/finalai/lib/core/constants/app_constants.dart`
```dart
class AppConstants {
  AppConstants._();

  // Supabase — .env dosyasından veya buradan yönet
  static const supabaseUrl = 'YOUR_SUPABASE_URL';
  static const supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';

  // Gemini
  static const geminiApiKey = 'YOUR_GEMINI_API_KEY';
  static const geminiModel = 'gemini-1.5-flash'; // ücretsiz tier

  // App
  static const appName = 'FinalAI';
  static const freeUploadLimit = 3; // günlük ücretsiz PDF limiti
  static const premiumPrice = '₺69';
}
```

### `apps/finalai/lib/core/services/gemini_service.dart`
```dart
import 'package:google_generative_ai/google_generative_ai.dart';
import '../constants/app_constants.dart';

class GeminiService {
  static final _model = GenerativeModel(
    model: AppConstants.geminiModel,
    apiKey: AppConstants.geminiApiKey,
  );

  // PDF bytes → özet, sorular, flashcard tek istekte
  static Future<Map<String, dynamic>> processPdf(List<int> pdfBytes) async {
    final prompt = '''
Sen bir sınav hazırlık asistanısın. Türkçe yanıt ver.

Bu PDF'i analiz et ve aşağıdaki JSON formatında SADECE JSON döndür, başka hiçbir şey yazma:

{
  "summary_short": ["madde1", "madde2", "madde3", "madde4", "madde5"],
  "summary_long": "konunun detaylı açıklaması",
  "questions": [
    {
      "question": "soru metni",
      "options": ["A) ...", "B) ...", "C) ...", "D) ..."],
      "correct_index": 1,
      "explanation": "neden bu cevap doğru"
    }
  ],
  "flashcards": [
    {"front": "kavram", "back": "açıklama"}
  ],
  "likely_exam_questions": ["olası sınav sorusu 1", "olası sınav sorusu 2"]
}

10 soru ve 10 flashcard üret.
''';

    final response = await _model.generateContent([
      Content.multi([
        DataPart('application/pdf', pdfBytes),
        TextPart(prompt),
      ])
    ]);

    final text = response.text ?? '{}';
    // JSON parse — gemini_service'in altında parse et
    return _parseJson(text);
  }

  // Çalışma planı oluştur
  static Future<String> generateStudyPlan({
    required String subject,
    required int daysLeft,
    required List<String> topics,
  }) async {
    final prompt = '''
Öğrenci için Türkçe çalışma planı oluştur.
Ders: $subject
Kalan gün: $daysLeft
Konular: ${topics.join(', ')}

Gün gün plan yap. JSON formatında döndür:
{
  "days": [
    {"day": 1, "tasks": ["görev1", "görev2"], "focus": "konu adı"},
    ...
  ],
  "tip": "motivasyon mesajı"
}
''';

    final response = await _model.generateContent([Content.text(prompt)]);
    return response.text ?? '';
  }

  static Map<String, dynamic> _parseJson(String text) {
    try {
      // Markdown kod bloğu varsa temizle
      final clean = text
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();
      // dart:convert ile parse
      import 'dart:convert';
      return jsonDecode(clean) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }
}
```

### `apps/finalai/lib/navigation/app_router.dart`
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/screens/auth_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/pdf_upload/screens/pdf_upload_screen.dart';
import '../features/ai_result/screens/ai_result_screen.dart';
import '../features/quiz/screens/quiz_screen.dart';
import '../features/stats/screens/stats_screen.dart';
import '../features/premium/screens/premium_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(path: '/auth', builder: (_, __) => const AuthScreen()),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/upload', builder: (_, __) => const PdfUploadScreen()),
          GoRoute(path: '/result/:id', builder: (_, state) =>
            AiResultScreen(noteId: state.pathParameters['id']!)),
          GoRoute(path: '/quiz/:id', builder: (_, state) =>
            QuizScreen(noteId: state.pathParameters['id']!)),
          GoRoute(path: '/stats', builder: (_, __) => const StatsScreen()),
          GoRoute(path: '/premium', builder: (_, __) => const PremiumScreen()),
        ],
      ),
    ],
  );
});

// Bottom navigation shell
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
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Ana Sayfa'),
          BottomNavigationBarItem(icon: Icon(Icons.description_outlined), activeIcon: Icon(Icons.description), label: 'Belgelerim'),
          BottomNavigationBarItem(icon: Icon(Icons.psychology_outlined), activeIcon: Icon(Icons.psychology), label: 'Quiz'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart_outlined), activeIcon: Icon(Icons.bar_chart), label: 'İstatistik'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  int _locationToIndex(String location) {
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/upload')) return 1;
    if (location.startsWith('/quiz')) return 2;
    if (location.startsWith('/stats')) return 3;
    return 0;
  }

  void _onTap(BuildContext context, int index) {
    const routes = ['/home', '/upload', '/quiz', '/stats', '/home'];
    context.go(routes[index]);
  }
}
```

### `apps/finalai/lib/features/pdf_upload/providers/upload_provider.dart`
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/gemini_service.dart';
import '../../../core/services/supabase_service.dart';

enum UploadState { idle, picking, uploading, processing, done, error }

class UploadNotifier extends StateNotifier<UploadState> {
  UploadNotifier() : super(UploadState.idle);

  String? resultId;
  String? errorMessage;

  Future<void> uploadPdf(List<int> bytes, String fileName, String subject) async {
    try {
      state = UploadState.uploading;
      // 1. Supabase storage'a yükle
      final path = await SupabaseService.uploadPdf(bytes, fileName);

      state = UploadState.processing;
      // 2. Gemini'ye gönder
      final result = await GeminiService.processPdf(bytes);

      // 3. Supabase DB'ye kaydet
      resultId = await SupabaseService.saveNote(
        subject: subject,
        filePath: path,
        summary: result,
      );

      state = UploadState.done;
    } catch (e) {
      errorMessage = e.toString();
      state = UploadState.error;
    }
  }
}

final uploadProvider = StateNotifierProvider<UploadNotifier, UploadState>(
  (ref) => UploadNotifier(),
);
```

---

## ADIM 5: SUPABASE TABLO YAPISI

Supabase dashboard'unda şu SQL'i çalıştır:

```sql
-- Kullanıcı notları
create table notes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null,
  subject text not null,
  exam_type text default 'final',
  file_path text,
  summary_short jsonb,
  summary_long text,
  questions jsonb,
  flashcards jsonb,
  created_at timestamptz default now()
);

-- Kullanıcı istatistikleri
create table user_stats (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users not null unique,
  total_pdfs int default 0,
  total_questions_answered int default 0,
  correct_answers int default 0,
  study_streak int default 0,
  last_study_date date,
  updated_at timestamptz default now()
);

-- Row Level Security
alter table notes enable row level security;
alter table user_stats enable row level security;

create policy "Users see own notes" on notes
  for all using (auth.uid() = user_id);

create policy "Users see own stats" on user_stats
  for all using (auth.uid() = user_id);
```

---

## KURALLAR (Windsurf'e)

1. **Her widget sadece kendi işini yapar.** İş mantığı provider'da, UI widget'ta.
2. **core_ui'den import et**, direkt renk/font yazmak yasak. Örnek: `AppColors.primary` kullan, `Color(0xFF7F77DD)` yazma.
3. **Magic string yasak.** Her sabit `AppConstants`'ta.
4. **Riverpod** state management için kullanılır. setState sadece local UI state için.
5. **go_router** ile navigate et. Navigator.push() yasak.
6. Her screen `ConsumerWidget` extend eder.
7. **Loading state'ini her zaman göster.** Gemini işlemi sırasında adım adım mesaj: "PDF okunuyor... → Konular çıkarılıyor... → Sorular hazırlanıyor..."
8. **Hata state'i** her feature'da handle edilmeli. Try-catch zorunlu.
9. Dosya isimleri `snake_case`, class isimleri `PascalCase`.
10. core_ui package'ı başka projeye taşırken sadece `AppColors` ve `AppTheme`'i değiştir, widget'lara dokunma.

---

## ŞİMDİ YAP

Yukarıdaki tüm dosyaları oluştur. Sonra şu sırayla implement et:

1. `core_ui` package — tüm token ve widget dosyaları
2. `pubspec.yaml` ve `main.dart`
3. `app_router.dart`
4. `auth_screen.dart` — Google ile giriş (Supabase)
5. `home_screen.dart` — Quick actions, daily goal, recent notes
6. `pdf_upload_screen.dart` — Dosya seç + kamera
7. `upload_provider.dart` + `gemini_service.dart`
8. `ai_result_screen.dart` — 3 sekme: özet, quiz, flashcard
9. `quiz_screen.dart` — Çoktan seçmeli + skor
10. `stats_screen.dart` — Streak, başarı oranı
11. `premium_screen.dart`

Her adımda hata alırsan bir sonraki adıma geçme, önce düzelt.