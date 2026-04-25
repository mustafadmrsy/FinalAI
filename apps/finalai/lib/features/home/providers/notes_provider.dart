import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/repositories/repository_providers.dart';
import '../../../models/note_model.dart';

final recentNotesProvider = FutureProvider<List<NoteModel>>((ref) async {
  return ref.watch(noteRepositoryProvider).getRecentNotes(limit: 10);
});
