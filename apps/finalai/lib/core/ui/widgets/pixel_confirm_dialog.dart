import 'package:flutter/material.dart';
import '../../services/haptic_service.dart';
import '../../../features/learning_path/widgets/tasks/task_helpers.dart';

// ═══════════════════════════════════════════════════════════════
//  PIXEL CONFIRM DIALOG — 2D Pixel Game Art style
//  Reusable for: lesson exit, logout, delete, etc.
// ═══════════════════════════════════════════════════════════════

class PixelConfirmDialog extends StatelessWidget {
  const PixelConfirmDialog({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    this.confirmLabel = 'Evet',
    this.cancelLabel = 'Iptal',
    this.confirmColor,
    this.confirmDark,
    this.showWarningBadge = false,
    this.warningText,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final Color? confirmColor;
  final Color? confirmDark;
  final bool showWarningBadge;
  final String? warningText;

  static Future<bool> show(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    String confirmLabel = 'Evet',
    String cancelLabel = 'Iptal',
    Color? confirmColor,
    Color? confirmDark,
    bool showWarningBadge = false,
    String? warningText,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: PixelConfirmDialog(
          icon: icon,
          iconColor: iconColor,
          title: title,
          message: message,
          confirmLabel: confirmLabel,
          cancelLabel: cancelLabel,
          confirmColor: confirmColor,
          confirmDark: confirmDark,
          showWarningBadge: showWarningBadge,
          warningText: warningText,
        ),
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final px = Px.of(context);
    final cColor = confirmColor ?? PxDecor.red;
    final cDark = confirmDark ?? PxDecor.redDark;

    return Container(
      constraints: const BoxConstraints(maxWidth: 340),
      decoration: BoxDecoration(
        color: px.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: iconColor, width: 3),
        boxShadow: [
          BoxShadow(color: iconColor.withAlpha(40), offset: const Offset(0, 6), blurRadius: 0),
          BoxShadow(color: iconColor.withAlpha(20), blurRadius: 20, spreadRadius: 2),
        ],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // ── Header ──
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: iconColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(21)),
            boxShadow: [BoxShadow(color: iconColor.withAlpha(180), offset: const Offset(0, 4), blurRadius: 0)],
          ),
          child: Column(children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(25),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withAlpha(50), width: 3),
                boxShadow: [BoxShadow(color: Colors.black.withAlpha(40), offset: const Offset(0, 4), blurRadius: 0)],
              ),
              child: Stack(children: [
                Positioned(top: 4, left: 4, child: Container(
                  width: 16, height: 7,
                  decoration: BoxDecoration(color: Colors.white.withAlpha(40), borderRadius: BorderRadius.circular(3)),
                )),
                Center(child: Icon(icon, color: Colors.white, size: 36)),
              ]),
            ),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20)),
          ]),
        ),

        // ── Body ──
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            Text(
              message,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: px.textSub, height: 1.5),
              textAlign: TextAlign.center,
            ),

            if (showWarningBadge && warningText != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: px.accentBg(PxDecor.orange),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: PxDecor.orange, width: 1.5),
                ),
                child: Row(children: [
                  Icon(Icons.warning_amber_rounded, color: PxDecor.orange, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(warningText!, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: PxDecor.orange))),
                ]),
              ),
            ],

            const SizedBox(height: 20),

            // Buttons
            Row(children: [
              // Cancel
              Expanded(child: GestureDetector(
                onTap: () { Haptic.light(); Navigator.of(context).pop(false); },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: px.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: px.border, width: 2),
                    boxShadow: [BoxShadow(color: px.shadow, offset: const Offset(0, 3), blurRadius: 0)],
                  ),
                  child: Center(child: Text(cancelLabel, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: px.text))),
                ),
              )),
              const SizedBox(width: 12),
              // Confirm
              Expanded(child: GestureDetector(
                onTap: () { Haptic.medium(); Navigator.of(context).pop(true); },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: cColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: cDark, width: 2),
                    boxShadow: [BoxShadow(color: cDark, offset: const Offset(0, 3), blurRadius: 0)],
                  ),
                  child: Center(child: Text(confirmLabel, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.white))),
                ),
              )),
            ]),
          ]),
        ),
      ]),
    );
  }
}
