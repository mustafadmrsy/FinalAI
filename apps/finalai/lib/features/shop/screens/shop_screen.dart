import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../learning_path/widgets/tasks/task_helpers.dart';
import '../../stats/providers/user_stats_provider.dart';
import '../../../core/services/ad_reward_service.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/services/purchase_service.dart';

// ═══════════════════════════════════════════════════════════════
//  SHOP SCREEN — Magaza: Enerji, PDF Kredi, AI Token satin al
//  Reklam izle veya premium al
// ═══════════════════════════════════════════════════════════════

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  bool _adLoading = false;

  Future<void> _watchAd(String rewardType) async {
    setState(() => _adLoading = true);
    final earned = await AdRewardService.instance.showRewardedAd();
    if (!mounted) return;
    setState(() => _adLoading = false);

    if (!earned) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reklam yuklenemedi. Tekrar deneyin.', style: TextStyle(fontWeight: FontWeight.w700)), backgroundColor: Color(0xFFFF4B4B)),
      );
      return;
    }

    final repo = ref.read(userStatsRepositoryProvider);
    switch (rewardType) {
      case 'energy':
        await repo.rewardEnergy(amount: 3);
        break;
      case 'pdf':
        await repo.rewardPdfCredit();
        break;
      case 'ai_token':
        await repo.rewardAiTokens(amount: 2);
        break;
    }
    ref.invalidate(userStatsProvider);

    if (!mounted) return;
    final msg = switch (rewardType) {
      'energy' => '+3 Enerji kazandiniz!',
      'pdf' => '+1 PDF Kredi kazandiniz!',
      'ai_token' => '+2 AI Token kazandiniz!',
      _ => 'Odul kazandiniz!',
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w700)), backgroundColor: PxDecor.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    final px = Px.of(context);
    final statsAsync = ref.watch(userStatsProvider);

    return Scaffold(
      backgroundColor: px.bg,
      body: SafeArea(
        child: statsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => Center(child: Text('Hata olustu', style: TextStyle(color: px.text))),
          data: (stats) {
            if (stats == null) return const SizedBox.shrink();
            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              children: [
                // ── Header ──
                Row(children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(color: px.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: px.border, width: 2), boxShadow: [BoxShadow(color: px.shadow, offset: const Offset(0, 3), blurRadius: 0)]),
                      child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: px.textMuted),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Magaza', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: px.text))),
                  // Coin badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: PxDecor.goldBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: PxDecor.gold, width: 2),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.token_rounded, color: PxDecor.gold, size: 18),
                      const SizedBox(width: 4),
                      Text('${stats.aiTokens}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: PxDecor.gold)),
                    ]),
                  ),
                ]),
                const SizedBox(height: 20),

                // ── Bakiye karti ──
                _BalanceCard(stats: stats, px: px),
                const SizedBox(height: 24),

                // ── Reklam ile kazan ──
                Text('Reklam Izle & Kazan', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: px.text)),
                const SizedBox(height: 12),

                _AdRewardCard(
                  px: px,
                  icon: Icons.bolt_rounded,
                  iconColor: PxDecor.orange,
                  title: '+3 Enerji',
                  subtitle: 'Reklam izle, 3 enerji kazan',
                  color: PxDecor.orange,
                  dark: PxDecor.orangeDark,
                  loading: _adLoading,
                  onTap: () => _watchAd('energy'),
                ),
                const SizedBox(height: 10),
                _AdRewardCard(
                  px: px,
                  icon: Icons.picture_as_pdf_rounded,
                  iconColor: PxDecor.purple,
                  title: '+1 PDF Kredi',
                  subtitle: 'Reklam izle, 1 PDF ozet hakki kazan',
                  color: PxDecor.purple,
                  dark: PxDecor.purpleDark,
                  loading: _adLoading,
                  onTap: () => _watchAd('pdf'),
                ),
                const SizedBox(height: 10),
                _AdRewardCard(
                  px: px,
                  icon: Icons.auto_awesome_rounded,
                  iconColor: PxDecor.blue,
                  title: '+2 AI Token',
                  subtitle: 'Reklam izle, 2 AI token kazan',
                  color: PxDecor.blue,
                  dark: PxDecor.blueDark,
                  loading: _adLoading,
                  onTap: () => _watchAd('ai_token'),
                ),
                const SizedBox(height: 28),

                // ── Premium ──
                Text('Premium Uyelik', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: px.text)),
                const SizedBox(height: 12),
                _PremiumCard(px: px, isPremium: stats.isPremium),
                const SizedBox(height: 28),

                // ── Satin alma paketleri ──
                Text('Token Paketleri', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: px.text)),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _TokenPackCard(px: px, amount: 10, productId: ProductIds.tokenPack10, price: PurchaseService.instance.priceOf(ProductIds.tokenPack10, fallback: '29.99 TL'), color: PxDecor.blue, dark: PxDecor.blueDark, emoji: '💎')),
                  const SizedBox(width: 10),
                  Expanded(child: _TokenPackCard(px: px, amount: 30, productId: ProductIds.tokenPack30, price: PurchaseService.instance.priceOf(ProductIds.tokenPack30, fallback: '69.99 TL'), color: PxDecor.purple, dark: PxDecor.purpleDark, emoji: '👑', popular: true)),
                  const SizedBox(width: 10),
                  Expanded(child: _TokenPackCard(px: px, amount: 100, productId: ProductIds.tokenPack100, price: PurchaseService.instance.priceOf(ProductIds.tokenPack100, fallback: '149.99 TL'), color: PxDecor.gold, dark: PxDecor.goldDark, emoji: '🏆')),
                ]),
                const SizedBox(height: 24),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  BALANCE CARD — Mevcut bakiye ozeti
// ═══════════════════════════════════════════════════════════
class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.stats, required this.px});
  final dynamic stats;
  final Px px;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [px.isDark ? const Color(0xFF1A2E4A) : const Color(0xFFF0F4FF), px.isDark ? const Color(0xFF0D1B2A) : const Color(0xFFE8EEFF)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: PxDecor.blue.withAlpha(60), width: 2),
        boxShadow: [BoxShadow(color: PxDecor.blueDark.withAlpha(px.isDark ? 20 : 40), offset: const Offset(0, 4), blurRadius: 0)],
      ),
      child: Row(children: [
        Expanded(child: _BalanceItem(icon: Icons.bolt_rounded, color: PxDecor.orange, label: 'Enerji', value: '${stats.energy}/${stats.energyMax}', px: px)),
        Container(width: 1, height: 44, color: px.border.withAlpha(40)),
        Expanded(child: _BalanceItem(icon: Icons.picture_as_pdf_rounded, color: PxDecor.purple, label: 'PDF', value: '${stats.pdfCredits}', px: px)),
        Container(width: 1, height: 44, color: px.border.withAlpha(40)),
        Expanded(child: _BalanceItem(icon: Icons.auto_awesome_rounded, color: PxDecor.blue, label: 'AI Token', value: '${stats.aiTokens}', px: px)),
      ]),
    );
  }
}

class _BalanceItem extends StatelessWidget {
  const _BalanceItem({required this.icon, required this.color, required this.label, required this.value, required this.px});
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final Px px;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Icon(icon, color: color, size: 24),
      const SizedBox(height: 4),
      Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: px.text)),
      Text(label, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: px.textMuted)),
    ]);
  }
}

// ═══════════════════════════════════════════════════════════
//  AD REWARD CARD — Reklam izle karti
// ═══════════════════════════════════════════════════════════
class _AdRewardCard extends StatelessWidget {
  const _AdRewardCard({
    required this.px, required this.icon, required this.iconColor,
    required this.title, required this.subtitle, required this.color,
    required this.dark, required this.loading, required this.onTap,
  });
  final Px px;
  final IconData icon;
  final Color iconColor, color, dark;
  final String title, subtitle;
  final bool loading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : () { Haptic.light(); onTap(); },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: px.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(60), width: 2),
          boxShadow: [BoxShadow(color: dark.withAlpha(px.isDark ? 20 : 40), offset: const Offset(0, 3), blurRadius: 0)],
        ),
        child: Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withAlpha(60), width: 1.5),
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: px.text)),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: px.textMuted)),
          ])),
          const SizedBox(width: 8),
          loading
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5))
            : Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: dark.withAlpha(80), offset: const Offset(0, 3), blurRadius: 0)],
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18),
                  const SizedBox(width: 4),
                  const Text('Izle', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.white)),
                ]),
              ),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  PREMIUM CARD
// ═══════════════════════════════════════════════════════════
class _PremiumCard extends StatelessWidget {
  const _PremiumCard({required this.px, required this.isPremium});
  final Px px;
  final bool isPremium;

  @override
  Widget build(BuildContext context) {
    if (isPremium) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF1A2E4A), Color(0xFF0D1B2A)]),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: PxDecor.gold, width: 2),
          boxShadow: [BoxShadow(color: PxDecor.goldDark.withAlpha(60), offset: const Offset(0, 4), blurRadius: 0)],
        ),
        child: Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: PxDecor.goldDark, borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.diamond_rounded, color: PxDecor.gold, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Premium Aktif', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: PxDecor.gold)),
            const SizedBox(height: 2),
            Text('Sinirsiz AI & PDF erisimi', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.white.withAlpha(180))),
          ])),
          const Icon(Icons.check_circle_rounded, color: PxDecor.green, size: 28),
        ]),
      );
    }

    return GestureDetector(
      onTap: () {
        Haptic.light();
        // Premium ekranina yonlendir
        Navigator.of(context).pushNamed('/premium');
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF1A2E4A), Color(0xFF0D1B2A)]),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: PxDecor.gold, width: 2),
          boxShadow: [BoxShadow(color: PxDecor.goldDark.withAlpha(60), offset: const Offset(0, 4), blurRadius: 0)],
        ),
        child: Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: PxDecor.goldDark, borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.diamond_rounded, color: PxDecor.gold, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Premium', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: PxDecor.gold)),
            const SizedBox(height: 2),
            Text('Sinirsiz AI, PDF & 2x Enerji', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.white.withAlpha(180))),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: PxDecor.gold,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: PxDecor.goldDark.withAlpha(80), offset: const Offset(0, 3), blurRadius: 0)],
            ),
            child: const Text('Satin Al', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.white)),
          ),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  TOKEN PACK CARD
// ═══════════════════════════════════════════════════════════
class _TokenPackCard extends StatelessWidget {
  const _TokenPackCard({
    required this.px, required this.amount, required this.price,
    required this.color, required this.dark, required this.emoji,
    required this.productId,
    this.popular = false,
  });
  final Px px;
  final int amount;
  final String price;
  final String productId;
  final Color color, dark;
  final String emoji;
  final bool popular;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        Haptic.light();
        final ok = await PurchaseService.instance.buy(productId);
        if (!ok && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Satin alma baslatilamadi. Lutfen tekrar deneyin.', style: TextStyle(fontWeight: FontWeight.w700)), backgroundColor: PxDecor.blue),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        decoration: BoxDecoration(
          color: px.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: popular ? color : px.border, width: popular ? 2.5 : 2),
          boxShadow: [BoxShadow(color: (popular ? dark : px.shadow).withAlpha(popular ? 60 : 30), offset: const Offset(0, 4), blurRadius: 0)],
        ),
        child: Column(children: [
          if (popular) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
              child: const Text('POPULER', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 9, color: Colors.white, letterSpacing: 1)),
            ),
            const SizedBox(height: 6),
          ] else
            const SizedBox(height: 18),
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 6),
          Text('$amount', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: px.text)),
          Text('Token', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: px.textMuted)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: dark.withAlpha(80), offset: const Offset(0, 2), blurRadius: 0)],
            ),
            child: Center(child: Text(price, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.white))),
          ),
        ]),
      ),
    );
  }
}
