import 'search_index.dart';

/// A highlight, with its place in the readable text of a tab.
class HighlightSpan {
  final String id;
  final int color;
  final bool hasNote;
  final int start; // place in the readable text
  final int end;

  const HighlightSpan({
    required this.id,
    required this.color,
    required this.hasNote,
    required this.start,
    required this.end,
  });
}

class _Insert {
  final int position; // place in the html
  final String text; // the tag to add
  final bool closing;

  const _Insert(this.position, this.text, this.closing);
}

/// Returns the html of a tab with the highlights (and a search mark) added
/// as tags around the text. Only tags are added, the text is never changed.
/// This is used for display only; the original html is not touched.
String buildTabHtml(
  TabText tab,
  List<HighlightSpan> spans, {
  int? markStart,
  int? markEnd,
}) {
  final inserts = <_Insert>[];
  final covered = <(int, int)>[]; // html ranges that have a highlight

  for (final span in spans) {
    for (final run in _runs(tab, span.start, span.end)) {
      final open = '<a href="hl:${span.id}:${span.color}:${span.hasNote ? 1 : 0}">';
      inserts.add(_Insert(run.$1, open, false));
      inserts.add(_Insert(run.$2, '</a>', true));
      covered.add(run);
    }
  }

  // Search result mark (skipped if it touches a highlight).
  if (markStart != null &&
      markEnd != null &&
      markStart < markEnd &&
      markEnd <= tab.html.length) {
    final touches = covered.any((r) => r.$1 < markEnd && markStart < r.$2);
    if (!touches) {
      inserts.add(_Insert(markStart, '<mark>', false));
      inserts.add(_Insert(markEnd, '</mark>', true));
    }
  }

  if (inserts.isEmpty) return tab.html;

  // Add the tags from the end to the start, so earlier places do not move.
  // At the same place, closing tags must come before opening tags.
  inserts.sort((a, b) {
    final byPosition = b.position.compareTo(a.position);
    if (byPosition != 0) return byPosition;
    return (a.closing ? 1 : 0).compareTo(b.closing ? 1 : 0);
  });

  var html = tab.html;
  for (final insert in inserts) {
    html = html.substring(0, insert.position) +
        insert.text +
        html.substring(insert.position);
  }
  return html;
}

/// Cuts a range of the readable text into pieces that do not cross html tags
/// (a tag cannot be opened in one paragraph and closed in another).
/// Returns html ranges: (start, end).
List<(int, int)> _runs(TabText tab, int start, int end) {
  final html = tab.html;
  final runs = <(int, int)>[];
  int? runStart;
  var runLast = 0; // html position of the last letter in the current run

  for (var p = start; p < end && p < tab.plain.length; p++) {
    final h = tab.htmlIndex[p];

    // A space that stands for a tag (end of paragraph...): end the run.
    if (html[h] == '<') {
      if (runStart != null) {
        runs.add((runStart, runLast + 1));
        runStart = null;
      }
      continue;
    }

    if (runStart == null) {
      runStart = h;
      runLast = h;
      continue;
    }

    // Same run if nothing (or only spaces) is between the two letters.
    final gap = html.substring(runLast + 1, h);
    if (gap.trim().isEmpty) {
      runLast = h;
    } else {
      runs.add((runStart, runLast + 1));
      runStart = h;
      runLast = h;
    }
  }
  if (runStart != null) runs.add((runStart, runLast + 1));
  return runs;
}
