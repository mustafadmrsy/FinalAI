import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/providers/auth_provider.dart';
import '../../../core/repositories/repository_providers.dart';
import '../../../core/constants/app_constants.dart';
import 'package:go_router/go_router.dart';
import '../../stats/providers/user_stats_provider.dart';
import '../../stats/widgets/daily_quests_popup.dart';
import '../../stats/widgets/streak_freeze_overlay.dart';
import '../../learning_path/widgets/tasks/task_helpers.dart';
import '../../learning_path/data/onboarding_options.dart';
import '../../../core/services/theme_service.dart';
import '../../../core/services/haptic_service.dart';
import '../../avatar/widgets/avatar_widget.dart';
import '../../avatar/screens/avatar_editor_screen.dart';
import '../../avatar/providers/avatar_provider.dart';
import '../../../core/ui/widgets/pixel_confirm_dialog.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  // Acilir-kapanir bolumler
  bool _achievementsOpen = false;
  bool _prefsOpen = false;
  bool _settingsOpen = false;
  bool _accountOpen = false;

  @override
  void initState() {
    super.initState();
    _checkStreakAndQuests();
  }

  Future<void> _checkStreakAndQuests() async {
    try {
      final repo = ref.read(userStatsRepositoryProvider);
      try { await repo.checkAndResetDailyQuests(); } catch (_) {}
      final result = await repo.checkAndUpdateStreak();
      ref.invalidate(userStatsProvider);
      if (!mounted) return;
      if (result == 'frozen') {
        final stats = await repo.getUserStats();
        if (mounted) StreakFreezeOverlay.show(context, type: 'frozen', streakCount: stats?.studyStreak ?? 0);
      } else if (result == 'broken') {
        if (mounted) StreakFreezeOverlay.show(context, type: 'broken', streakCount: 0);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final px = Px.of(context);
    final auth = ref.watch(authProvider);
    final user = Supabase.instance.client.auth.currentUser;
    final profile = ref.watch(_profileProvider);
    final stats = ref.watch(userStatsProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    const heroH = 320.0;
    const avatarSize = 150.0;

    return Scaffold(
      backgroundColor: px.bg,
      body: Stack(children: [
        // ── Fixed hero background — uses avatar bgColor ──
        Positioned(
          left: 0, right: 0, top: 0, height: heroH + MediaQuery.of(context).padding.top,
          child: Builder(builder: (_) {
            const bgColors = [
              PxDecor.blue, PxDecor.purple, PxDecor.teal, PxDecor.green,
              PxDecor.orange, PxDecor.red, Color(0xFF2A2A3E), Color(0xFF1A1A2E),
            ];
            final bgIdx = ref.watch(avatarProvider).bgColor.clamp(0, bgColors.length - 1);
            return Container(color: bgColors[bgIdx]);
          }),
        ),
        // ── Scrollable content overlay ──
        SafeArea(
          child: CustomScrollView(slivers: [
            // ── Duolingo-style avatar hero ──
            SliverToBoxAdapter(child: profile.when(
              loading: () => SizedBox(height: heroH, child: const Center(child: CircularProgressIndicator(color: Colors.white))),
              error: (e, _) => SizedBox(height: heroH, child: Center(child: Text('$e', style: const TextStyle(color: Colors.white)))),
              data: (p) {
                final fullName = (p?['full_name'] as String?) ?? '';
                final isPremium = (p?['is_premium'] as bool?) ?? false;
                final dailyCount = (p?['daily_upload_count'] as int?) ?? 0;
                final premiumUntil = p?['premium_until']?.toString();

                return Column(children: [
                  // ── Blue hero zone ──
                  SizedBox(
                    height: heroH,
                    child: Stack(children: [
                      // Top row: back + settings
                      Positioned(
                        left: 16, right: 16, top: 8,
                        child: Row(children: [
                          const Expanded(child: Text('Profil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22))),
                          GestureDetector(
                            onTap: () { Haptic.light(); _showEditNameDialog(context, ref, fullName); },
                            child: Container(
                              width: 36, height: 36,
                              decoration: BoxDecoration(color: Colors.white.withAlpha(30), borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.edit_rounded, color: Colors.white, size: 16),
                            ),
                          ),
                        ]),
                      ),
                      // Avatar — large, free-standing, no box, waist-up
                      Positioned.fill(
                        top: 40,
                        child: GestureDetector(
                          onTap: () {
                            Haptic.medium();
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => AvatarEditorScreen(
                                initial: ref.read(avatarProvider),
                                onSave: (a) => ref.read(avatarProvider.notifier).save(a),
                              ),
                            ));
                          },
                          child: Stack(alignment: Alignment.center, children: [
                            // Soft glow behind avatar
                            Container(
                              width: avatarSize * 1.3,
                              height: avatarSize * 1.3,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(colors: [Colors.white.withAlpha(25), Colors.transparent]),
                              ),
                            ),
                            // Avatar — big render
                            AvatarWidget(avatar: ref.watch(avatarProvider), size: avatarSize),
                            // Edit badge — bottom right of avatar
                            Positioned(
                              bottom: 10, right: 0, left: avatarSize * 0.5 + 20,
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Container(
                                  width: 34, height: 34,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: const Color(0xFF1CB0F6), width: 2.5),
                                    boxShadow: [BoxShadow(color: Colors.black.withAlpha(30), offset: const Offset(0, 2), blurRadius: 0)],
                                  ),
                                  child: const Icon(Icons.brush_rounded, color: Color(0xFF1CB0F6), size: 16),
                                ),
                              ),
                            ),
                          ]),
                        ),
                      ),
                    ]),
                  ),
                  // ── Name + email — below hero, on bg color ──
                  Container(
                    width: double.infinity,
                    color: px.bg,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(children: [
                      Text(fullName.isEmpty ? 'Ad Soyad ekle' : fullName, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: px.text), textAlign: TextAlign.center),
                      const SizedBox(height: 2),
                      Text(user?.email ?? '-', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: px.textSub), textAlign: TextAlign.center),
                      const SizedBox(height: 10),
                      // Badges
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        _infoBadge(px, isPremium ? 'Premium' : 'Ucretsiz', isPremium ? PxDecor.purple : PxDecor.teal),
                        const SizedBox(width: 8),
                        _infoBadge(px, isPremium && premiumUntil != null ? 'Bitis: $premiumUntil' : 'Gunluk: $dailyCount/${AppConstants.freeUploadLimit}', PxDecor.blue),
                      ]),
                      if (!isPremium) ...[
                        const SizedBox(height: 14),
                        GestureDetector(
                          onTap: () { Haptic.light(); context.go('/premium'); },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: px.accentBg(PxDecor.purple),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: PxDecor.purple, width: 2),
                              boxShadow: [BoxShadow(color: PxDecor.purpleDark.withAlpha(40), offset: const Offset(0, 3), blurRadius: 0)],
                            ),
                            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(Icons.workspace_premium_rounded, color: PxDecor.purple, size: 18),
                              const SizedBox(width: 8),
                              Text('Premium\'a gec', style: TextStyle(color: PxDecor.purple, fontWeight: FontWeight.w900, fontSize: 14)),
                            ]),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                    ]),
                  ),
                ]);
              },
            )),

            // ── Content sections ──
            SliverToBoxAdapter(child: Container(
              color: px.bg,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: profile.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (p) {
                  final subject = (p?['learning_subject'] as String?) ?? '';
                  final difficulty = (p?['learning_difficulty'] as String?) ?? '';
                  return Column(children: [
                    if (subject.isNotEmpty)
                      _ExpandableSection(
                        px: px, title: 'Ogrenme Tercihleri', icon: Icons.school_rounded, color: PxDecor.blue,
                        isOpen: _prefsOpen, onToggle: () { Haptic.selection(); setState(() => _prefsOpen = !_prefsOpen); },
                        child: _buildLearningPrefs(px, subject, difficulty),
                      ),
                  ]);
                },
              ),
            )),

            // ── Rest of content ──
            SliverToBoxAdapter(child: Container(
              color: px.bg,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const SizedBox(height: 4),

                // ── Gunluk Gorevler butonu ──
            stats.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (s) => s == null ? const SizedBox.shrink() : GestureDetector(
                onTap: () => DailyQuestsPopup.show(context, s),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: px.accentBg(PxDecor.teal),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: PxDecor.teal, width: 2),
                    boxShadow: [BoxShadow(color: PxDecor.teal.withAlpha(px.isDark ? 20 : 40), offset: const Offset(0, 3), blurRadius: 0)],
                  ),
                  child: Row(children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: PxDecor.teal, borderRadius: BorderRadius.circular(11)),
                      child: const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Gunluk Gorevler', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: px.text)),
                      Text('${s.dailyQuestLessons}/${s.dailyQuestLessonsGoal} ders · ${s.dailyQuestXp}/${s.dailyQuestXpGoal} XP', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: px.textSub)),
                    ])),
                    Icon(Icons.chevron_right_rounded, color: PxDecor.teal, size: 22),
                  ]),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Basarimlar (acilir-kapanir) ──
            stats.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (s) => s == null ? const SizedBox.shrink() : _ExpandableSection(
                px: px, title: 'Basarimlar', icon: Icons.emoji_events_rounded, color: PxDecor.gold,
                isOpen: _achievementsOpen, onToggle: () { Haptic.selection(); setState(() => _achievementsOpen = !_achievementsOpen); },
                child: Column(children: [
                  _buildAchievementsContent(px, s),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => context.push('/achievements'),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: PxDecor.gold,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: PxDecor.goldDark.withAlpha(60), offset: const Offset(0, 3), blurRadius: 0)],
                      ),
                      child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.emoji_events_rounded, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text('Hepsini Gor', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                      ]),
                    ),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 12),

            // ── Ayarlar (acilir-kapanir) ──
            _ExpandableSection(
              px: px, title: 'Ayarlar', icon: Icons.settings_rounded, color: PxDecor.purple,
              isOpen: _settingsOpen, onToggle: () { Haptic.selection(); setState(() => _settingsOpen = !_settingsOpen); },
              child: Column(children: [
                // Tema toggle
                _settingRow(px, isDark ? Icons.nights_stay_rounded : Icons.wb_sunny_rounded, PxDecor.teal, 'Tema', isDark ? 'Karanlik' : 'Aydinlik',
                  trailing: Switch(
                    value: isDark,
                    activeColor: PxDecor.teal,
                    onChanged: (v) { Haptic.light(); ref.read(themeModeProvider.notifier).setThemeMode(v ? ThemeMode.dark : ThemeMode.light); },
                  ),
                ),
                const SizedBox(height: 8),
                // Titresim toggle
                _settingRow(px, ref.watch(hapticEnabledProvider) ? Icons.vibration_rounded : Icons.phone_android_rounded, PxDecor.orange, 'Titresim', ref.watch(hapticEnabledProvider) ? 'Acik' : 'Kapali',
                  trailing: Switch(
                    value: ref.watch(hapticEnabledProvider),
                    activeColor: PxDecor.orange,
                    onChanged: (v) { ref.read(hapticEnabledProvider.notifier).setEnabled(v); Haptic.init(v); if (v) Haptic.medium(); },
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 12),

            // ── Hesap Yonetimi (acilir-kapanir) ──
            _ExpandableSection(
              px: px, title: 'Hesap', icon: Icons.manage_accounts_rounded, color: PxDecor.red,
              isOpen: _accountOpen, onToggle: () { Haptic.selection(); setState(() => _accountOpen = !_accountOpen); },
              child: Column(children: [
                _actionRow(px, Icons.email_rounded, PxDecor.blue, 'E-posta', user?.email ?? '-', null),
                const SizedBox(height: 8),
                _actionRow(px, Icons.lock_reset_rounded, PxDecor.gold, 'Sifre degistir', 'E-posta ile sifirla', () {
                  if (user?.email != null) {
                    ref.read(authProvider.notifier).resetPassword(user!.email!);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sifre sifirlama e-postasi gonderildi')));
                  }
                }),
                const SizedBox(height: 8),
                _actionRow(px, Icons.logout_rounded, PxDecor.orange, 'Cikis yap', 'Hesabindan cikis yap', () async {
                  if (!auth.isLoading && auth.session != null) {
                    final confirmed = await PixelConfirmDialog.show(
                      context,
                      icon: Icons.logout_rounded,
                      iconColor: PxDecor.orange,
                      title: 'Cikis Yap?',
                      message: 'Hesabindan cikis yapmak\nistediginize emin misiniz?',
                      confirmLabel: 'Cikis Yap',
                      cancelLabel: 'Iptal',
                      confirmColor: PxDecor.orange,
                      confirmDark: PxDecor.orangeDark,
                    );
                    if (confirmed) ref.read(authProvider.notifier).signOut();
                  }
                }),
                const SizedBox(height: 8),
                _actionRow(px, Icons.delete_forever_rounded, PxDecor.red, 'Hesabi sil', 'Kalici olarak sil', () => _showDeleteAccountDialog(context, ref)),
              ]),
            ),
                const SizedBox(height: 12),

                const SizedBox(height: 24),
              ]),
            )),
          ]),
        ),
      ]),
    );
  }

  static Widget _infoBadge(Px px, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: px.accentBg(color),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 11)),
    );
  }

  // ── Ogrenme Tercihleri icerigi ──
  static Widget _buildLearningPrefs(Px px, String subject, String difficulty) {
    final subItem = OnboardingOptions.subjects.where((s) => s.name == subject).firstOrNull;
    final subColor = subItem?.color ?? PxDecor.blue;
    final subIcon = subItem?.icon ?? Icons.school_rounded;

    Color diffColor;
    String diffLabel;
    IconData diffIcon;
    switch (difficulty.toLowerCase()) {
      case 'başlangıç': case 'baslangic': diffColor = PxDecor.green; diffLabel = 'Baslangic'; diffIcon = Icons.eco_rounded; break;
      case 'orta': diffColor = PxDecor.gold; diffLabel = 'Orta'; diffIcon = Icons.speed_rounded; break;
      case 'ileri': case 'ileri seviye': diffColor = PxDecor.red; diffLabel = 'Ileri'; diffIcon = Icons.whatshot_rounded; break;
      default: diffColor = PxDecor.blue; diffLabel = difficulty; diffIcon = Icons.speed_rounded;
    }

    return Column(children: [
      // Konu karti — pixel game tarz
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: px.accentBg(subColor),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: subColor, width: 2),
          boxShadow: [BoxShadow(color: subColor.withAlpha(px.isDark ? 25 : 50), offset: const Offset(0, 3), blurRadius: 0)],
        ),
        child: Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: subColor, borderRadius: BorderRadius.circular(12)),
            child: Icon(subIcon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Konu', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: px.textSub)),
            Text(subject, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: px.isDark ? subColor : subColor)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: subColor, borderRadius: BorderRadius.circular(8)),
            child: const Text('Aktif', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 11)),
          ),
        ]),
      ),
      const SizedBox(height: 10),
      // Seviye karti
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: px.accentBg(diffColor),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: diffColor, width: 2),
          boxShadow: [BoxShadow(color: diffColor.withAlpha(px.isDark ? 25 : 50), offset: const Offset(0, 3), blurRadius: 0)],
        ),
        child: Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(color: diffColor, borderRadius: BorderRadius.circular(12)),
            child: Icon(diffIcon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Seviye', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: px.textSub)),
            Text(diffLabel, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: px.isDark ? diffColor : diffColor)),
          ])),
        ]),
      ),
    ]);
  }

  // ── Basarimlar icerigi ──
  static Widget _buildAchievementsContent(Px px, dynamic s) {
    final achievements = <_Achievement>[
      _Achievement('Ilk Adim', 'Ilk dersini tamamla', Icons.flag_rounded, PxDecor.green, s.xpTotal > 0),
      _Achievement('XP Avcisi', '100 XP topla', PxIcons.xpIcon, PxIcons.xpColor, s.xpTotal >= 100),
      _Achievement('XP Ustasi', '500 XP topla', Icons.auto_awesome_rounded, PxDecor.gold, s.xpTotal >= 500),
      _Achievement('Kombo x5', '5 arka arkaya dogru', Icons.whatshot_rounded, PxDecor.purple, s.comboBest >= 5),
      _Achievement('Kombo x10', '10 arka arkaya', Icons.whatshot_rounded, PxDecor.purple, s.comboBest >= 10),
      _Achievement('Haftalik Seri', '7 gun ust uste', PxIcons.streakIcon, PxIcons.streakColor, (s.longestStreak ?? 0) >= 7),
    ];

    return Column(children: [
      Row(children: [
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: PxDecor.gold, borderRadius: BorderRadius.circular(6)),
          child: Text('${achievements.where((a) => a.done).length}/${achievements.length}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11)),
        ),
      ]),
      const SizedBox(height: 8),
      ...achievements.map((a) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: a.done ? px.accentBg(a.color) : px.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: a.done ? a.color : px.border, width: 2),
            boxShadow: [BoxShadow(color: a.done ? a.color.withAlpha(px.isDark ? 25 : 50) : px.shadow, offset: const Offset(0, 2), blurRadius: 0)],
          ),
          child: Row(children: [
            Icon(a.icon, color: a.done ? a.color : px.textMuted, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(a.title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: a.done ? px.text : px.textMuted)),
              Text(a.desc, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: a.done ? px.textSub : px.textMuted)),
            ])),
            if (a.done) const Icon(Icons.check_circle_rounded, color: PxDecor.green, size: 20)
            else Icon(Icons.lock_rounded, color: px.textMuted, size: 18),
          ]),
        ),
      )),
    ]);
  }

  // ── Ayar satiri ──
  Widget _settingRow(Px px, IconData icon, Color color, String title, String subtitle, {Widget? trailing}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: px.accentBg(color),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(px.isDark ? 40 : 80), width: 1.5),
      ),
      child: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: px.text)),
          Text(subtitle, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: px.textSub)),
        ])),
        if (trailing != null) trailing,
      ]),
    );
  }

  // ── Aksiyon satiri (hesap yonetimi) ──
  Widget _actionRow(Px px, IconData icon, Color color, String title, String subtitle, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: px.accentBg(color),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(px.isDark ? 40 : 80), width: 1.5),
        ),
        child: Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: px.text)),
            Text(subtitle, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: px.textSub)),
          ])),
          if (onTap != null) Icon(Icons.chevron_right_rounded, color: px.textMuted, size: 20),
        ]),
      ),
    );
  }

  Future<void> _showDeleteAccountDialog(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final px = Px.of(ctx);
        return AlertDialog(
          backgroundColor: px.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: PxDecor.red, width: 2)),
          title: Row(children: [
            const Icon(Icons.warning_rounded, color: PxDecor.red, size: 22),
            const SizedBox(width: 8),
            Text('Hesabi Sil', style: TextStyle(fontWeight: FontWeight.w900, color: px.text)),
          ]),
          content: Text('Bu islem geri alinamaz. Tum verileriniz silinecek.', style: TextStyle(color: px.textSub)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Iptal', style: TextStyle(color: px.textSub))),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sil', style: TextStyle(color: PxDecor.red, fontWeight: FontWeight.w800))),
          ],
        );
      },
    );
    if (confirm == true) {
      await ref.read(authProvider.notifier).deleteAccount();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Hesabin ve tum verilerin silindi')));
    }
  }
}

// ═══════════════════════════════════════════════════
//  Acilir-Kapanir Bolum Widget
// ═══════════════════════════════════════════════════
class _ExpandableSection extends StatelessWidget {
  const _ExpandableSection({
    required this.px, required this.title, required this.icon,
    required this.color, required this.isOpen, required this.onToggle,
    required this.child,
  });
  final Px px;
  final String title;
  final IconData icon;
  final Color color;
  final bool isOpen;
  final VoidCallback onToggle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: px.sectionDeco(),
      child: Column(children: [
        GestureDetector(
          onTap: onToggle,
          child: Container(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: px.text))),
              AnimatedRotation(
                turns: isOpen ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(Icons.keyboard_arrow_down_rounded, color: px.textMuted, size: 24),
              ),
            ]),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity),
          secondChild: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: child,
          ),
          crossFadeState: isOpen ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ]),
    );
  }
}

class _Achievement {
  const _Achievement(this.title, this.desc, this.icon, this.color, this.done);
  final String title, desc;
  final IconData icon;
  final Color color;
  final bool done;
}

final _profileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  // Auth degistiginde (hesap degisimi) otomatik yeniden yukle
  ref.watch(authProvider);
  return ref.watch(statsRepositoryProvider).getUserProfile();
});

Future<void> _showEditNameDialog(BuildContext context, WidgetRef ref, String current) async {
  final px = Px.of(context);
  final controller = TextEditingController(text: current);
  final formKey = GlobalKey<FormState>();

  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: px.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: px.border, width: 2)),
      title: Text('Ad Soyad', style: TextStyle(fontWeight: FontWeight.w900, color: px.text)),
      content: Form(key: formKey, child: TextFormField(controller: controller, style: TextStyle(color: px.text), decoration: InputDecoration(hintText: 'Orn: Ali Veli', hintStyle: TextStyle(color: px.textMuted)), validator: (v) => (v == null || v.trim().isEmpty) ? 'Bos olamaz' : null)),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: Text('Iptal', style: TextStyle(color: px.textSub))),
        TextButton(onPressed: () { if (formKey.currentState?.validate() != true) return; Navigator.of(context).pop(controller.text.trim()); }, child: const Text('Kaydet', style: TextStyle(color: PxDecor.teal, fontWeight: FontWeight.w800))),
      ],
    ),
  );

  if (result == null) return;
  await ref.read(statsRepositoryProvider).updateUserProfile(fullName: result);
  ref.invalidate(_profileProvider);
}

