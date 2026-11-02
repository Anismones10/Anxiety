import 'package:flutter/material.dart';
import '../app_state.dart';
import '../services/search_index.dart';
import '../utils/app_colors.dart';
import 'reader_screen.dart';

/// Search in the whole book. Shows the sentence around each match.
class SearchScreen extends StatefulWidget {
  final AppState app;

  const SearchScreen({super.key, required this.app});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String _query = '';
  List<SearchHit> _hits = [];

  void _onChanged(String value) {
    setState(() {
      _query = value;
      _hits = widget.app.search.search(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final ui = AppColors.of(context);
    final sections = widget.app.book.sections;

    Widget body;
    if (SearchIndex.normalizeQuery(_query).length < 2) {
      body = const _Message('حداقل دو حرف بنویسید');
    } else if (_hits.isEmpty) {
      body = const _Message('نتیجه‌ای پیدا نشد');
    } else {
      body = ListView.separated(
        itemCount: _hits.length + 1,
        separatorBuilder: (context, index) =>
            Divider(height: 1, color: ui.divider),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                '${_hits.length} نتیجه',
                style: TextStyle(color: ui.muted),
              ),
            );
          }
          final hit = _hits[index - 1];
          final section = sections[hit.section];
          final tabName = section.tabs[hit.tab].name;
          return ListTile(
            onTap: () => openReader(
              context,
              widget.app,
              hit.section,
              tab: hit.tab,
              // Scroll to the match and mark it in yellow.
              start: ScrollStart(hit.fraction, target: true),
              mark: hit.markStart == null || hit.markEnd == null
                  ? null
                  : SearchMark(hit.markStart!, hit.markEnd!),
            ),
            title: Text(
              '${section.fullTitle}  ›  $tabName',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: ui.accent,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text.rich(
                TextSpan(
                  style: TextStyle(
                    color: ui.text,
                    height: 1.9,
                    fontSize: 14.5,
                  ),
                  children: [
                    TextSpan(text: hit.before),
                    TextSpan(
                      text: hit.match,
                      style: const TextStyle(
                        backgroundColor: Color(0xFFFFE082),
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(text: hit.after),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: ui.surface,
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          onChanged: _onChanged,
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: 'جستجو در کتاب...',
            border: InputBorder.none,
          ),
        ),
      ),
      body: body,
    );
  }
}

class _Message extends StatelessWidget {
  final String text;

  const _Message(this.text);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(text, style: TextStyle(color: AppColors.of(context).muted)),
    );
  }
}
