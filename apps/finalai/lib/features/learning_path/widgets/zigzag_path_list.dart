import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'tasks/task_helpers.dart';

class ZigzagPathList extends StatelessWidget {
  const ZigzagPathList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.startLeft = true,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index, bool isLeft) itemBuilder;
  final bool startLeft;

  @override
  Widget build(BuildContext context) {
    final px = Px.of(context);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 14),
      itemCount: itemCount,
      itemBuilder: (context, i) {
        final isLeft = (i % 2 == 0) == startLeft;
        final align = isLeft ? Alignment.centerLeft : Alignment.centerRight;

        return Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Align(
            alignment: align,
            child: SizedBox(
              width: 220,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  if (i > 0)
                    Positioned(
                      left: isLeft ? 38 : null,
                      right: isLeft ? null : 38,
                      top: -30,
                      child: Container(
                        width: 6, height: 30,
                        decoration: BoxDecoration(color: px.border, borderRadius: BorderRadius.circular(3)),
                      ),
                    ),
                  if (i > 0)
                    Positioned(
                      left: isLeft ? 38 : null,
                      right: isLeft ? null : 38,
                      top: -48,
                      child: Transform.rotate(
                        angle: isLeft ? -math.pi / 6 : math.pi / 6,
                        child: Container(
                          width: 28, height: 8,
                          decoration: BoxDecoration(color: px.border, borderRadius: BorderRadius.circular(4)),
                        ),
                      ),
                    ),
                  itemBuilder(context, i, isLeft),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
