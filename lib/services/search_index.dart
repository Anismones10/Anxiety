import '../models/book.dart';
import '../models/highlight.dart';

/// One search result: the text around the match, split in 3 parts
/// so the screen can highlight the middle part.
class SearchHit {
  final int section;
  final int tab;
  final String before;
  final String match;
  final String after;

  /// Where the match is in the tab: 0 = top, 1 = bottom (used to scroll there).
  final double fraction;

  /// Position of the match inside the tab's html (used to mark it on screen).
  /// Null if the match crosses html tags and cannot be marked safely.
  final int? markStart;
  final int? markEnd;

  const SearchHit({
    required this.section,
    required this.tab,
    required this.before,
    required this.match,
    required this.after,
    required this.fraction,
    this.markStart,
    this.markEnd,
  });
}

/// Readable text of one html page + where each letter is in the html.
class _Plain {
  final String text;
  final List<int> htmlIndex; // plain position -> html position
  const _Plain(this.text, this.htmlIndex);
}

/// Text of one tab: the html, the readable text, and helpers for finding.
class TabText {
  final int section;
  final int tab;
  final String html; // original html
  final String plain; // readable text (original letters)
  final List<int> htmlIndex; // plain position -> html position
  final String norm; // simplified text, used only for finding
  final List<int> map; // norm position -> plain position

  const TabText(
    this.section,
    this.tab,
    this.html,
    this.plain,
    this.htmlIndex,
    this.norm,
    this.map,
  );
}

class _Normalized {
  final String text;
  final List<int> map;
  const _Normalized(this.text, this.map);
}

/// Simplifies ONE character. Returns '' if the character should be ignored.
/// This is only for searching. The text on the screen is never changed.
String _normChar(int c) {
  // Invisible marks, tatweel
  if (c == 0x200C || c == 0x200D || c == 0x200E || c == 0x200F) return '';
  if (c == 0x0640) return '';
  // Harakat (zabar, zir, pesh, shadda...) and Quran marks
  if (c >= 0x064B && c <= 0x065F) return '';
  if (c == 0x0670) return '';
  if (c >= 0x06D6 && c <= 0x06ED) return '';
  // Arabic letters -> Persian letters
  if (c == 0x064A || c == 0x0649) return 'ی';
  if (c == 0x0643) return 'ک';
  if (c == 0x06C0 || c == 0x0629) return 'ه';
  if (c == 0x0623 || c == 0x0625 || c == 0x0671) return 'ا';
  // Persian and Arabic digits -> 0-9
  if (c >= 0x06F0 && c <= 0x06F9) return String.fromCharCode(c - 0x06F0 + 0x30);
  if (c >= 0x0660 && c <= 0x0669) return String.fromCharCode(c - 0x0660 + 0x30);

  final ch = String.fromCharCode(c);
  if (ch.trim().isEmpty) return ''; // spaces: ignored, so "می شود" = "میشود"
  return ch.toLowerCase();
}

_Normalized _normalize(String s) {
  final buffer = StringBuffer();
  final map = <int>[];
  for (var i = 0; i < s.length; i++) {
    final out = _normChar(s.codeUnitAt(i));
    buffer.write(out);
    for (var k = 0; k < out.length; k++) {
      map.add(i);
    }
  }
  return _Normalized(buffer.toString(), map);
}

/// Does this tag (the text between < and >) separate words?
/// For example <br>, the end of a paragraph, or a verse reference.
bool _tagMakesSpace(String tag) {
  if (tag.startsWith('br')) return true;
  if (!tag.startsWith('/') && tag.contains('ayah-ref')) return true;
  return RegExp(r'^/(p|div|li|ul|ol|h[1-6])\b').hasMatch(tag);
}

/// Turns the html of a tab into readable text (no tags),
/// and remembers where each letter came from in the html.
_Plain _toPlain(String html) {
  final text = StringBuffer();
  final index = <int>[];
  var lastWasSpace = true; // true at the start, so no space at the beginning

  void addSpace(int pos) {
    if (lastWasSpace) return;
    text.write(' ');
    index.add(pos);
    lastWasSpace = true;
  }

  void addChar(String ch, int pos) {
    text.write(ch);
    index.add(pos);
    lastWasSpace = false;
  }

  var i = 0;
  while (i < html.length) {
    final ch = html[i];
    if (ch == '<') {
      final close = html.indexOf('>', i);
      if (close == -1) {
        addChar(ch, i); // broken html: keep it as text
        i++;
        continue;
      }
      final tag = html.substring(i + 1, close).toLowerCase();
      if (_tagMakesSpace(tag)) addSpace(i);
      i = close + 1;
      continue;
    }
    if (ch.trim().isEmpty) {
      addSpace(i);
    } else {
      addChar(ch, i);
    }
    i++;
  }

  var result = text.toString();
  if (lastWasSpace && result.isNotEmpty) {
    result = result.substring(0, result.length - 1);
    index.removeLast();
  }
  return _Plain(result, index);
}

/// Search over the whole book.
class SearchIndex {
  final List<TabText> _entries;
  final Map<String, TabText> _byKey;

  SearchIndex._(this._entries)
      : _byKey = {for (final e in _entries) '${e.section}:${e.tab}': e};

  /// Builds the index once, when the app starts.
  factory SearchIndex.build(Book book) {
    final entries = <TabText>[];
    final sections = book.sections;
    for (var s = 0; s < sections.length; s++) {
      final tabs = sections[s].tabs;
      for (var t = 0; t < tabs.length; t++) {
        final html = tabs[t].content;
        final p = _toPlain(html);
        final n = _normalize(p.text);
        entries.add(TabText(s, t, html, p.text, p.htmlIndex, n.text, n.map));
      }
    }
    return SearchIndex._(entries);
  }

  /// The simplified form of what the user typed.
  static String normalizeQuery(String query) => _normalize(query).text;

  List<SearchHit> search(
    String query, {
    int maxHits = 300,
    int maxPerTab = 30,
  }) {
    final q = normalizeQuery(query);
    if (q.length < 2) return [];

    final hits = <SearchHit>[];
    for (final e in _entries) {
      var from = 0;
      var count = 0;
      while (hits.length < maxHits && count < maxPerTab) {
        final index = e.norm.indexOf(q, from);
        if (index < 0) break;
        final start = e.map[index];
        final end = e.map[index + q.length - 1] + 1;
        hits.add(_makeHit(e, start, end));
        count++;
        from = index + q.length;
      }
      if (hits.length >= maxHits) break;
    }
    return hits;
  }

  /// The text of a tab (null if there is no such tab).
  TabText? textOf(int section, int tab) => _byKey['$section:$tab'];

  /// Finds the selected text inside a tab and returns its place in the
  /// readable text. If the text appears more than once, we take the one
  /// closest to `nearFraction` (the part of the page the reader is looking at).
  ({int start, int end})? locateSelection(
    int section,
    int tab,
    String selected,
    double nearFraction,
  ) {
    final e = textOf(section, tab);
    if (e == null || e.plain.isEmpty) return null;

    // Remove list bullets that the screen may add to the selected text.
    final cleaned = selected.replaceAll(RegExp('[•◦▪‣∙·]'), '');
    final q = normalizeQuery(cleaned);
    if (q.length < 2) return null;

    int? best;
    var bestDistance = double.infinity;
    var from = 0;
    while (true) {
      final index = e.norm.indexOf(q, from);
      if (index < 0) break;
      final fraction = e.map[index] / e.plain.length;
      final distance = (fraction - nearFraction).abs();
      if (distance < bestDistance) {
        best = index;
        bestDistance = distance;
      }
      from = index + 1;
    }
    if (best == null) return null;
    return (start: e.map[best], end: e.map[best + q.length - 1] + 1);
  }

  /// The current place of a saved highlight in the readable text.
  /// If the book text changed since it was saved, we look for the saved
  /// text again, near the old place. Returns null if it is not found.
  ({int start, int end})? resolve(Highlight h) {
    final e = textOf(h.section, h.tab);
    if (e == null) return null;
    final wanted = _normalize(h.text).text;
    if (wanted.isEmpty) return null;

    // 1) The saved place is still right.
    if (h.start >= 0 && h.start < h.end && h.end <= e.plain.length) {
      final saved = _normalize(e.plain.substring(h.start, h.end)).text;
      if (saved == wanted) return (start: h.start, end: h.end);
    }

    // 2) Find the text again, closest to the old place.
    int? best;
    var bestDistance = 1 << 30;
    var from = 0;
    while (true) {
      final index = e.norm.indexOf(wanted, from);
      if (index < 0) break;
      final distance = (e.map[index] - h.start).abs();
      if (distance < bestDistance) {
        best = index;
        bestDistance = distance;
      }
      from = index + 1;
    }
    if (best == null) return null;
    return (start: e.map[best], end: e.map[best + wanted.length - 1] + 1);
  }

  /// Cuts the sentence around the match (about 45 letters before, 70 after).
  SearchHit _makeHit(TabText e, int matchStart, int matchEnd) {
    final plain = e.plain;
    var start = matchStart - 45 < 0 ? 0 : matchStart - 45;
    var end = matchEnd + 70 > plain.length ? plain.length : matchEnd + 70;

    // Do not cut words in the middle.
    if (start > 0) {
      final space = plain.indexOf(' ', start);
      if (space != -1 && space < matchStart) start = space + 1;
    }
    if (end < plain.length) {
      final space = plain.lastIndexOf(' ', end - 1);
      if (space > matchEnd) end = space;
    }

    // Position of the match in the html, so the reader can mark it.
    // If the match crosses a tag (like <strong>), we do not mark it.
    int? markStart = e.htmlIndex[matchStart];
    int? markEnd = e.htmlIndex[matchEnd - 1] + 1;
    final between = e.html.substring(markStart, markEnd);
    if (between.contains('<') || between.contains('>')) {
      markStart = null;
      markEnd = null;
    }

    return SearchHit(
      section: e.section,
      tab: e.tab,
      before: (start > 0 ? '… ' : '') + plain.substring(start, matchStart),
      match: plain.substring(matchStart, matchEnd),
      after: plain.substring(matchEnd, end) + (end < plain.length ? ' …' : ''),
      fraction: plain.isEmpty ? 0 : matchStart / plain.length,
      markStart: markStart,
      markEnd: markEnd,
    );
  }
}
