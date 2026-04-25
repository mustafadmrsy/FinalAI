import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:finalai/app.dart';

void main() {
  testWidgets('FinalAI app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: FinalAIApp()));
    await tester.pump();
  });
}
