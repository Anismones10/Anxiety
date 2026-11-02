import 'package:flutter/material.dart';
import '../app_state.dart';
import '../models/highlight.dart';
import '../utils/app_colors.dart';
import '../utils/gradient.dart';
import '../utils/highlight_colors.dart';
import 'reader_screen.dart';

/// Bookmarks, highlights and notes, in three tabs.
class BookmarksScreen extends StatelessWidget {
  final AppState app;

  const BookmarksScreen({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    final ui = AppColors.of(context);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: ui.background,
        appBar: AppBar(
          title: const Text('نشانک‌ها و یادداشت‌ها'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'نشانک‌ها'),
              Tab(text: 'هایلایت‌ها'),
              Tab(text: 'یادداشت‌ها'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _BookmarksList(app: app),
            _HighlightsList(app: app, onlyNotes: false),
            _HighlightsList(app: app, onlyNotes: true),
          ],
        ),
      ),
    );
  }
}

/// Text shown when a list is empty.
class _EmptyMessage extends StatelessWidget {
  final String text;

  const _EmptyMessage(this.text);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.of(context).muted,
            height: 2,
          ),
        ),
      ),
    );
  }
}

/// Tab 1: saved bookmarks. Tap to open, trash icon to delete.
class _BookmarksList extends StatelessWidget {
  final AppState app;

  const _BookmarksList({required this.app});

  @override
  Widget build(BuildContext context) {
    final sections = app.book.sections;

    return ListenableBuilder(
      listenable: app.bookmarks,
      builder: (context, _) {
        // Newest first. Ignore bookmarks that point to a missing place.
        final items = app.bookmarks.items.reversed.where((b) {
          return b.section >= 0 &&
              b.section < sections.length &&
              b.tab >= 0 &&
              b.tab < sections[b.section].tabs.length;
        }).toList();

        if (items.isEmpty) {
          return const _EmptyMessage(
            'هنوز نشانکی ندارید.\nدر صفحهٔ خواندن، آیکن نشانک را بزنید.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final b = items[index];
            final section = sections[b.section];
            final colors = sectionColors(section.color);
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                onTap: () => openReader(context, app, b.section, tab: b.tab),
                leading: Icon(Icons.bookmark, color: colors.first),
                title: Text(
                  section.fullTitle,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(section.tabs[b.tab].name),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'حذف',
                  onPressed: () => app.bookmarks.remove(b),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// Tabs 2 and 3: highlights (all) and notes (only highlights with a note).
class _HighlightsList extends StatelessWidget {
  final AppState app;
  final bool onlyNotes;

  const _HighlightsList({required this.app, required this.onlyNotes});

  Future<void> _confirmDelete(BuildContext context, Highlight h) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(onlyNotes ? 'این یادداشت حذف شود؟' : 'این هایلایت حذف شود؟'),
        content: const Text('بعد از حذف، برگشتی ندارد.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('انصراف'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (ok == true) app.highlights.remove(h.id);
  }

  void _open(BuildContext context, Highlight h) {
    // Go to the place of the highlight in the page.
    final range = app.search.resolve(h);
    final tab = app.search.textOf(h.section, h.tab);
    final fraction = (range == null || tab == null || tab.plain.isEmpty)
        ? 0.0
        : range.start / tab.plain.length;
    openReader(
      context,
      app,
      h.section,
      tab: h.tab,
      start: ScrollStart(fraction, target: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ui = AppColors.of(context);
    final sections = app.book.sections;

    return ListenableBuilder(
      listenable: app.highlights,
      builder: (context, _) {
        // Newest first. Ignore items that point to a missing place.
        final items = app.highlights.items.reversed.where((h) {
          final valid = h.section >= 0 &&
              h.section < sections.length &&
              h.tab >= 0 &&
              h.tab < sections[h.section].tabs.length;
          return valid && (!onlyNotes || h.note.isNotEmpty);
        }).toList();

        if (items.isEmpty) {
          return _EmptyMessage(
            onlyNotes
                ? 'هنوز یادداشتی ندارید.\nدر صفحهٔ خواندن، متن را انتخاب کنید و «یادداشت» را بزنید.'
                : 'هنوز هایلایتی ندارید.\nدر صفحهٔ خواندن، متن را انتخاب کنید و «هایلایت» را بزنید.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final h = items[index];
            final section = sections[h.section];
            final place = '${section.fullTitle} › ${section.tabs[h.tab].name}';
            final hasNote = h.note.isNotEmpty;

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => _open(context, h),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Color bar of the highlight.
                      Container(width: 6, color: highlightColor(h.color, ui)),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // In the notes tab, the note comes first.
                              if (onlyNotes && hasNote)
                                Text(
                                  h.note,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    height: 1.8,
                                  ),
                                ),
                              Text(
                                h.text,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  height: 1.8,
                                  fontSize: onlyNotes ? 13 : 14.5,
                                  color: onlyNotes ? ui.muted : ui.text,
                                ),
                              ),
                              // In the highlights tab, a note is shown under the text.
                              if (!onlyNotes && hasNote) ...[
                                const SizedBox(height: 6),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.edit_note,
                                      size: 18,
                                      color: ui.accent,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        h.note,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: ui.accent,
                                          fontSize: 13,
                                          height: 1.7,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 6),
                              Text(
                                place,
                                style: TextStyle(color: ui.muted, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'حذف',
                        onPressed: () => _confirmDelete(context, h),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
