import 'package:flutter/material.dart';

import '../../learning_path/widgets/tasks/task_helpers.dart';
import '../models/avatar_model.dart';
import '../data/avatar_parts.dart';
import '../widgets/avatar_widget.dart';

// ═══════════════════════════════════════════════════════════════
//  AVATAR EDITOR — Duolingo-style character customization screen
// ═══════════════════════════════════════════════════════════════

class AvatarEditorScreen extends StatefulWidget {
  const AvatarEditorScreen({super.key, required this.initial, required this.onSave});
  final AvatarModel initial;
  final ValueChanged<AvatarModel> onSave;

  @override
  State<AvatarEditorScreen> createState() => _AvatarEditorScreenState();
}

class _AvatarEditorScreenState extends State<AvatarEditorScreen> with SingleTickerProviderStateMixin {
  late AvatarModel _avatar;
  late TabController _tabCtrl;

  static const _tabs = ['Cinsiyet', 'Cilt', 'Sac', 'Gozler', 'Kaslar', 'Agiz', 'Kiyafet', 'Aksesuar'];
  static const _bgColors = [
    PxDecor.blue, PxDecor.purple, PxDecor.teal, PxDecor.green,
    PxDecor.orange, PxDecor.red, Color(0xFF2A2A3E), Color(0xFF1A1A2E),
  ];

  @override
  void initState() {
    super.initState();
    _avatar = widget.initial;
    _tabCtrl = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  void _update(AvatarModel Function(AvatarModel) fn) => setState(() => _avatar = fn(_avatar));

  @override
  Widget build(BuildContext context) {
    final px = Px.of(context);

    return Scaffold(
      backgroundColor: px.bg,
      body: SafeArea(
        child: Column(children: [
          // ── Top bar ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: px.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: px.border, width: 2), boxShadow: [BoxShadow(color: px.shadow, offset: const Offset(0, 3), blurRadius: 0)]),
                  child: Icon(Icons.close_rounded, size: 20, color: px.textMuted),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text('Avatar Duzenle', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: px.text))),
              GestureDetector(
                onTap: () { widget.onSave(_avatar); Navigator.of(context).pop(); },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: PxDecor.green,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: PxDecor.greenDark, width: 2),
                    boxShadow: [BoxShadow(color: PxDecor.greenDark, offset: const Offset(0, 3), blurRadius: 0)],
                  ),
                  child: const Text('Kaydet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                ),
              ),
            ]),
          ),
          const SizedBox(height: 16),

          // ── Avatar preview ──
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: px.heroDeco(_bgColors[_avatar.bgColor.clamp(0, _bgColors.length - 1)], HSLColor.fromColor(_bgColors[_avatar.bgColor.clamp(0, _bgColors.length - 1)]).withLightness(0.3).toColor()),
            child: Center(child: AvatarWidget(avatar: _avatar, size: 140)),
          ),
          const SizedBox(height: 8),
          // ── Background color picker ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Text('Arkaplan', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: px.textMuted)),
              const SizedBox(width: 10),
              Expanded(child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: List.generate(_bgColors.length, (i) {
                  final sel = _avatar.bgColor == i;
                  return GestureDetector(
                    onTap: () => _update((a) => a.copyWith(bgColor: i)),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 28, height: 28,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: _bgColors[i],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: sel ? Colors.white : Colors.transparent, width: 2),
                        boxShadow: sel ? [BoxShadow(color: _bgColors[i], blurRadius: 6)] : null,
                      ),
                      child: sel ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
                    ),
                  );
                })),
              )),
            ]),
          ),
          const SizedBox(height: 10),

          // ── Category tabs ──
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: px.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: px.border, width: 2),
            ),
            child: TabBar(
              controller: _tabCtrl,
              isScrollable: true,
              labelColor: PxDecor.blue,
              unselectedLabelColor: px.textMuted,
              labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
              indicatorColor: PxDecor.blue,
              indicatorWeight: 3,
              dividerColor: Colors.transparent,
              tabAlignment: TabAlignment.start,
              tabs: _tabs.map((t) => Tab(text: t)).toList(),
            ),
          ),
          const SizedBox(height: 12),

          // ── Tab content ──
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _GenderTab(avatar: _avatar, onUpdate: _update, px: px),
                _SkinTab(avatar: _avatar, onUpdate: _update, px: px),
                _HairTab(avatar: _avatar, onUpdate: _update, px: px),
                _EyeTab(avatar: _avatar, onUpdate: _update, px: px),
                _EyebrowTab(avatar: _avatar, onUpdate: _update, px: px),
                _MouthTab(avatar: _avatar, onUpdate: _update, px: px),
                _OutfitTab(avatar: _avatar, onUpdate: _update, px: px),
                _AccessoryTab(avatar: _avatar, onUpdate: _update, px: px),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
//  Gender Tab
// ═══════════════════════════════════════════════════
class _GenderTab extends StatelessWidget {
  const _GenderTab({required this.avatar, required this.onUpdate, required this.px});
  final AvatarModel avatar;
  final void Function(AvatarModel Function(AvatarModel)) onUpdate;
  final Px px;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(children: [
        Expanded(child: _genderCard(AvatarGender.male, Icons.male_rounded, 'Erkek', PxDecor.blue)),
        const SizedBox(width: 12),
        Expanded(child: _genderCard(AvatarGender.female, Icons.female_rounded, 'Kadin', PxDecor.purple)),
      ]),
    );
  }

  Widget _genderCard(AvatarGender g, IconData icon, String label, Color color) {
    final selected = avatar.gender == g;
    return GestureDetector(
      onTap: () => onUpdate((a) => a.copyWith(gender: g, hairStyle: 0)),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: selected
            ? px.heroDeco(color, HSLColor.fromColor(color).withLightness(0.35).toColor())
            : px.cardDeco(),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 48, color: selected ? Colors.white : px.textMuted),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: selected ? Colors.white : px.text)),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════
//  Skin Tab
// ═══════════════════════════════════════════════════
class _SkinTab extends StatelessWidget {
  const _SkinTab({required this.avatar, required this.onUpdate, required this.px});
  final AvatarModel avatar;
  final void Function(AvatarModel Function(AvatarModel)) onUpdate;
  final Px px;

  @override
  Widget build(BuildContext context) {
    return _ColorGrid(
      colors: AvatarParts.skinTones,
      selected: avatar.skinTone,
      onSelect: (i) => onUpdate((a) => a.copyWith(skinTone: i)),
      px: px,
      label: 'Cilt Tonu',
    );
  }
}

// ═══════════════════════════════════════════════════
//  Hair Tab
// ═══════════════════════════════════════════════════
class _HairTab extends StatelessWidget {
  const _HairTab({required this.avatar, required this.onUpdate, required this.px});
  final AvatarModel avatar;
  final void Function(AvatarModel Function(AvatarModel)) onUpdate;
  final Px px;

  @override
  Widget build(BuildContext context) {
    final styles = avatar.gender == AvatarGender.male ? AvatarParts.hairStylesMale : AvatarParts.hairStylesFemale;
    return ListView(padding: const EdgeInsets.symmetric(horizontal: 20), children: [
      Text('Sac Stili', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: px.text)),
      const SizedBox(height: 10),
      Wrap(spacing: 10, runSpacing: 10, children: List.generate(styles.length, (i) {
        final sel = avatar.hairStyle == i;
        final preview = avatar.copyWith(hairStyle: i);
        return GestureDetector(
          onTap: () => onUpdate((a) => a.copyWith(hairStyle: i)),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 80, height: 100,
            decoration: sel ? px.heroDeco(PxDecor.teal, PxDecor.tealDark, depth: 3) : px.cardDeco(depth: 3),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              ClipRect(child: SizedBox(width: 50, height: 58, child: AvatarWidget(avatar: preview, size: 44))),
              const SizedBox(height: 2),
              Text(styles[i], style: TextStyle(fontWeight: FontWeight.w800, fontSize: 9, color: sel ? Colors.white : px.text), maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
        );
      })),
      const SizedBox(height: 20),
      Text('Sac Rengi', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: px.text)),
      const SizedBox(height: 10),
      _buildColorRow(AvatarParts.hairColors, avatar.hairColor, (i) => onUpdate((a) => a.copyWith(hairColor: i))),
    ]);
  }

  Widget _buildColorRow(List<Color> colors, int selected, ValueChanged<int> onSelect) {
    return Wrap(spacing: 10, runSpacing: 10, children: List.generate(colors.length, (i) {
      final sel = selected == i;
      return GestureDetector(
        onTap: () => onSelect(i),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: colors[i],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: sel ? Colors.white : Colors.transparent, width: 3),
            boxShadow: [
              BoxShadow(color: colors[i].withAlpha(sel ? 120 : 60), offset: const Offset(0, 3), blurRadius: 0),
              if (sel) BoxShadow(color: PxDecor.blue, offset: Offset.zero, blurRadius: 0, spreadRadius: 2),
            ],
          ),
          child: sel ? const Icon(Icons.check_rounded, color: Colors.white, size: 20) : null,
        ),
      );
    }));
  }
}

// ═══════════════════════════════════════════════════
//  Eye Tab
// ═══════════════════════════════════════════════════
class _EyeTab extends StatelessWidget {
  const _EyeTab({required this.avatar, required this.onUpdate, required this.px});
  final AvatarModel avatar;
  final void Function(AvatarModel Function(AvatarModel)) onUpdate;
  final Px px;

  @override
  Widget build(BuildContext context) {
    return _AvatarPreviewGrid(
      labels: AvatarParts.eyeStyles,
      selected: avatar.eyeStyle,
      onSelect: (i) => onUpdate((a) => a.copyWith(eyeStyle: i)),
      previewBuilder: (i) => avatar.copyWith(eyeStyle: i),
      px: px,
      label: 'Goz Stili',
      color: PxDecor.purple,
    );
  }
}

// ═══════════════════════════════════════════════════
//  Eyebrow Tab
// ═══════════════════════════════════════════════════
class _EyebrowTab extends StatelessWidget {
  const _EyebrowTab({required this.avatar, required this.onUpdate, required this.px});
  final AvatarModel avatar;
  final void Function(AvatarModel Function(AvatarModel)) onUpdate;
  final Px px;

  @override
  Widget build(BuildContext context) {
    return _AvatarPreviewGrid(
      labels: AvatarParts.eyebrowStyles,
      selected: avatar.eyebrowStyle,
      onSelect: (i) => onUpdate((a) => a.copyWith(eyebrowStyle: i)),
      previewBuilder: (i) => avatar.copyWith(eyebrowStyle: i),
      px: px,
      label: 'Kas Stili',
      color: PxDecor.teal,
    );
  }
}

// ═══════════════════════════════════════════════════
//  Mouth Tab
// ═══════════════════════════════════════════════════
class _MouthTab extends StatelessWidget {
  const _MouthTab({required this.avatar, required this.onUpdate, required this.px});
  final AvatarModel avatar;
  final void Function(AvatarModel Function(AvatarModel)) onUpdate;
  final Px px;

  @override
  Widget build(BuildContext context) {
    return _AvatarPreviewGrid(
      labels: AvatarParts.mouthStyles,
      selected: avatar.mouthStyle,
      onSelect: (i) => onUpdate((a) => a.copyWith(mouthStyle: i)),
      previewBuilder: (i) => avatar.copyWith(mouthStyle: i),
      px: px,
      label: 'Agiz Stili',
      color: PxDecor.orange,
    );
  }
}

// ═══════════════════════════════════════════════════
//  Outfit Tab
// ═══════════════════════════════════════════════════
class _OutfitTab extends StatelessWidget {
  const _OutfitTab({required this.avatar, required this.onUpdate, required this.px});
  final AvatarModel avatar;
  final void Function(AvatarModel Function(AvatarModel)) onUpdate;
  final Px px;

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.symmetric(horizontal: 20), children: [
      Text('Kiyafet Tipi', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: px.text)),
      const SizedBox(height: 10),
      Wrap(spacing: 10, runSpacing: 10, children: List.generate(AvatarParts.outfits.length, (i) {
        final sel = avatar.outfit == i;
        final preview = avatar.copyWith(outfit: i);
        return GestureDetector(
          onTap: () => onUpdate((a) => a.copyWith(outfit: i)),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 80, height: 100,
            decoration: sel ? px.heroDeco(PxDecor.green, PxDecor.greenDark, depth: 3) : px.cardDeco(depth: 3),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              ClipRect(child: SizedBox(width: 50, height: 58, child: AvatarWidget(avatar: preview, size: 44))),
              const SizedBox(height: 2),
              Text(AvatarParts.outfits[i], style: TextStyle(fontWeight: FontWeight.w800, fontSize: 9, color: sel ? Colors.white : px.text), maxLines: 1, overflow: TextOverflow.ellipsis),
            ]),
          ),
        );
      })),
      const SizedBox(height: 20),
      Text('Kiyafet Rengi', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: px.text)),
      const SizedBox(height: 10),
      Wrap(spacing: 10, runSpacing: 10, children: List.generate(AvatarParts.outfitColors.length, (i) {
        final sel = avatar.outfitColor == i;
        return GestureDetector(
          onTap: () => onUpdate((a) => a.copyWith(outfitColor: i)),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: AvatarParts.outfitColors[i],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: sel ? Colors.white : Colors.transparent, width: 3),
              boxShadow: [
                BoxShadow(color: AvatarParts.outfitColors[i].withAlpha(sel ? 120 : 60), offset: const Offset(0, 3), blurRadius: 0),
                if (sel) BoxShadow(color: PxDecor.blue, offset: Offset.zero, blurRadius: 0, spreadRadius: 2),
              ],
            ),
            child: sel ? const Icon(Icons.check_rounded, color: Colors.white, size: 20) : null,
          ),
        );
      })),
    ]);
  }
}

// ═══════════════════════════════════════════════════
//  Accessory Tab
// ═══════════════════════════════════════════════════
class _AccessoryTab extends StatelessWidget {
  const _AccessoryTab({required this.avatar, required this.onUpdate, required this.px});
  final AvatarModel avatar;
  final void Function(AvatarModel Function(AvatarModel)) onUpdate;
  final Px px;

  @override
  Widget build(BuildContext context) {
    return _AvatarPreviewGrid(
      labels: AvatarParts.accessories,
      selected: avatar.accessory + 1,
      onSelect: (i) => onUpdate((a) => a.copyWith(accessory: i - 1)),
      previewBuilder: (i) => avatar.copyWith(accessory: i - 1),
      px: px,
      label: 'Aksesuar',
      color: PxDecor.gold,
    );
  }
}

// ═══════════════════════════════════════════════════
//  Shared widgets
// ═══════════════════════════════════════════════════

class _ColorGrid extends StatelessWidget {
  const _ColorGrid({required this.colors, required this.selected, required this.onSelect, required this.px, required this.label});
  final List<Color> colors;
  final int selected;
  final ValueChanged<int> onSelect;
  final Px px;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: px.text)),
        const SizedBox(height: 14),
        Wrap(spacing: 12, runSpacing: 12, children: List.generate(colors.length, (i) {
          final sel = selected == i;
          return GestureDetector(
            onTap: () => onSelect(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: colors[i],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: sel ? Colors.white : Colors.transparent, width: 3),
                boxShadow: [
                  BoxShadow(color: colors[i].withAlpha(sel ? 120 : 60), offset: const Offset(0, 4), blurRadius: 0),
                  if (sel) BoxShadow(color: PxDecor.blue, offset: Offset.zero, blurRadius: 0, spreadRadius: 2),
                ],
              ),
              child: sel ? const Icon(Icons.check_rounded, color: Colors.white, size: 24) : null,
            ),
          );
        })),
      ]),
    );
  }
}

class _AvatarPreviewGrid extends StatelessWidget {
  const _AvatarPreviewGrid({required this.labels, required this.selected, required this.onSelect, required this.previewBuilder, required this.px, required this.label, required this.color});
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelect;
  final AvatarModel Function(int index) previewBuilder;
  final Px px;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final dark = HSLColor.fromColor(color).withLightness(0.35).toColor();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: px.text)),
        const SizedBox(height: 14),
        Wrap(spacing: 10, runSpacing: 10, children: List.generate(labels.length, (i) {
          final sel = selected == i;
          final preview = previewBuilder(i);
          return GestureDetector(
            onTap: () => onSelect(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 80, height: 100,
              decoration: sel ? px.heroDeco(color, dark, depth: 3) : px.cardDeco(depth: 3),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                ClipRect(child: SizedBox(width: 50, height: 58, child: AvatarWidget(avatar: preview, size: 44))),
                const SizedBox(height: 2),
                Text(labels[i], style: TextStyle(fontWeight: FontWeight.w800, fontSize: 9, color: sel ? Colors.white : px.text), maxLines: 1, overflow: TextOverflow.ellipsis),
              ]),
            ),
          );
        })),
      ]),
    );
  }
}
