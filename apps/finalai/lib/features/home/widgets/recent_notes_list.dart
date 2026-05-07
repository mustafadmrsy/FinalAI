import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/notes_provider.dart';
import '../../notes/widgets/note_list_section.dart';

class RecentNotesList extends ConsumerWidget {
  const RecentNotesList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = ref.watch(recentNotesProvider);

    return NoteListSection(
      title: 'Son notlar',
      notes: notes,
      onChanged: () => ref.invalidate(recentNotesProvider),
      showHeader: false,
    );
  }
}
