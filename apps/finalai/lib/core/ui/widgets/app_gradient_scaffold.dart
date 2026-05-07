import 'package:flutter/material.dart';

import 'app_gradient_background.dart';

class AppGradientScaffold extends StatelessWidget {
  const AppGradientScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.safeArea = true,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final bool safeArea;

  @override
  Widget build(BuildContext context) {
    final content = safeArea ? SafeArea(child: body) : body;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: appBar,
      body: Stack(
        children: [
          const Positioned.fill(child: AppGradientBackground()),
          content,
        ],
      ),
    );
  }
}
