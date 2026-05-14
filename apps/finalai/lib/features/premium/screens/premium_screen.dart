import 'package:flutter/material.dart';

import '../../learning_path/widgets/tasks/task_helpers.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/services/purchase_service.dart';

// ═══════════════════════════════════════════════════════════════
//  PREMIUM SCREEN — Modern Subscription UI (2D Pixel Style)
//  Tier select + Monthly/Yearly toggle
// ═══════════════════════════════════════════════════════════════

class PremiumScreen extends StatefulWidget {
  const PremiumScreen({super.key});

  @override
  State<PremiumScreen> createState() => _PremiumScreenState();
}

class _PremiumScreenState extends State<PremiumScreen> {
  int _selectedTier = 0; // 0=plus, 1=pro
  bool _isYearly = true; // default yearly (best value)

  static const _tiers = [
    _Tier(
      name: 'Plus',
      icon: Icons.bolt_rounded,
      monthly: '79.99',
      yearly: '479.99',
      yearlyMonthly: '40.00',
      features: [
        _Feat(Icons.block_rounded, 'Reklamsiz deneyim'),
        _Feat(Icons.bolt_rounded, '60 enerji / gun'),
        _Feat(Icons.picture_as_pdf_rounded, '5 PDF / gun'),
        _Feat(Icons.ac_unit_rounded, '2 seri dondurma / ay'),
        _Feat(Icons.psychology_rounded, 'Gelismis AI planlama'),
        _Feat(Icons.school_rounded, '15 AI ders / gun'),
      ],
    ),
    _Tier(
      name: 'Pro',
      icon: Icons.diamond_rounded,
      monthly: '149.99',
      yearly: '899.99',
      yearlyMonthly: '75.00',
      features: [
        _Feat(Icons.block_rounded, 'Reklamsiz deneyim'),
        _Feat(Icons.all_inclusive_rounded, 'Sinirsiz enerji'),
        _Feat(Icons.picture_as_pdf_rounded, 'Sinirsiz PDF'),
        _Feat(Icons.ac_unit_rounded, 'Sinirsiz seri dondurma'),
        _Feat(Icons.auto_awesome_rounded, 'Gelismis+ AI planlama'),
        _Feat(Icons.speed_rounded, 'Oncelikli AI isleme'),
        _Feat(Icons.school_rounded, 'Sinirsiz AI ders'),
      ],
    ),
  ];

  String get _displayPrice {
    final t = _tiers[_selectedTier];
    return _isYearly ? t.yearly : t.monthly;
  }

  String get _period => _isYearly ? 'yil' : 'ay';

  Color get _accent => _selectedTier == 0 ? PxDecor.blue : PxDecor.gold;
  Color get _accentDark => _selectedTier == 0 ? PxDecor.blueDark : PxDecor.goldDark;

  @override
  Widget build(BuildContext context) {
    final px = Px.of(context);
    final tier = _tiers[_selectedTier];

    return Scaffold(
      backgroundColor: px.bg,
      body: SafeArea(
        child: Column(children: [
          // ── Top bar ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.of(context).maybePop(),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: px.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: px.border, width: 2), boxShadow: [BoxShadow(color: px.shadow, offset: const Offset(0, 3), blurRadius: 0)]),
                  child: Icon(Icons.close_rounded, size: 18, color: px.textMuted),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () { Haptic.light(); PurchaseService.instance.restorePurchases(); },
                child: Text('Geri Yukle', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _accent)),
              ),
            ]),
          ),

          // ── Scrollable content ──
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                const SizedBox(height: 8),
                // ── Icon + Title ──
                Center(child: Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [_accent, _accentDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _accentDark, width: 3),
                    boxShadow: [BoxShadow(color: _accentDark, offset: const Offset(0, 4), blurRadius: 0)],
                  ),
                  child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 36),
                )),
                const SizedBox(height: 16),
                Center(child: Text('FinalAI Premium', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: px.text))),
                const SizedBox(height: 4),
                Center(child: Text('Tum sinirlari kaldir, tam gucle ogren!', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: px.textMuted))),
                const SizedBox(height: 24),

                // ── Monthly / Yearly toggle ──
                _buildPeriodToggle(px),
                const SizedBox(height: 20),

                // ── Plan cards ──
                Row(children: [
                  Expanded(child: _buildPlanCard(px, 0, tier)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildPlanCard(px, 1, tier)),
                ]),
                const SizedBox(height: 20),

                // ── Features ──
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: px.card,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: _accent.withAlpha(60), width: 2),
                    boxShadow: [BoxShadow(color: px.shadow, offset: const Offset(0, 3), blurRadius: 0)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${tier.name} icerikleri', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: px.text)),
                      const SizedBox(height: 12),
                      for (final f in tier.features)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(children: [
                            Container(
                              width: 28, height: 28,
                              decoration: BoxDecoration(color: _accent.withAlpha(30), borderRadius: BorderRadius.circular(8)),
                              child: Icon(f.icon, color: _accent, size: 16),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text(f.label, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: px.text))),
                            Icon(Icons.check_circle_rounded, color: _accent, size: 18),
                          ]),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Legal ──
                Center(child: Text('Abonelik otomatik yenilenir. Istedigin zaman iptal edebilirsin.', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: px.textMuted))),
                const SizedBox(height: 24),
              ],
            ),
          ),

          // ── Sticky purchase button ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: _buildPurchaseButton(px),
          ),
        ]),
      ),
    );
  }

  // ── Period toggle (Monthly / Yearly) ──
  Widget _buildPeriodToggle(Px px) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: px.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: px.border, width: 2),
        boxShadow: [BoxShadow(color: px.shadow, offset: const Offset(0, 3), blurRadius: 0)],
      ),
      child: Row(children: [
        Expanded(child: _toggleBtn(px, false, 'Aylik')),
        Expanded(child: _toggleBtn(px, true, 'Yillik')),
      ]),
    );
  }

  Widget _toggleBtn(Px px, bool yearly, String label) {
    final selected = _isYearly == yearly;
    return GestureDetector(
      onTap: () { Haptic.selection(); setState(() => _isYearly = yearly); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? _accent : Colors.transparent,
          borderRadius: BorderRadius.circular(11),
          boxShadow: selected ? [BoxShadow(color: _accentDark, offset: const Offset(0, 3), blurRadius: 0)] : null,
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: selected ? Colors.white : px.textMuted)),
          if (yearly) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: selected ? Colors.white.withAlpha(30) : PxDecor.green.withAlpha(30),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('%50', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, color: selected ? Colors.white : PxDecor.green)),
            ),
          ],
        ]),
      ),
    );
  }

  // ── Plan card ──
  Widget _buildPlanCard(Px px, int index, _Tier currentTier) {
    final t = _tiers[index];
    final selected = _selectedTier == index;
    final color = index == 0 ? PxDecor.blue : PxDecor.gold;
    final dark = index == 0 ? PxDecor.blueDark : PxDecor.goldDark;
    final price = _isYearly ? t.yearlyMonthly : t.monthly;

    return GestureDetector(
      onTap: () { Haptic.selection(); setState(() => _selectedTier = index); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? color : px.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? dark : px.border, width: selected ? 3 : 2),
          boxShadow: [BoxShadow(color: selected ? dark : px.shadow, offset: const Offset(0, 4), blurRadius: 0)],
        ),
        child: Column(children: [
          // Badge
          if (index == 1) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: selected ? Colors.white.withAlpha(30) : PxDecor.gold.withAlpha(30), borderRadius: BorderRadius.circular(6)),
              child: Text('EN POPULER', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 9, color: selected ? Colors.white : PxDecor.gold, letterSpacing: 0.5)),
            ),
            const SizedBox(height: 6),
          ] else
            const SizedBox(height: 22),

          // Icon
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: selected ? dark : px.surface,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: selected ? Colors.white.withAlpha(30) : px.border, width: 2),
            ),
            child: Icon(t.icon, color: selected ? Colors.white : color, size: 22),
          ),
          const SizedBox(height: 10),
          Text(t.name, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: selected ? Colors.white : px.text)),
          const SizedBox(height: 6),

          // Price
          RichText(text: TextSpan(children: [
            TextSpan(text: '₺$price', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: selected ? Colors.white : px.text)),
            TextSpan(text: '/ay', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: selected ? Colors.white.withAlpha(180) : px.textMuted)),
          ])),

          if (_isYearly) ...[
            const SizedBox(height: 4),
            Text('₺${t.yearly}/yil', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11, color: selected ? Colors.white.withAlpha(160) : px.textMuted)),
          ],

          const SizedBox(height: 8),
          // Radio indicator
          Container(
            width: 22, height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? Colors.white : px.surface,
              border: Border.all(color: selected ? dark : px.border, width: 2),
            ),
            child: selected ? Center(child: Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: color))) : null,
          ),
        ]),
      ),
    );
  }

  // ── Purchase button ──
  Widget _buildPurchaseButton(Px px) {
    final productId = _isYearly
        ? (_selectedTier == 0 ? ProductIds.premiumPlus : ProductIds.premiumPro)
        : (_selectedTier == 0 ? ProductIds.premiumPlusMonthly : ProductIds.premiumProMonthly);
    final tier = _tiers[_selectedTier];
    final label = '${tier.name}\'a Abone Ol';

    return GestureDetector(
      onTap: () async {
        Haptic.medium();
        final ok = await PurchaseService.instance.buy(productId);
        if (!ok && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Satin alma baslatilamadi. Lutfen tekrar deneyin.', style: TextStyle(fontWeight: FontWeight.w700)),
              backgroundColor: _accent,
            ),
          );
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _accent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _accentDark, width: 3),
          boxShadow: [BoxShadow(color: _accentDark, offset: const Offset(0, 5), blurRadius: 0)],
        ),
        child: Column(children: [
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17)),
          const SizedBox(height: 2),
          Text('₺$_displayPrice / $_period', style: TextStyle(color: Colors.white.withAlpha(200), fontWeight: FontWeight.w700, fontSize: 13)),
        ]),
      ),
    );
  }
}

// ── Data classes ──
class _Tier {
  const _Tier({required this.name, required this.icon, required this.monthly, required this.yearly, required this.yearlyMonthly, required this.features});
  final String name, monthly, yearly, yearlyMonthly;
  final IconData icon;
  final List<_Feat> features;
}

class _Feat {
  const _Feat(this.icon, this.label);
  final IconData icon;
  final String label;
}
