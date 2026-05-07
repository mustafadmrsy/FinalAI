import 'package:core_ui/core_ui.dart';
import 'package:flutter/material.dart';

import '../../data/onboarding_options.dart';
import '../tasks/task_helpers.dart';

// ═══════════════════════════════════════════════════════════
//  SUBJECT SELECT STEP — Kategori → Alt Dal secimi (pixel art)
// ═══════════════════════════════════════════════════════════

class SubjectSelectStep extends StatefulWidget {
  const SubjectSelectStep({
    super.key,
    required this.query,
    required this.selectedSubject,
    required this.onQueryChanged,
    required this.onSubjectSelected,
  });

  final String query;
  final String? selectedSubject;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onSubjectSelected;

  @override
  State<SubjectSelectStep> createState() => _SubjectSelectStepState();
}

class _SubjectSelectStepState extends State<SubjectSelectStep> {
  int? _expandedIndex;

  @override
  Widget build(BuildContext context) {
    final px = Px.of(context);
    final q = widget.query.trim().toLowerCase();
    final isSearching = q.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text('Ne ogrenmek istiyorsun?', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: px.text)),
        const SizedBox(height: 6),
        Text('Bir kategori sec, sonra alt dalini belirle.', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: px.textMuted)),
        const SizedBox(height: 16),
        // Search bar — pixel style
        Container(
          decoration: px.cardDeco(depth: 3),
          child: AppTextField(
            label: '',
            hint: 'Ara: Python, Fizik, Almanca...',
            prefixIcon: Icons.search_rounded,
            onChanged: widget.onQueryChanged,
          ),
        ),
        const SizedBox(height: 16),

        if (isSearching)
          // Arama modunda flat liste goster
          ..._buildSearchResults(px, q)
        else
          // Kategori dropdown modunda
          ..._buildCategoryCards(px),
      ],
    );
  }

  // ── Arama sonuclari (flat) ────────────────────────────
  List<Widget> _buildSearchResults(Px px, String q) {
    final all = OnboardingOptions.subjects;
    final filtered = all.where((s) => s.name.toLowerCase().contains(q)).toList();
    if (filtered.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Center(child: Text('Sonuc bulunamadi', style: TextStyle(color: px.textMuted, fontWeight: FontWeight.w700, fontSize: 14))),
        ),
      ];
    }
    return filtered.map((s) => _SubjectTile(
      subject: s,
      selected: widget.selectedSubject == s.name,
      onTap: () => widget.onSubjectSelected(s.name),
    )).toList();
  }

  // ── Kategori kartlari (expandable) ────────────────────
  List<Widget> _buildCategoryCards(Px px) {
    return List.generate(OnboardingOptions.categories.length, (i) {
      final cat = OnboardingOptions.categories[i];
      final isExpanded = _expandedIndex == i;
      final hasSelected = cat.subjects.any((s) => s.name == widget.selectedSubject);

      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(children: [
          // Kategori basligi
          GestureDetector(
            onTap: () => setState(() => _expandedIndex = isExpanded ? null : i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isExpanded ? px.accentBg(cat.color) : px.card,
                borderRadius: BorderRadius.vertical(top: const Radius.circular(14), bottom: isExpanded ? Radius.zero : const Radius.circular(14)),
                border: Border.all(color: isExpanded ? cat.color : (hasSelected ? cat.color : px.border), width: 2),
                boxShadow: isExpanded
                    ? []
                    : [BoxShadow(color: hasSelected ? cat.color.withAlpha(40) : px.shadow, offset: const Offset(0, 3), blurRadius: 0)],
              ),
              child: Row(children: [
                // Kategori ikonu
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: cat.color.withAlpha(isExpanded ? 40 : 25),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: cat.color.withAlpha(60), width: 1.5),
                  ),
                  child: Icon(cat.icon, color: cat.color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(cat.name, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: isExpanded ? cat.color : px.text)),
                  Text('${cat.subjects.length} alt dal', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: px.textMuted)),
                ])),
                if (hasSelected && !isExpanded)
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(color: cat.color, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
                  ),
                const SizedBox(width: 6),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.keyboard_arrow_down_rounded, color: isExpanded ? cat.color : px.textMuted, size: 24),
                ),
              ]),
            ),
          ),
          // Alt dallar — expandable
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Container(
              decoration: BoxDecoration(
                color: px.card,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                border: Border(
                  left: BorderSide(color: cat.color, width: 2),
                  right: BorderSide(color: cat.color, width: 2),
                  bottom: BorderSide(color: cat.color, width: 2),
                ),
                boxShadow: [BoxShadow(color: cat.color.withAlpha(30), offset: const Offset(0, 3), blurRadius: 0)],
              ),
              child: Column(children: cat.subjects.map((s) {
                final selected = widget.selectedSubject == s.name;
                return _SubjectTile(
                  subject: s,
                  selected: selected,
                  compact: true,
                  onTap: () => widget.onSubjectSelected(s.name),
                );
              }).toList()),
            ),
            crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ]),
      );
    });
  }
}

// ═══════════════════════════════════════════════════════════
//  SUBJECT TILE — tek bir konu secimi (pixel art)
// ═══════════════════════════════════════════════════════════

class _SubjectTile extends StatelessWidget {
  const _SubjectTile({required this.subject, required this.selected, this.compact = false, required this.onTap});
  final SubjectItem subject;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final px = Px.of(context);
    final c = subject.color;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: compact ? 14 : 16, vertical: compact ? 10 : 14),
        margin: compact ? EdgeInsets.zero : const EdgeInsets.only(bottom: 10),
        decoration: compact
            ? BoxDecoration(
                color: selected ? px.accentBg(c) : px.card,
                border: Border(bottom: BorderSide(color: selected ? c.withAlpha(40) : px.border.withAlpha(60), width: 1)),
              )
            : BoxDecoration(
                color: selected ? px.accentBg(c) : px.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: selected ? c : px.border, width: 2),
                boxShadow: [BoxShadow(color: selected ? c.withAlpha(40) : px.shadow, offset: const Offset(0, 3), blurRadius: 0)],
              ),
        child: Row(children: [
          Container(
            width: compact ? 34 : 42,
            height: compact ? 34 : 42,
            decoration: BoxDecoration(
              color: c.withAlpha(selected ? 40 : 20),
              borderRadius: BorderRadius.circular(compact ? 8 : 11),
            ),
            child: Icon(subject.icon, color: c, size: compact ? 18 : 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(
            subject.name,
            style: TextStyle(fontWeight: selected ? FontWeight.w900 : FontWeight.w700, fontSize: compact ? 13 : 15, color: selected ? c : px.text),
          )),
          if (selected)
            Container(
              width: 26, height: 26,
              decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
            )
          else
            Icon(Icons.chevron_right_rounded, color: px.textMuted, size: 20),
        ]),
      ),
    );
  }
}
