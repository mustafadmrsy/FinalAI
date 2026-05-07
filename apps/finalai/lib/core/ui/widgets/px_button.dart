import 'package:flutter/material.dart';
import '../../../features/learning_path/widgets/tasks/task_helpers.dart';

// ═══════════════════════════════════════════════════════════════
//  PX BUTTON — Game-style button with loading & disabled states
// ═══════════════════════════════════════════════════════════════

class PxButton extends StatefulWidget {
  const PxButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color = PxDecor.green,
    this.icon,
    this.isLoading = false,
    this.isDisabled = false,
    this.height = 52,
    this.fontSize = 16,
  });

  final String label;
  final VoidCallback? onTap;
  final Color color;
  final IconData? icon;
  final bool isLoading;
  final bool isDisabled;
  final double height;
  final double fontSize;

  @override
  State<PxButton> createState() => _PxButtonState();
}

class _PxButtonState extends State<PxButton> with SingleTickerProviderStateMixin {
  bool _pressed = false;

  Color get _dark => HSLColor.fromColor(widget.color)
      .withLightness((HSLColor.fromColor(widget.color).lightness - 0.15).clamp(0, 1))
      .toColor();

  bool get _enabled => !widget.isLoading && !widget.isDisabled && widget.onTap != null;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = _enabled ? widget.color : widget.color.withAlpha(120);
    final darkColor = _enabled ? _dark : _dark.withAlpha(120);
    final offset = _pressed ? 1.0 : 4.0;

    return GestureDetector(
      onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: _enabled ? (_) { setState(() => _pressed = false); widget.onTap?.call(); } : null,
      onTapCancel: _enabled ? () => setState(() => _pressed = false) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: double.infinity,
        height: widget.height,
        transform: Matrix4.translationValues(0, _pressed ? 3 : 0, 0),
        decoration: BoxDecoration(
          color: effectiveColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: darkColor, width: 2),
          boxShadow: [BoxShadow(color: darkColor, offset: Offset(0, offset), blurRadius: 0)],
        ),
        child: Center(
          child: widget.isLoading
              ? SizedBox(
                  width: 22, height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation(Colors.white.withAlpha(200)),
                  ),
                )
              : Row(mainAxisSize: MainAxisSize.min, children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, color: Colors.white, size: widget.fontSize + 2),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    widget.label,
                    style: TextStyle(
                      color: Colors.white.withAlpha(_enabled ? 255 : 180),
                      fontWeight: FontWeight.w900,
                      fontSize: widget.fontSize,
                    ),
                  ),
                ]),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
//  PAGE LOADING OVERLAY — Shown during route transitions
// ═══════════════════════════════════════════════════════════════

class PxLoadingOverlay extends StatelessWidget {
  const PxLoadingOverlay({super.key, this.message});
  final String? message;

  @override
  Widget build(BuildContext context) {
    final px = Px.of(context);
    return Container(
      color: px.bg,
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _BouncingLoader(color: PxDecor.green),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: px.textSub)),
          ],
        ]),
      ),
    );
  }
}

class _BouncingLoader extends StatefulWidget {
  const _BouncingLoader({required this.color});
  final Color color;

  @override
  State<_BouncingLoader> createState() => _BouncingLoaderState();
}

class _BouncingLoaderState extends State<_BouncingLoader> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: List.generate(3, (i) {
      return AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          final t = ((_ctrl.value - i * 0.15) % 1.0).clamp(0.0, 1.0);
          final bounce = (t < 0.5) ? (t * 2) : (2 - t * 2);
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            child: Transform.translate(
              offset: Offset(0, -8 * bounce),
              child: Container(
                width: 14, height: 14,
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: HSLColor.fromColor(widget.color).withLightness(0.3).toColor(),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: HSLColor.fromColor(widget.color).withLightness(0.3).toColor(),
                      offset: const Offset(0, 2),
                      blurRadius: 0,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }));
  }
}
