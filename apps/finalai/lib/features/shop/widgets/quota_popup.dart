import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../learning_path/widgets/tasks/task_helpers.dart';
import '../../stats/providers/user_stats_provider.dart';
import '../../../core/services/ad_reward_service.dart';
import '../../../core/services/haptic_service.dart';

// ═══════════════════════════════════════════════════════════════
//  QUOTA POPUP — Token/Kredi/Enerji bitince gosterilecek popup
//  Reklam izle veya magazaya yonlendir
// ═══════════════════════════════════════════════════════════════

enum QuotaType { energy, pdfCredit, aiToken }

class QuotaPopup {
  QuotaPopup._();

  /// Kota bitti popup'i goster. true donerse odullendirildi (tekrar denenebilir)
  static Future<bool> show(
    BuildContext context,
    WidgetRef ref, {
    required QuotaType type,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _QuotaSheet(type: type, parentContext: context),
    );
    return result ?? false;
  }
}

class _QuotaSheet extends ConsumerStatefulWidget {
  const _QuotaSheet({required this.type, required this.parentContext});
  final QuotaType type;
  final BuildContext parentContext;

  @override
  ConsumerState<_QuotaSheet> createState() => _QuotaSheetState();
}

class _QuotaSheetState extends ConsumerState<_QuotaSheet> {
  bool _loading = false;

  String get _title => switch (widget.type) {
    QuotaType.energy => 'Enerjin Bitti!',
    QuotaType.pdfCredit => 'PDF Kredin Bitti!',
    QuotaType.aiToken => 'AI Token Bitti!',
  };

  String get _message => switch (widget.type) {
    QuotaType.energy => 'Derse devam etmek icin enerjiye ihtiyacin var. Reklam izle veya magazadan satin al!',
    QuotaType.pdfCredit => 'PDF ozetlemek icin krediye ihtiyacin var. Reklam izle veya magazadan satin al!',
    QuotaType.aiToken => 'AI ozelliklerini kullanmak icin token gerekli. Reklam izle veya magazadan satin al!',
  };

  String get _rewardText => switch (widget.type) {
    QuotaType.energy => 'Reklam Izle (+3 Enerji)',
    QuotaType.pdfCredit => 'Reklam Izle (+1 PDF Kredi)',
    QuotaType.aiToken => 'Reklam Izle (+2 AI Token)',
  };

  IconData get _icon => switch (widget.type) {
    QuotaType.energy => Icons.bolt_rounded,
    QuotaType.pdfCredit => Icons.picture_as_pdf_rounded,
    QuotaType.aiToken => Icons.auto_awesome_rounded,
  };

  Color get _color => switch (widget.type) {
    QuotaType.energy => PxDecor.orange,
    QuotaType.pdfCredit => PxDecor.purple,
    QuotaType.aiToken => PxDecor.blue,
  };

  Color get _dark => switch (widget.type) {
    QuotaType.energy => PxDecor.orangeDark,
    QuotaType.pdfCredit => PxDecor.purpleDark,
    QuotaType.aiToken => PxDecor.blueDark,
  };

  Future<void> _watchAd() async {
    setState(() => _loading = true);
    final earned = await AdRewardService.instance.showRewardedAd();
    if (!mounted) return;

    if (!earned) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reklam yuklenemedi. Tekrar deneyin.', style: TextStyle(fontWeight: FontWeight.w700)), backgroundColor: Color(0xFFFF4B4B)),
      );
      return;
    }

    final repo = ref.read(userStatsRepositoryProvider);
    switch (widget.type) {
      case QuotaType.energy:
        await repo.rewardEnergy(amount: 3);
        break;
      case QuotaType.pdfCredit:
        await repo.rewardPdfCredit();
        break;
      case QuotaType.aiToken:
        await repo.rewardAiTokens(amount: 2);
        break;
    }
    ref.invalidate(userStatsProvider);
    setState(() => _loading = false);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final px = Px.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: px.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _color.withAlpha(60), width: 2),
        boxShadow: [BoxShadow(color: _dark.withAlpha(40), offset: const Offset(0, 6), blurRadius: 0)],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Icon
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(
            color: _color.withAlpha(25),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _color.withAlpha(60), width: 2),
          ),
          child: Icon(_icon, color: _color, size: 36),
        ),
        const SizedBox(height: 16),
        Text(_title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: px.text)),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(_message, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: px.textMuted, height: 1.4)),
        ),
        const SizedBox(height: 24),

        // Reklam izle butonu
        SizedBox(
          width: double.infinity,
          child: GestureDetector(
            onTap: _loading ? null : () { Haptic.light(); _watchAd(); },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: _color,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: _dark.withAlpha(80), offset: const Offset(0, 4), blurRadius: 0)],
              ),
              child: Center(
                child: _loading
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                      const SizedBox(width: 6),
                      Text(_rewardText, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.white)),
                    ]),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Magazaya git
        SizedBox(
          width: double.infinity,
          child: GestureDetector(
            onTap: () {
              Haptic.light();
              Navigator.of(context).pop(false);
              widget.parentContext.go('/shop');
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: px.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: px.border, width: 2),
              ),
              child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.storefront_rounded, color: px.textMuted, size: 20),
                const SizedBox(width: 6),
                Text('Magazaya Git', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: px.textMuted)),
              ])),
            ),
          ),
        ),
        SizedBox(height: MediaQuery.of(context).padding.bottom + 4),
      ]),
    );
  }
}
