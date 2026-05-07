import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ButtonFeedbackController {
  VoidCallback? _success;
  VoidCallback? _error;

  void _attach({required VoidCallback success, required VoidCallback error}) {
    _success = success;
    _error = error;
  }

  void _detach() {
    _success = null;
    _error = null;
  }

  void success() {
    _success?.call();
  }

  void error() {
    _error?.call();
  }
}

class ExpressiveButton extends StatefulWidget {
  const ExpressiveButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.height = 52,
    this.backgroundColor,
    this.foregroundColor,
    this.borderRadius,
    this.borderSide,
    this.depth = 6,
    this.controller,
    this.enableHaptics = false,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final double height;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final BorderRadius? borderRadius;
  final BorderSide? borderSide;
  final double depth;
  final ButtonFeedbackController? controller;
  final bool enableHaptics;

  @override
  State<ExpressiveButton> createState() => _ExpressiveButtonState();
}

class _ExpressiveButtonState extends State<ExpressiveButton> with TickerProviderStateMixin {
  late final AnimationController _pressController;
  late final AnimationController _successController;
  late final AnimationController _errorController;

  @override
  void initState() {
    super.initState();

    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      reverseDuration: const Duration(milliseconds: 120),
    );

    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );

    _errorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    widget.controller?._attach(success: _playSuccess, error: _playError);
  }

  @override
  void didUpdateWidget(covariant ExpressiveButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach();
      widget.controller?._attach(success: _playSuccess, error: _playError);
    }
  }

  @override
  void dispose() {
    widget.controller?._detach();
    _pressController.dispose();
    _successController.dispose();
    _errorController.dispose();
    super.dispose();
  }

  bool get _enabled => widget.onPressed != null;

  Color _darken(Color c, [double amount = 0.16]) {
    final hsl = HSLColor.fromColor(c);
    final l = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(l).toColor();
  }

  void _playSuccess() {
    if (!_enabled) return;
    _successController
      ..stop()
      ..reset()
      ..forward();
  }

  void _playError() {
    if (!_enabled) return;
    _errorController
      ..stop()
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final background = widget.backgroundColor ?? theme.colorScheme.primary;
    final foreground = widget.foregroundColor ?? theme.colorScheme.onPrimary;
    final radius = widget.borderRadius ?? BorderRadius.circular(16);
    final borderSide = widget.borderSide ?? BorderSide.none;
    final depth = widget.depth;

    final pressT = CurvedAnimation(parent: _pressController, curve: Curves.easeOutCubic);
    final scale = Tween<double>(begin: 1.0, end: 0.98).evaluate(pressT);
    final pressDown = Tween<double>(begin: 0.0, end: depth).evaluate(pressT);

    final successT = CurvedAnimation(parent: _successController, curve: Curves.elasticOut);
    final successLift = Tween<double>(begin: 0.0, end: -8.0).evaluate(successT);

    final errorT = CurvedAnimation(parent: _errorController, curve: Curves.easeInOut);

    final shake = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: 0.0), weight: 1),
    ]).evaluate(errorT);

    final disabledOpacity = theme.disabledColor.a;
    final disabledBg = Color.lerp(background, theme.colorScheme.surface, 0.55) ?? background;
    final faceColor = _enabled
        ? background
        : disabledBg.withAlpha((math.max(0.35, 1 - disabledOpacity) * 255).round());
    final baseColor = _darken(faceColor, 0.18);

    return ConstrainedBox(
      constraints: BoxConstraints.tightFor(height: widget.height + depth),
      child: AnimatedBuilder(
        animation: Listenable.merge([_pressController, _successController, _errorController]),
        builder: (context, _) {
          final dx = shake;
          final dy = pressDown + successLift;

          return Transform.translate(
            offset: Offset(dx, 0),
            child: Stack(
              children: [
                Positioned.fill(
                  top: depth,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: baseColor,
                      borderRadius: radius,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Transform.translate(
                    offset: Offset(0, dy),
                    child: Transform.scale(
                      scale: scale,
                      child: Material(
                        color: faceColor,
                        shape: RoundedRectangleBorder(borderRadius: radius, side: borderSide),
                        child: InkWell(
                          onTap: _enabled ? () { HapticFeedback.lightImpact(); widget.onPressed?.call(); } : null,
                          onHighlightChanged: (v) {
                            if (!_enabled) return;
                            if (v) {
                              _pressController.forward();
                            } else {
                              _pressController.reverse();
                            }
                          },
                          borderRadius: radius,
                          splashColor: foreground.withAlpha((0.14 * 255).round()),
                          highlightColor: foreground.withAlpha((0.08 * 255).round()),
                          child: DefaultTextStyle(
                            style: theme.textTheme.titleMedium?.copyWith(color: foreground) ??
                                TextStyle(color: foreground),
                            child: IconTheme(
                              data: IconThemeData(color: foreground),
                              child: Center(child: widget.child),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
