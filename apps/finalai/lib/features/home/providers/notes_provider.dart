import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/repositories/repository_providers.dart';
import '../../../models/note_model.dart';
import '../../auth/providers/auth_provider.dart';

final recentNotesProvider = FutureProvider<List<NoteModel>>((ref) async {
  final auth = ref.watch(authProvider);
  if (auth.session == null) return <NoteModel>[];
  return ref.watch(noteRepositoryProvider).getRecentNotes(limit: 10);
});
