import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/repositories/repository_providers.dart';

final userStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.watch(statsRepositoryProvider).getUserStats();
});
