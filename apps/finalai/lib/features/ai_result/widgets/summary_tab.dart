import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/repositories/repository_providers.dart';
import '../providers/note_detail_provider.dart';

class SummaryTab extends ConsumerWidget {
  const SummaryTab({super.key, required this.noteId});

  final String noteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final note = ref.watch(noteDetailProvider(noteId));

    return note.when(
      loading: () => const LoadingIndicator(message: 'Özet yükleniyor...'),
      error: (e, _) => EmptyState(
        title: 'Özet yüklenemedi',
        message: e.toString(),
        icon: Icons.error_outline,
      ),
      data: (data) {
        final summaryShortRaw = data['summary_short'];
        final short = summaryShortRaw is List
            ? summaryShortRaw.cast<dynamic>()
            : summaryShortRaw is String
                ? summaryShortRaw.split('\n').where((l) => l.trim().isNotEmpty).toList()
                : null;
        final long = data['summary_long'] as String?;

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Row(
              children: [
                Expanded(child: Text('Kısa özet', style: AppTypography.titleMedium)),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () => _editSummaryShort(context, ref, noteId, short),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            BaseCard(
              child: (short == null || short.isEmpty)
                  ? const Text('Kısa özet bulunamadı.')
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: short
                          .map((e) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text('- ${e.toString()}', style: AppTypography.bodyMedium),
                              ))
                          .toList(),
                    ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(child: Text('Detaylı özet', style: AppTypography.titleMedium)),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () => _editSummaryLong(context, ref, noteId, long ?? ''),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (long == null || long.trim().isEmpty)
              const BaseCard(
                child: Text('Detaylı özet bulunamadı.'),
              )
            else
              _buildExpandableSummary(long, data),
          ],
        );
      },
    );
  }

  Future<void> _editSummaryShort(
    BuildContext context,
    WidgetRef ref,
    String noteId,
    List<dynamic>? current,
  ) async {
    final controller = TextEditingController(
      text: current?.map((e) => e.toString()).join('\n') ?? '',
    );

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Kısa Özeti Düzenle'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Her satır bir madde',
            border: OutlineInputBorder(),
          ),
          maxLines: 10,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );

    if (result != null) {
      final lines = result.split('\n').where((l) => l.trim().isNotEmpty).toList();
      await ref.watch(noteRepositoryProvider).updateNoteSummary(
            noteId: noteId,
            summaryShort: lines.join('\n'),
          );
      ref.invalidate(noteDetailProvider(noteId));
    }
    controller.dispose();
  }

  Future<void> _editSummaryLong(
    BuildContext context,
    WidgetRef ref,
    String noteId,
    String current,
  ) async {
    final controller = TextEditingController(text: current);

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Detaylı Özeti Düzenle'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Detaylı açıklama',
            border: OutlineInputBorder(),
          ),
          maxLines: 15,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );

    if (result != null) {
      await ref.watch(noteRepositoryProvider).updateNoteSummary(
            noteId: noteId,
            summaryLong: result,
          );
      ref.invalidate(noteDetailProvider(noteId));
    }
    controller.dispose();
  }

  Widget _buildExpandableSummary(String longSummary, Map<String, dynamic> data) {
    // Parse summary into sections based on paragraphs or topics
    final sections = _parseSummaryIntoSections(longSummary, data);

    if (sections.isEmpty) {
      return BaseCard(
        child: Builder(builder: (context) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Text(
            longSummary,
            style: AppTypography.bodyMedium.copyWith(color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight),
          );
        }),
      );
    }

    return Column(
      children: sections.asMap().entries.map((entry) {
        final index = entry.key;
        final section = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: _ExpandableSection(
            title: section['title'] as String,
            content: section['content'] as String,
            icon: _getSectionIcon(index),
            initiallyExpanded: index == 0,
          ),
        );
      }).toList(),
    );
  }

  List<Map<String, String>> _parseSummaryIntoSections(String summary, Map<String, dynamic> data) {
    final sections = <Map<String, String>>[];

    // Try to get key concepts for section titles
    final keyConcepts = data['key_concepts'] as List<dynamic>?;
    final mainTopic = data['main_topic'] as String?;

    // Split by double newlines (paragraphs)
    final paragraphs = summary.split('\n\n').where((p) => p.trim().isNotEmpty).toList();

    if (paragraphs.length <= 1) {
      // Single paragraph - split by sentences if too long
      if (summary.length > 500) {
        final sentences = summary.split('. ');
        final chunks = <String>[];
        String current = '';
        
        for (final sentence in sentences) {
          if ((current + sentence).length > 400 && current.isNotEmpty) {
            chunks.add(current.trim());
            current = sentence;
          } else {
            current += (current.isEmpty ? '' : '. ') + sentence;
          }
        }
        if (current.isNotEmpty) chunks.add(current.trim());

        for (int i = 0; i < chunks.length; i++) {
          sections.add({
            'title': i == 0 ? 'Genel Bakış' : 'Devamı ${i + 1}',
            'content': chunks[i],
          });
        }
      }
      return sections;
    }

    // Multiple paragraphs - use them as sections
    for (int i = 0; i < paragraphs.length; i++) {
      String title;
      if (i == 0 && mainTopic != null) {
        title = mainTopic;
      } else if (keyConcepts != null && i - 1 < keyConcepts.length) {
        title = keyConcepts[i - 1].toString();
      } else {
        // Try to extract title from first line
        final lines = paragraphs[i].split('\n');
        if (lines.first.length < 50 && lines.length > 1) {
          title = lines.first;
          sections.add({
            'title': title,
            'content': lines.skip(1).join('\n').trim(),
          });
          continue;
        }
        title = 'Bölüm ${i + 1}';
      }

      sections.add({
        'title': title,
        'content': paragraphs[i].trim(),
      });
    }

    return sections;
  }

  IconData _getSectionIcon(int index) {
    final icons = [
      Icons.lightbulb_outline,
      Icons.school_outlined,
      Icons.psychology_outlined,
      Icons.science_outlined,
      Icons.functions_outlined,
      Icons.calculate_outlined,
      Icons.description_outlined,
      Icons.article_outlined,
    ];
    return icons[index % icons.length];
  }
}

class _ExpandableSection extends StatefulWidget {
  const _ExpandableSection({
    required this.title,
    required this.content,
    required this.icon,
    this.initiallyExpanded = false,
  });

  final String title;
  final String content;
  final IconData icon;
  final bool initiallyExpanded;

  @override
  State<_ExpandableSection> createState() => _ExpandableSectionState();
}

class _ExpandableSectionState extends State<_ExpandableSection> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return BaseCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      widget.icon,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Builder(builder: (context) {
                final isDark = Theme.of(context).brightness == Brightness.dark;
                return Text(
                  widget.content,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? AppColors.textPrimary : AppColors.textPrimaryLight,
                    height: 1.6,
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }
}
