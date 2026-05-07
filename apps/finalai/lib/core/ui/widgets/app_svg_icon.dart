import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppSvgIcon extends StatelessWidget {
  const AppSvgIcon(
    this.assetPath, {
    super.key,
    this.size = 22,
    this.color,
    this.semanticLabel,
    this.useThemeColorIfNull = true,
  });

  final String assetPath;
  final double size;
  final Color? color;
  final String? semanticLabel;
  final bool useThemeColorIfNull;

  @override
  Widget build(BuildContext context) {
    final resolvedColor = (color == null && useThemeColorIfNull) ? Theme.of(context).colorScheme.onSurface : color;
    final fallbackColor = resolvedColor ?? Theme.of(context).colorScheme.onSurface;

    return SvgPicture.asset(
      assetPath,
      width: size,
      height: size,
      theme: SvgTheme(currentColor: fallbackColor),
      colorFilter: resolvedColor == null ? null : ColorFilter.mode(resolvedColor, BlendMode.srcIn),
      semanticsLabel: semanticLabel,
      placeholderBuilder: (_) => SizedBox(width: size, height: size),
      errorBuilder: (context, error, stackTrace) {
        debugPrint('AppSvgIcon failed: $assetPath');
        debugPrint('Error: $error');
        if (stackTrace != null) debugPrint('$stackTrace');
        return Icon(Icons.broken_image_outlined, size: size, color: fallbackColor);
      },
    );
  }
}
