import 'package:flutter/material.dart';
import '../data/app_state.dart';
import '../data/content.dart';
import '../data/models.dart';
import 'duo.dart';

/// Radicals tab: search + 149-card grid + expandable detail card on top.
class RadicalsScreen extends StatefulWidget {
  final AppState state;
  final ContentRepository content;
  final void Function(String hanziWord) onJumpWord;
  const RadicalsScreen({super.key, required this.state, required this.content, required this.onJumpWord});

  @override
  State<RadicalsScreen> createState() => _RadicalsScreenState();
}

class _RadicalsScreenState extends State<RadicalsScreen> {
  final _search = TextEditingController();
  RadicalEntry? _selected;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _search.text.toLowerCase();
    final list = q.isEmpty
        ? widget.content.radicals
        : widget.content.radicals.where((r) =>
            r.radical.contains(q) ||
            r.pinyin.toLowerCase().contains(q) ||
            r.meaning.toLowerCase().contains(q) ||
            r.explanation.toLowerCase().contains(q)).toList();

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
        child: TextField(
          controller: _search,
          onChanged: (_) => setState(() {}),
          style: duoFont(size: 14, weight: FontWeight.w700),
          decoration: InputDecoration(
            hintText: 'Search radicals…',
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
      ),
      Expanded(
        child: ListView(padding: const EdgeInsets.all(16), children: [
          if (_selected != null) _detail(_selected!),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Center(
              child: Text('${list.length} radicals • covering ${widget.content.vocab.length} ${widget.content.levelLabel} words',
                  style: duoFont(size: 12, weight: FontWeight.w700, color: Duo.textLight)),
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 150,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: .92,
            ),
            itemCount: list.length,
            itemBuilder: (_, i) => _card(list[i]),
          ),
        ]),
      ),
    ]);
  }

  Widget _card(RadicalEntry r) {
    return DuoCard(
      padding: const EdgeInsets.all(10),
      onTap: () => setState(() => _selected = r),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(r.radical, style: duoFont(size: 30, weight: FontWeight.w800, height: 1.1)),
        const SizedBox(height: 4),
        Text(r.pinyin, style: duoFont(size: 12, weight: FontWeight.w800, color: Duo.blue)),
        Text(r.meaning, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: duoFont(size: 10.5, weight: FontWeight.w700, color: Duo.textLight, height: 1.2)),
        const SizedBox(height: 3),
        Text('${r.words.length} words', style: duoFont(size: 10, weight: FontWeight.w700, color: Duo.textLight)),
      ]),
    );
  }

  Widget _detail(RadicalEntry r) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DuoCard(
        child: Column(children: [
          Row(children: [
            const Spacer(),
            GestureDetector(
              onTap: () => setState(() => _selected = null),
              child: const Icon(Icons.close_rounded, color: Duo.textLight, size: 20),
            ),
          ]),
          Text(r.radical, style: duoFont(size: 52, weight: FontWeight.w900, height: 1)),
          const SizedBox(height: 4),
          Text('${r.pinyin} — ${r.meaning}', style: duoFont(size: 15, weight: FontWeight.w800)),
          if (r.variant.isNotEmpty)
            Text('full form: ${r.variant}', style: duoFont(size: 12, weight: FontWeight.w700, color: Duo.textLight)),
          if (r.explanation.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(r.explanation,
                  style: duoFont(size: 12.5, weight: FontWeight.w600, color: Duo.textLight, height: 1.4)),
            ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('${widget.content.levelLabel.toUpperCase()} CHARACTERS WITH THIS RADICAL (${r.chars.length})',
                style: duoFont(size: 11, weight: FontWeight.w900, color: Duo.textLight, spacing: .5)),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: r.chars.map((c) => Container(
                  width: 42, height: 42,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Theme.of(context).dividerColor, width: 2),
                  ),
                  child: Text(c, style: duoFont(size: 20, weight: FontWeight.w800)),
                )).toList(),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('${widget.content.levelLabel.toUpperCase()} WORDS USING IT (${r.words.length}) — TAP TO OPEN',
                style: duoFont(size: 11, weight: FontWeight.w900, color: Duo.textLight, spacing: .5)),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: r.words.map((w) => GestureDetector(
                  onTap: () => widget.onJumpWord(w),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: Duo.greenLight.withValues(alpha: .5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Duo.green, width: 2),
                    ),
                    child: Text(w, style: duoFont(size: 14, weight: FontWeight.w800, color: Duo.greenDark)),
                  ),
                )).toList(),
          ),
        ]),
      ),
    );
  }
}
