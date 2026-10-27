import 'package:flutter/material.dart';
import '../data/app_state.dart';
import '../data/content.dart';
import '../data/models.dart';
import 'duo.dart';
import 'fi_sticker.dart';
import 'widgets.dart';

/// Vocab list & Hafal list — A–Z groups, search, per-word & per-group mark.
/// [knownTab] = true shows the "Hafal" variant (default filter different summary).
class VocabScreen extends StatefulWidget {
  final AppState state;
  final ContentRepository content;
  final bool knownTab;
  const VocabScreen({super.key, required this.state, required this.content, this.knownTab = false});

  @override
  State<VocabScreen> createState() => _VocabScreenState();
}

class _VocabScreenState extends State<VocabScreen> {
  final _search = TextEditingController();

  AppState get S => widget.state;
  ContentRepository get R => widget.content;
  String get _filter => widget.knownTab ? S.kf : S.vf;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: S,
      builder: (context, _) {
        final q = _search.text.toLowerCase();
        final filtered = R.vocab.where((v) {
          final k = S.isKnown(v.id);
          if (_filter == 'belum' && k) return false;
          if (_filter == 'sudah' && !k) return false;
          return ContentRepository.matches(v, q);
        }).toList();
        final groups = ContentRepository.alphaGroups(filtered);
        final knownCount = R.vocab.where((v) => S.isKnown(v.id)).length;

        return Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Column(children: [
              if (widget.knownTab)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text.rich(TextSpan(children: [
                    TextSpan(text: '$knownCount', style: duoFont(size: 13, weight: FontWeight.w900, color: Duo.green)),
                    TextSpan(text: ' memorized • ', style: duoFont(size: 13, weight: FontWeight.w700, color: Duo.textLight)),
                    TextSpan(text: '${R.vocab.length - knownCount}', style: duoFont(size: 13, weight: FontWeight.w900, color: Duo.orange)),
                    TextSpan(text: ' not yet • ${R.vocab.length} total', style: duoFont(size: 13, weight: FontWeight.w700, color: Duo.textLight)),
                  ])),
                ),
              Row(children: [
                _filterChip('belum', 'Not memorized'),
                const SizedBox(width: 8),
                _filterChip('sudah', 'Memorized'),
                if (!widget.knownTab) ...[const SizedBox(width: 8), _filterChip('semua', 'All')],
              ]),
              const SizedBox(height: 10),
              TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                style: duoFont(size: 14, weight: FontWeight.w700),
                decoration: InputDecoration(
                  hintText: 'Search hanzi / pinyin / meaning…',
                  hintStyle: duoFont(size: 14, weight: FontWeight.w600, color: Duo.textLight),
                  prefixIcon: const Icon(Icons.search_rounded, color: Duo.textLight),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Theme.of(context).dividerColor, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Theme.of(context).dividerColor, width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: Duo.blue, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Showing ${filtered.length} words • ${groups.length} groups${q.isNotEmpty ? ' (search)' : ''}',
                  style: duoFont(size: 11.5, weight: FontWeight.w700, color: Duo.textLight),
                ),
              ),
            ]),
          ),
          Expanded(
            child: filtered.isEmpty
                ? _emptyState()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                    children: [for (final g in groups) _group(context, g)],
                  ),
          ),
        ]);
      },
    );
  }

  Widget _emptyState() {
    final searching = _search.text.isNotEmpty;
    final String title;
    final String sub;
    final Widget sticker;
    if (searching) {
      title = 'No words match';
      sub = 'Try a different search or clear the filter.';
      sticker = const FiSticker.loupe();
    } else if (widget.knownTab) {
      title = 'Nothing here yet';
      sub = 'Mark words as known and they will show up here.';
      sticker = const FiSticker.sprout();
    } else {
      title = 'No words in this filter';
      sub = 'Try another filter or search.';
      sticker = const FiSticker.loupe();
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          sticker,
          const SizedBox(height: 10),
          Text(title, style: duoFont(size: 17, weight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(sub, textAlign: TextAlign.center,
              style: duoFont(size: 13, weight: FontWeight.w600, color: Duo.textLight)),
        ]),
      ),
    );
  }

  Widget _filterChip(String f, String label) {
    final active = _filter == f;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => widget.knownTab ? S.kf = f : S.vf = f);
          S.save();
        },
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: active ? Duo.green : Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border(
              top: BorderSide(color: active ? Duo.greenDark : Theme.of(context).dividerColor, width: 2),
              left: BorderSide(color: active ? Duo.greenDark : Theme.of(context).dividerColor, width: 2),
              right: BorderSide(color: active ? Duo.greenDark : Theme.of(context).dividerColor, width: 2),
              bottom: BorderSide(color: active ? Duo.greenDark : Theme.of(context).dividerColor, width: 4),
            ),
          ),
          child: Text(label.toUpperCase(),
              style: duoFont(size: 11, weight: FontWeight.w900, color: active ? Colors.white : Duo.textLight)),
        ),
      ),
    );
  }

  Widget _group(BuildContext context, MapEntry<String, List<VocabWord>> g) {
    final list = g.value;
    final allKnown = list.every((v) => S.isKnown(v.id));
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DuoCard(
        padding: EdgeInsets.zero,
        child: Column(children: [
          // header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor, width: 2)),
            ),
            child: Row(children: [
              Container(
                width: 30, height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: Duo.green, borderRadius: BorderRadius.circular(10)),
                child: Text(g.key, style: duoFont(size: 15, weight: FontWeight.w900, color: Colors.white)),
              ),
              const SizedBox(width: 8),
              Text('${list.length} words', style: duoFont(size: 12, weight: FontWeight.w800, color: Duo.textLight)),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  S.markGroup(list.map((v) => v.id), !allKnown);
                  duoToast(context, '${allKnown ? '↩️' : '✅'} ${list.length} words ${allKnown ? 'unmarked' : 'marked as known'}');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Duo.greenLight.withValues(alpha: .5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Duo.green, width: 2),
                  ),
                  child: Text(allKnown ? '↩️ Undo' : '✅ Know it',
                      style: duoFont(size: 11, weight: FontWeight.w900, color: Duo.greenDark)),
                ),
              ),
            ]),
          ),
          // rows
          ...list.map((v) {
            final k = S.isKnown(v.id);
            final lv = S.wordLevel(v.id);
            return InkWell(
              onTap: () => _openWord(v),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                child: Row(children: [
                  SizedBox(width: 28, child: Text('${v.id}', style: duoFont(size: 11, weight: FontWeight.w800, color: Duo.textLight))),
                  const SizedBox(width: 8),
                  Text(v.hanzi, style: duoFont(size: 17, weight: FontWeight.w800)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('${v.pinyin}  •  ${v.meaning.length > 24 ? '${v.meaning.substring(0, 24)}…' : v.meaning}',
                        overflow: TextOverflow.ellipsis,
                        style: duoFont(size: 12, weight: FontWeight.w600, color: Duo.textLight)),
                  ),
                  _dot(lv),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => S.toggleKnown(v.id),
                    child: Container(
                      width: 30, height: 30,
                      decoration: BoxDecoration(
                        color: k ? Duo.greenLight : Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: k ? Duo.green : Theme.of(context).dividerColor, width: 2),
                      ),
                      child: Center(child: Text(k ? '↩️' : '✅', style: const TextStyle(fontSize: 13))),
                    ),
                  ),
                ]),
              ),
            );
          }),
        ]),
      ),
    );
  }

  Widget _dot(double l) {
    final c = l >= 3 ? Duo.green : (l >= 1 ? Duo.blue : Duo.border);
    return Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle));
  }

  void _openWord(VocabWord v) {
    // show a detail bottom sheet (PWA jumps to flashcard; sheet is faster here)
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: .8,
        expand: false,
        builder: (_, scroll) => _WordDetail(word: v, scroll: scroll, state: S, content: R),
      ),
    );
  }
}

class _WordDetail extends StatelessWidget {
  final VocabWord word;
  final ScrollController scroll;
  final AppState state;
  final ContentRepository content;
  const _WordDetail({required this.word, required this.scroll, required this.state, required this.content});

  @override
  Widget build(BuildContext context) {
    final rad = content.radicalFor(word.hanzi);
    return ListView(controller: scroll, padding: const EdgeInsets.all(20), children: [
      Center(child: Text(word.hanzi, style: duoFont(size: 52, weight: FontWeight.w900))),
      Center(child: Text(word.pinyin, style: duoFont(size: 19, weight: FontWeight.w800, color: Duo.blue))),
      const SizedBox(height: 6),
      Center(child: Text(word.meaning, textAlign: TextAlign.center, style: duoFont(size: 16, weight: FontWeight.w800))),
      if (word.traditional != word.hanzi)
        Center(child: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text('Traditional: ${word.traditional}', style: duoFont(size: 12, weight: FontWeight.w700, color: Duo.textLight)),
        )),
      if (rad != null)
        Center(child: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text('Radical: ${rad.radical} (${rad.pinyin}) — ${rad.meaning}',
              style: duoFont(size: 12, weight: FontWeight.w700, color: Duo.textLight)),
        )),
      const SizedBox(height: 14),
      Text('Example Sentences (tap a character for details):', style: duoFont(size: 12, weight: FontWeight.w900, color: Duo.textLight)),
      const SizedBox(height: 8),
      ...word.sentences.asMap().entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: DuoCard(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text('${e.key + 1}.', style: duoFont(size: 12, weight: FontWeight.w800, color: Duo.textLight)),
                  const SizedBox(width: 6),
                  Expanded(child: HanziText(e.value.hanzi, fontSize: 15)),
                ]),
                const SizedBox(height: 3),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(e.value.pinyin, style: duoFont(size: 12, weight: FontWeight.w700, color: Duo.blue)),
                    Text(e.value.en, style: duoFont(size: 12, weight: FontWeight.w600, color: Duo.textLight)),
                  ]),
                ),
              ]),
            ),
          )),
    ]);
  }
}
