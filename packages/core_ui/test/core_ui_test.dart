import 'package:flutter_test/flutter_test.dart';

import 'package:core_ui/core_ui.dart';

void main() {
  test('core_ui smoke test', () {
    expect(AppColors.primary.toARGB32(), isNot(0));
  });
}
