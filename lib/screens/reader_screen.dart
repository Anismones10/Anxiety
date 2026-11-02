import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_state.dart';
import '../book_info.dart';
import '../models/book.dart';
import '../models/highlight.dart';
import '../services/highlight_html.dart';
import '../utils/app_colors.dart';
import '../utils/gradient.dart';
import '../widgets/book_html.dart';
import '../widgets/highlight_editor.dart';
import '../widgets/settings_sheet.dart';

/// Where to scroll when a tab opens.
/// `fraction`: 0 = top, 1 = bottom of the page.
/// `target`: true for a search result (shown a bit below the top),
/// false for "continue reading" (same relative place as before).
class ScrollStart {
  final double fraction;
  final bool target;

  const ScrollStart(this.fraction, {this.target = false});
}

/// The part of the tab html to mark (yellow) for a search result.
class SearchMark {
  final int start;
  final int end;

  const SearchMark(this.start, this.end);
}

/// The route (page) of the reader.
Route<void> readerRoute(
  AppState app,
  int sectionIndex, {
  int tab = 0,
  ScrollStart? start,
  SearchMark? mark,
}) {
  return MaterialPageRoute<void>(
    builder: (_) => ReaderScreen(
      app: app,
      sectionIndex: sectionIndex,
      initialTab: tab,
      start: start,
      mark: mark,
    ),
  );
}

/// Opens the reader on a section (intro or chapter) and a tab.
void openReader(
  BuildContext context,
  AppState app,
  int sectionIndex, {
  int tab = 0,
  ScrollStart? start,
  SearchMark? mark,
}) {
  Navigator.push(
    context,
    readerRoute(app, sectionIndex, tab: tab, start: start, mark: mark),
  );
}

/// Shows one section with tabs at the top.
class ReaderScreen extends StatefulWidget {
  final AppState app;
  final int sectionIndex;
  final int initialTab;
  final ScrollStart? start;
  final SearchMark? mark;

  const ReaderScreen({
    super.key,
    required this.app,
    required this.sectionIndex,
    this.initialTab = 0,
    this.start,
    this.mark,
  });

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final int _firstTab; // the tab we opened on
  late int _lastTab; // the tab we saved last
  ScrollStart? _start; // used once, by the first tab
  SearchMark? _mark; // yellow mark (until the user removes it)

  Section get _section => widget.app.book.sections[widget.sectionIndex];

  @override
  void initState() {
    super.initState();
    final count = _section.tabs.length;
    _firstTab = widget.initialTab.clamp(0, count - 1);
    _lastTab = _firstTab;
    _start = widget.start;
    _mark = widget.mark;

    _tabController = TabController(
      length: count,
      vsync: this,
      initialIndex: _firstTab,
    );
    _tabController.addListener(_onTabChanged);

    // Remember this place (we wait for the end of the frame, because the
    // home screen listens to it and must not be changed while building).
    // When we are resuming, the saved place is already right.
    final resuming = widget.start != null && !widget.start!.target;
    if (!resuming) {
      final fraction = widget.start?.fraction ?? 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.app.progress.save(widget.sectionIndex, _firstTab, fraction);
      });
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    final index = _tabController.index;
    if (index == _lastTab) return;
    _lastTab = index;
    widget.app.progress.save(widget.sectionIndex, index, 0);
  }

  Future<void> _toggleBookmark() async {
    final nowSaved = await widget.app.bookmarks
        .toggle(widget.sectionIndex, _tabController.index);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(nowSaved ? 'نشانک ذخیره شد' : 'نشانک حذف شد'),
          duration: const Duration(milliseconds: 1500),
        ),
      );
  }

  /// Go to another tab (same chapter) or another chapter.
  void _goTo(int section, int tab) {
    if (section == widget.sectionIndex) {
      _tabController.animateTo(tab);
    } else {
      Navigator.pushReplacement(
        context,
        readerRoute(widget.app, section, tab: tab),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.app.settings;
    final bookmarks = widget.app.bookmarks;
    final colors = sectionColors(_section.color);

    return Scaffold(
      backgroundColor: AppColors.of(context).surface,
      appBar: AppBar(
        backgroundColor: colors.first,
        foregroundColor: Colors.white,
        title: Text(
          _section.fullTitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold),
        ),
        actions: [
          // The bookmark icon changes when the tab or the bookmarks change.
          ListenableBuilder(
            listenable: Listenable.merge([bookmarks, _tabController]),
            builder: (context, _) {
              final saved = bookmarks.isBookmarked(
                widget.sectionIndex,
                _tabController.index,
              );
              return IconButton(
                icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border),
                tooltip: saved ? 'حذف نشانک' : 'ذخیرهٔ نشانک',
                onPressed: _toggleBookmark,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.text_fields),
            tooltip: 'تنظیمات',
            onPressed: () => showSettingsSheet(context, settings),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: const Color(0xFFC9A961),
          tabs: [for (final t in _section.tabs) Tab(text: t.name)],
        ),
      ),
      // Button to remove the yellow mark of a search result.
      floatingActionButton: _mark == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => setState(() => _mark = null),
              icon: const Icon(Icons.highlight_off),
              label: const Text('حذف علامت'),
            ),
      body: ListenableBuilder(
        listenable: settings,
        builder: (context, _) {
          return TabBarView(
            controller: _tabController,
            children: [
              for (var i = 0; i < _section.tabs.length; i++)
                _TabPage(
                  // The key makes sure a new page is built for each tab.
                  key: ValueKey('${widget.sectionIndex}-$i'),
                  app: widget.app,
                  sectionIndex: widget.sectionIndex,
                  tabIndex: i,
                  mark: i == _firstTab ? _mark : null,
                  start: i == _firstTab ? _start : null,
                  onStartUsed: () => _start = null,
                  onGo: _goTo,
                ),
            ],
          );
        },
      ),
    );
  }
}

/// One tab page: the text, buttons for the previous / next topic,
/// copy with citation, saving the reading place.
class _TabPage extends StatefulWidget {
  final AppState app;
  final int sectionIndex;
  final int tabIndex;
  final SearchMark? mark;
  final ScrollStart? start;
  final VoidCallback onStartUsed;
  final void Function(int section, int tab) onGo;

  const _TabPage({
    super.key,
    required this.app,
    required this.sectionIndex,
    required this.tabIndex,
    required this.mark,
    required this.start,
    required this.onStartUsed,
    required this.onGo,
  });

  @override
  State<_TabPage> createState() => _TabPageState();
}

class _TabPageState extends State<_TabPage> {
  final ScrollController _scroll = ScrollController();
  String _selectedText = '';

  List<Section> get _sections => widget.app.book.sections;
  Section get _section => _sections[widget.sectionIndex];

  @override
  void initState() {
    super.initState();
    final start = widget.start;
    if (start != null) {
      // After the first layout, the page height is known: scroll there.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _applyStart(start);
        widget.onStartUsed();
      });
    }

    // A short page (no scrolling needed) counts as read if it stays open
    // for 2 seconds. (A page that is only seen for a moment while the reader
    // swipes between tabs is closed before that, so it does not count.)
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted || !_scroll.hasClients) return;
      if (_scroll.position.maxScrollExtent <= 0) {
        widget.app.progress.markRead(widget.sectionIndex, widget.tabIndex);
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _applyStart(ScrollStart start) {
    if (!mounted || !_scroll.hasClients) return;
    final p = _scroll.position;
    double offset;
    if (start.target) {
      // Search result: the text is at this height of the whole page.
      final total = p.maxScrollExtent + p.viewportDimension;
      offset = start.fraction * total - p.viewportDimension * 0.3;
    } else {
      // Continue reading: same relative place as before.
      offset = start.fraction * p.maxScrollExtent;
    }
    _scroll.jumpTo(offset.clamp(0.0, p.maxScrollExtent).toDouble());
  }

  /// When scrolling stops, save how far down the reader is.
  bool _onScroll(ScrollNotification n) {
    if (n is ScrollEndNotification && n.depth == 0) {
      final m = n.metrics;
      final fraction = m.maxScrollExtent <= 0
          ? 0.0
          : (m.pixels / m.maxScrollExtent).clamp(0.0, 1.0).toDouble();
      widget.app.progress.save(widget.sectionIndex, widget.tabIndex, fraction);
    }
    return false;
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(milliseconds: 2200),
        ),
      );
  }

  // ---- previous / next topic ----

  ({int section, int tab})? get _prev {
    if (widget.tabIndex > 0) {
      return (section: widget.sectionIndex, tab: widget.tabIndex - 1);
    }
    if (widget.sectionIndex > 0) {
      final s = widget.sectionIndex - 1;
      return (section: s, tab: _sections[s].tabs.length - 1);
    }
    return null;
  }

  ({int section, int tab})? get _next {
    if (widget.tabIndex < _section.tabs.length - 1) {
      return (section: widget.sectionIndex, tab: widget.tabIndex + 1);
    }
    if (widget.sectionIndex < _sections.length - 1) {
      return (section: widget.sectionIndex + 1, tab: 0);
    }
    return null;
  }

  /// Name shown on the button: the tab name, plus the chapter if it changes.
  String _label(({int section, int tab}) target) {
    final section = _sections[target.section];
    final tabName = section.tabs[target.tab].name;
    return target.section == widget.sectionIndex
        ? tabName
        : '${section.fullTitle} › $tabName';
  }

  // ---- highlights and notes ----

  /// The part of the page the reader is looking at (0 = top, 1 = bottom).
  double _visibleCenterFraction() {
    if (!_scroll.hasClients) return 0.5;
    final p = _scroll.position;
    final total = p.maxScrollExtent + p.viewportDimension;
    if (total <= 0) return 0;
    return ((p.pixels + p.viewportDimension / 2) / total)
        .clamp(0.0, 1.0)
        .toDouble();
  }

  /// The html of this tab with the saved highlights (and the search mark).
  String _buildHtml() {
    final search = widget.app.search;
    final tab = search.textOf(widget.sectionIndex, widget.tabIndex);
    if (tab == null) return _section.tabs[widget.tabIndex].content;

    final spans = <HighlightSpan>[];
    for (final h
        in widget.app.highlights.forTab(widget.sectionIndex, widget.tabIndex)) {
      final range = search.resolve(h);
      if (range == null) continue;
      spans.add(
        HighlightSpan(
          id: h.id,
          color: h.color,
          hasNote: h.note.isNotEmpty,
          start: range.start,
          end: range.end,
        ),
      );
    }
    return buildTabHtml(
      tab,
      spans,
      markStart: widget.mark?.start,
      markEnd: widget.mark?.end,
    );
  }

  /// The reader selected some text and pressed "highlight" or "note".
  void _startHighlight(String selected, {required bool quick}) {
    final search = widget.app.search;
    final highlights = widget.app.highlights;
    final tab = search.textOf(widget.sectionIndex, widget.tabIndex);
    final range = tab == null
        ? null
        : search.locateSelection(
            widget.sectionIndex,
            widget.tabIndex,
            selected,
            _visibleCenterFraction(),
          );
    if (tab == null || range == null) {
      _toast('این بخش پیدا نشد. بخش کوچک‌تری را انتخاب کنید.');
      return;
    }

    // Do not mark the same text twice.
    for (final h in highlights.forTab(widget.sectionIndex, widget.tabIndex)) {
      final other = search.resolve(h);
      if (other != null && other.start < range.end && range.start < other.end) {
        _toast('این بخش قبلاً هایلایت شده است. روی آن بزنید تا ویرایش شود.');
        return;
      }
    }

    final text = tab.plain.substring(range.start, range.end);
    showHighlightEditor(
      context,
      text: text,
      initialColor: 0,
      quick: quick,
      isEdit: false,
      onSave: (color, note) {
        highlights.add(
          Highlight(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            section: widget.sectionIndex,
            tab: widget.tabIndex,
            start: range.start,
            end: range.end,
            text: text,
            color: color,
            note: note,
            createdAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );
      },
    );
  }

  /// The reader tapped a highlight: show its note, change color, or delete.
  Future<bool> _onTapUrl(String url) async {
    if (!url.startsWith('hl:')) return false;
    final parts = url.split(':');
    if (parts.length < 2) return true;
    final highlights = widget.app.highlights;
    final h = highlights.byId(parts[1]);
    if (h == null || !mounted) return true;

    showHighlightEditor(
      context,
      text: h.text,
      initialColor: h.color,
      initialNote: h.note,
      quick: false,
      isEdit: true,
      onSave: (color, note) =>
          highlights.update(h.copyWith(color: color, note: note)),
      onDelete: () => highlights.remove(h.id),
    );
    return true;
  }

  // ---- text menu: copy with citation, highlight, note ----

  Widget _menu(BuildContext context, SelectableRegionState state) {
    final items = <ContextMenuButtonItem>[];
    for (final item in state.contextMenuButtonItems) {
      if (item.type == ContextMenuButtonType.copy &&
          widget.app.settings.copyWithCitation) {
        // Replace the normal "copy" with "copy + citation".
        items.add(
          ContextMenuButtonItem(
            type: ContextMenuButtonType.copy,
            onPressed: () {
              _copyWithCitation();
              state.hideToolbar();
            },
          ),
        );
      } else {
        items.add(item);
      }
    }

    // Highlight and note buttons (only when some text is selected).
    if (_selectedText.trim().isNotEmpty) {
      final selected = _selectedText;
      items.add(
        ContextMenuButtonItem(
          label: 'هایلایت',
          onPressed: () {
            state.hideToolbar();
            _startHighlight(selected, quick: true);
          },
        ),
      );
      items.add(
        ContextMenuButtonItem(
          label: 'یادداشت',
          onPressed: () {
            state.hideToolbar();
            _startHighlight(selected, quick: false);
          },
        ),
      );
    }

    return AdaptiveTextSelectionToolbar.buttonItems(
      anchors: state.contextMenuAnchors,
      buttonItems: items,
    );
  }

  Future<void> _copyWithCitation() async {
    final text = _selectedText.trim();
    if (text.isEmpty) return;
    final tabName = _section.tabs[widget.tabIndex].name;
    final citation =
        '— «$bookTitle»، $authorFullName، ${_section.fullTitle}، $tabName';
    await Clipboard.setData(ClipboardData(text: '$text\n\n$citation'));
    if (!mounted) return;
    _toast('متن همراه با ارجاع کپی شد');
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.app.settings;
    final prev = _prev;
    final next = _next;

    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: SingleChildScrollView(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // The text is drawn again when a highlight is added or changed.
            ListenableBuilder(
              listenable: widget.app.highlights,
              builder: (context, _) {
                // SelectionArea: the reader can select and copy the text.
                return SelectionArea(
                  onSelectionChanged: (content) {
                    _selectedText = content?.plainText ?? '';
                  },
                  contextMenuBuilder: _menu,
                  child: BookHtml(
                    html: _buildHtml(),
                    settings: settings,
                    onTapUrl: _onTapUrl,
                  ),
                );
              },
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: prev == null
                      ? const SizedBox.shrink()
                      : _NavButton(
                          title: 'مبحث قبلی',
                          label: _label(prev),
                          icon: Icons.chevron_left,
                          iconFirst: true,
                          onTap: () => widget.onGo(prev.section, prev.tab),
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: next == null
                      ? const SizedBox.shrink()
                      : _NavButton(
                          title: 'مبحث بعدی',
                          label: _label(next),
                          icon: Icons.chevron_right,
                          iconFirst: false,
                          onTap: () => widget.onGo(next.section, next.tab),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Button for the previous / next topic.
class _NavButton extends StatelessWidget {
  final String title;
  final String label;
  final IconData icon;
  final bool iconFirst;
  final VoidCallback onTap;

  const _NavButton({
    required this.title,
    required this.label,
    required this.icon,
    required this.iconFirst,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ui = AppColors.of(context);
    final radius = BorderRadius.circular(12);
    final iconWidget = Icon(icon, color: ui.accent);

    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: ui.background,
          borderRadius: radius,
          border: Border.all(color: ui.divider),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            child: Row(
              children: [
                if (iconFirst) iconWidget,
                Expanded(
                  child: Column(
                    crossAxisAlignment: iconFirst
                        ? CrossAxisAlignment.start
                        : CrossAxisAlignment.end,
                    children: [
                      Text(
                        title,
                        style: TextStyle(color: ui.muted, fontSize: 11.5),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        label,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: ui.accent,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!iconFirst) iconWidget,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
