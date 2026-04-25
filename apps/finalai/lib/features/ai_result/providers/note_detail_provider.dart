import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/repositories/repository_providers.dart';

final noteDetailProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, noteId) async {
  return ref.watch(noteRepositoryProvider).getNoteById(noteId);
});
