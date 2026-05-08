import 'package:flutter/material.dart';

import '../../learning_path/widgets/tasks/task_helpers.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/services/purchase_service.dart';

// ═══════════════════════════════════════════════════════════════
//  PREMIUM SCREEN — 2D Pixel Game Art Style
//  3 tiers: Gumus (Silver), Altin (Gold), Elmas (Diamond)
// ═══════════════════════════════════════════════════════════════

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  int _selectedTier = 1; // 0=silver, 1=gold, 2=diamond

  @override
  Widget build(BuildContext context) {
    final px = Px.of(context);

    return Scaffold(
      backgroundColor: px.bg,
      body: SafeArea(
        child: ListView(
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
              Expanded(child: Text('Premium', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: px.text))),
            ]),
            const SizedBox(height: 20),

            // ── Hero card ──
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF1A2E4A), Color(0xFF0D1B2A)]),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: PxDecor.gold, width: 3),
                boxShadow: [BoxShadow(color: PxDecor.goldDark, offset: const Offset(0, 6), blurRadius: 0)],
              ),
              child: Column(children: [
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: PxDecor.goldDark,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: PxDecor.gold, width: 3),
                    boxShadow: [BoxShadow(color: Colors.black.withAlpha(40), offset: const Offset(0, 4), blurRadius: 0)],
                  ),
                  child: Stack(children: [
                    Positioned(top: 4, left: 4, child: Container(width: 18, height: 8, decoration: BoxDecoration(color: Colors.white.withAlpha(30), borderRadius: BorderRadius.circular(4)))),
                    const Center(child: Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 40)),
                  ]),
                ),
                const SizedBox(height: 14),
                const Text('FinalAI Premium', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24)),
                const SizedBox(height: 6),
                Text('Ogrenme macerani ust seviyeye tasi!', style: TextStyle(color: Colors.white.withAlpha(180), fontWeight: FontWeight.w600, fontSize: 14)),
              ]),
            ),
            const SizedBox(height: 24),

            // ── Tier selector ──
            Text('Plan Sec', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: px.text)),
            const SizedBox(height: 14),

            Row(children: [
              Expanded(child: _tierTab(px, 0, 'Gumus', Icons.shield_rounded, const Color(0xFFA0AEC0), const Color(0xFF718096))),
              const SizedBox(width: 8),
              Expanded(child: _tierTab(px, 1, 'Altin', Icons.workspace_premium_rounded, PxDecor.gold, PxDecor.goldDark)),
              const SizedBox(width: 8),
              Expanded(child: _tierTab(px, 2, 'Elmas', Icons.diamond_rounded, const Color(0xFF63B3ED), const Color(0xFF3182CE))),
            ]),
            const SizedBox(height: 20),

            // ── Tier detail card ──
            _buildTierCard(px),
            const SizedBox(height: 20),

            // ── Features comparison ──
            Text('Ozellikler', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: px.text)),
            const SizedBox(height: 14),

            _featureRow(px, Icons.upload_file_rounded, PxDecor.green, 'PDF Yukleme', _featureValue(0), _featureValue(1), _featureValue(2), ['3/gun', '10/gun', 'Sinirsiz']),
            const SizedBox(height: 8),
            _featureRow(px, Icons.bolt_rounded, PxDecor.orange, 'Enerji', _featureValue(0), _featureValue(1), _featureValue(2), ['30', '60', '100']),
            const SizedBox(height: 8),
            _featureRow(px, Icons.ac_unit_rounded, PxDecor.teal, 'Seri Dondurma', _featureValue(0), _featureValue(1), _featureValue(2), ['1/ay', '3/ay', 'Sinirsiz']),
            const SizedBox(height: 8),
            _featureRow(px, Icons.psychology_rounded, PxDecor.blue, 'AI Planlama', _featureValue(0), _featureValue(1), _featureValue(2), ['Temel', 'Gelismis', 'Gelismis+']),
            const SizedBox(height: 8),
            _featureRow(px, Icons.auto_awesome_rounded, PxDecor.purple, 'Quiz Modu', _featureValue(0), _featureValue(1), _featureValue(2), ['Temel', 'Gelismis', 'Gelismis+']),
            const SizedBox(height: 8),
            _featureRow(px, Icons.speed_rounded, PxDecor.orange, 'AI Hizi', _featureValue(0), _featureValue(1), _featureValue(2), ['Normal', 'Oncelikli', 'Aninda']),
            const SizedBox(height: 8),
            _featureRow(px, Icons.support_agent_rounded, PxDecor.gold, 'Destek', _featureValue(0), _featureValue(1), _featureValue(2), ['Standart', 'Oncelikli', 'VIP']),
            const SizedBox(height: 24),

            // ── Purchase button ──
            _buildPurchaseButton(px),
            const SizedBox(height: 12),

            // ── Restore ──
            Center(child: GestureDetector(
              onTap: () { Haptic.light(); PurchaseService.instance.restorePurchases(); },
              child: Text('Satin alimi geri yukle', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: px.textMuted, decoration: TextDecoration.underline)),
            )),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _tierTab(Px px, int index, String label, IconData icon, Color color, Color dark) {
    final selected = _selectedTier == index;
    return GestureDetector(
      onTap: () { Haptic.selection(); setState(() => _selectedTier = index); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? color : px.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? dark : px.border, width: selected ? 3 : 2),
          boxShadow: [BoxShadow(color: selected ? dark : px.shadow, offset: const Offset(0, 3), blurRadius: 0)],
        ),
        child: Column(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: selected ? dark : px.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: selected ? Colors.white.withAlpha(40) : px.border, width: 2),
            ),
            child: Icon(icon, color: selected ? Colors.white : color, size: 18),
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: selected ? Colors.white : px.text)),
        ]),
      ),
    );
  }

  Widget _buildTierCard(Px px) {
    final tiers = [
      _TierData('Gumus', Icons.shield_rounded, const Color(0xFFA0AEC0), const Color(0xFF718096), '29.99', 'Aylik', ['3 PDF/gun', '30 enerji', '1 freeze/ay', 'Temel AI planlama']),
      _TierData('Altin', Icons.workspace_premium_rounded, PxDecor.gold, PxDecor.goldDark, '49.99', 'Aylik', ['10 PDF/gun', '60 enerji', '3 freeze/ay', 'Gelismis AI planlama', 'Oncelikli AI isleme']),
      _TierData('Elmas', Icons.diamond_rounded, const Color(0xFF63B3ED), const Color(0xFF3182CE), '79.99', 'Aylik', ['Sinirsiz PDF', '100 enerji', 'Sinirsiz freeze', 'Gelismis+ AI planlama', 'Aninda AI isleme', 'VIP destek']),
    ];
    final tier = tiers[_selectedTier];

    return Container(
      decoration: BoxDecoration(
        color: px.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tier.color, width: 3),
        boxShadow: [BoxShadow(color: tier.dark, offset: const Offset(0, 5), blurRadius: 0)],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: tier.color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
            boxShadow: [BoxShadow(color: tier.dark, offset: const Offset(0, 3), blurRadius: 0)],
          ),
          child: Column(children: [
            Icon(tier.icon, color: Colors.white, size: 32),
            const SizedBox(height: 8),
            Text('${tier.name} Plan', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
            const SizedBox(height: 4),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('₺${tier.price}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 28)),
              Text(' / ${tier.period}', style: TextStyle(color: Colors.white.withAlpha(180), fontWeight: FontWeight.w600, fontSize: 14)),
            ]),
          ]),
        ),
        // Features
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            for (final f in tier.features) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(children: [
                  Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(color: tier.color, borderRadius: BorderRadius.circular(7)),
                    child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(f, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: px.text))),
                ]),
              ),
            ],
          ]),
        ),
      ]),
    );
  }

  String _featureValue(int tier) {
    // Placeholder — values are passed in the row
    return '';
  }

  Widget _featureRow(Px px, IconData icon, Color color, String title, String s, String g, String d, List<String> values) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _selectedTier >= 0 ? px.accentBg(color) : px.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color, width: 2),
        boxShadow: [BoxShadow(color: color.withAlpha(px.isDark ? 15 : 30), offset: const Offset(0, 2), blurRadius: 0)],
      ),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: color.withAlpha(80), offset: const Offset(0, 2), blurRadius: 0)]),
          child: Stack(children: [
            Positioned(top: 3, left: 3, child: Container(width: 8, height: 4, decoration: BoxDecoration(color: Colors.white.withAlpha(40), borderRadius: BorderRadius.circular(2)))),
            Center(child: Icon(icon, color: Colors.white, size: 18)),
          ]),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: px.text))),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(values[_selectedTier], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11)),
        ),
      ]),
    );
  }

  Widget _buildPurchaseButton(Px px) {
    final colors = [const Color(0xFFA0AEC0), PxDecor.gold, const Color(0xFF63B3ED)];
    final darks = [const Color(0xFF718096), PxDecor.goldDark, const Color(0xFF3182CE)];
    final labels = ['Gumus\'e Abone Ol', 'Altin\'a Abone Ol', 'Elmas\'a Abone Ol'];
    final prices = ['₺29.99/ay', '₺49.99/ay', '₺79.99/ay'];

    return GestureDetector(
      onTap: () async {
        Haptic.medium();
        final productIds = [ProductIds.premiumSilver, ProductIds.premiumGold, ProductIds.premiumDiamond];
        final ok = await PurchaseService.instance.buy(productIds[_selectedTier]);
        if (!ok && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Satin alma baslatilamadi. Lutfen tekrar deneyin.', style: TextStyle(fontWeight: FontWeight.w700)),
              backgroundColor: colors[_selectedTier],
            ),
          );
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: colors[_selectedTier],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: darks[_selectedTier], width: 3),
          boxShadow: [BoxShadow(color: darks[_selectedTier], offset: const Offset(0, 5), blurRadius: 0)],
        ),
        child: Column(children: [
          Text(labels[_selectedTier], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17)),
          const SizedBox(height: 2),
          Text(prices[_selectedTier], style: TextStyle(color: Colors.white.withAlpha(200), fontWeight: FontWeight.w700, fontSize: 13)),
        ]),
      ),
    );
  }
}

class _TierData {
  const _TierData(this.name, this.icon, this.color, this.dark, this.price, this.period, this.features);
  final String name, price, period;
  final IconData icon;
  final Color color, dark;
  final List<String> features;
}
