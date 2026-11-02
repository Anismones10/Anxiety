import 'package:flutter/material.dart';
import '../app_state.dart';
import '../book_info.dart';
import '../models/book.dart';
import '../utils/app_colors.dart';
import '../utils/gradient.dart';
import '../utils/persian_digits.dart';
import '../widgets/fade_slide_in.dart';
import '../widgets/geometric_pattern.dart';
import '../widgets/glow_border.dart';
import '../widgets/settings_sheet.dart';
import 'about_screen.dart';
import 'bookmarks_screen.dart';
import 'reader_screen.dart';
import 'search_screen.dart';

/// Home screen: cover + colored cards (intro and chapters).
class HomeScreen extends StatelessWidget {
  final AppState app;

  const HomeScreen({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    final sections = app.book.sections;
    final ui = AppColors.of(context);

    return Scaffold(
      backgroundColor: ui.background,
      appBar: AppBar(
        title: const Text('اضطراب در قرآن'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'جستجو',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SearchScreen(app: app)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.bookmarks_outlined),
            tooltip: 'نشانک‌ها و یادداشت‌ها',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => BookmarksScreen(app: app)),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.text_fields),
            tooltip: 'تنظیمات',
            onPressed: () => showSettingsSheet(context, app.settings),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'دربارهٔ برنامه',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AboutScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const FadeSlideIn(child: _CoverCard()),
          const SizedBox(height: 16),
          // "Continue reading": shown only after the reader has opened something.
          ListenableBuilder(
            listenable: app.progress,
            builder: (context, _) {
              final p = app.progress;
              final valid = p.hasProgress &&
                  p.section < sections.length &&
                  p.tab < sections[p.section].tabs.length;
              if (!valid) return const SizedBox.shrink();
              final section = sections[p.section];

              // How many parts (tabs) of the book are read, out of all parts.
              var total = 0;
              var read = 0;
              for (var si = 0; si < sections.length; si++) {
                for (var ti = 0; ti < sections[si].tabs.length; ti++) {
                  total++;
                  if (p.isRead(si, ti)) read++;
                }
              }

              return _ContinueCard(
                subtitle: '${section.fullTitle} › ${section.tabs[p.tab].name}',
                readCount: read,
                totalCount: total,
                onTap: () => openReader(
                  context,
                  app,
                  p.section,
                  tab: p.tab,
                  start: ScrollStart(p.fraction),
                ),
              );
            },
          ),
          // Each card starts a little later than the one before it.
          for (var i = 0; i < sections.length; i++)
            FadeSlideIn(
              delay: Duration(milliseconds: 150 * (i + 1)),
              child: _SectionCard(
                section: sections[i],
                icon: _sectionIcon(i),
                // Big faint chapter number (the intro has none).
                number: i == 0 ? null : toPersianDigits('$i'),
                // Different start time, so the cards do not shine together.
                phase: i * 0.17,
                onTap: () => openReader(context, app, i),
              ),
            ),
        ],
      ),
    );
  }
}

/// Cover card at the top. The texts are copied from the original HTML.
class _CoverCard extends StatelessWidget {
  const _CoverCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF0D3A6B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFC9A961), width: 2),
      ),
      child: Stack(
        // The texts are placed in the middle of the card.
        alignment: Alignment.center,
        children: [
          // Very light geometric pattern behind the texts.
          const Positioned.fill(
            child: GeometricPattern(color: Color(0x14FFFFFF)),
          ),
          // Full width, so the texts are centered in the whole card
          // (not only inside the width of the longest line).
          const SizedBox(
            width: double.infinity,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 28, horizontal: 20),
              child: Column(
              children: [
                Text(
                  bookTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    height: 1.7,
                  ),
                ),
                SizedBox(height: 14),
                Text(
                  researcherLine,
                  style: TextStyle(color: Color(0xFFC9A961), height: 1.9),
                ),
                Text(
                  supervisorLine,
                  style: TextStyle(color: Colors.white, height: 1.9),
                ),
                Text(
                  universityLine,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12.5,
                    height: 1.9,
                  ),
                ),
              ],
            ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Card "Continue reading": goes back to the last place, with a progress bar.
class _ContinueCard extends StatelessWidget {
  final String subtitle;
  final int readCount;
  final int totalCount;
  final VoidCallback onTap;

  const _ContinueCard({
    required this.subtitle,
    required this.readCount,
    required this.totalCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ui = AppColors.of(context);
    final radius = BorderRadius.circular(14);
    final progress = totalCount == 0 ? 0.0 : readCount / totalCount;
    final readText = toPersianDigits('$readCount');
    final totalText = toPersianDigits('$totalCount');

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlowBorder(
        radius: 14,
        color: const Color(0xFFC9A961),
        child: Material(
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              color: ui.surface,
              borderRadius: radius,
              border: Border.all(color: const Color(0xFFC9A961), width: 1.5),
            ),
            child: InkWell(
              borderRadius: radius,
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Icon(
                      Icons.play_circle_outline,
                      color: Color(0xFFC9A961),
                      size: 34,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'ادامهٔ مطالعه',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: ui.muted, fontSize: 12.5),
                          ),
                          const SizedBox(height: 10),
                          // Progress in the whole book.
                          Row(
                            children: [
                              Expanded(
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 5,
                                  borderRadius: BorderRadius.circular(3),
                                  color: const Color(0xFFC9A961),
                                  backgroundColor: ui.divider,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '$readText از $totalText بخش خوانده شد',
                                style: TextStyle(
                                  color: ui.muted,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.chevron_right, color: ui.muted),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Icon of each card: intro, then chapter 1, 2, 3, 4 (same order as the book).
const List<IconData> _sectionIcons = [
  Icons.auto_stories_outlined, // مقدمات کتاب
  Icons.psychology_outlined, // کلیات و مفاهیم اضطراب
  Icons.account_tree_outlined, // ریشه‌های اضطراب
  Icons.healing_outlined, // درمان اضطراب
  Icons.library_books_outlined, // نتیجه‌گیری و فهرست منابع
];

IconData _sectionIcon(int index) {
  return index < _sectionIcons.length
      ? _sectionIcons[index]
      : Icons.menu_book_outlined;
}

/// One colored card: icon, big faint number, and a slow light on the edge.
class _SectionCard extends StatelessWidget {
  final Section section;
  final IconData icon;
  final String? number;
  final double phase;
  final VoidCallback onTap;

  const _SectionCard({
    required this.section,
    required this.icon,
    required this.number,
    required this.phase,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = sectionColors(section.color);
    final radius = BorderRadius.circular(14);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlowBorder(
        radius: 14,
        phase: phase,
        child: Material(
          color: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: colors,
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: radius,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x26000000),
                  blurRadius: 14,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: InkWell(
              borderRadius: radius,
              onTap: onTap,
              child: ClipRRect(
                borderRadius: radius,
                child: Stack(
                  children: [
                    // Big faint chapter number on the far side of the card.
                    if (number != null)
                      PositionedDirectional(
                        end: 14,
                        bottom: -18,
                        child: Text(
                          number!,
                          style: const TextStyle(
                            color: Color(0x1FFFFFFF),
                            fontSize: 92,
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(
                        children: [
                          // Icon inside a soft white circle.
                          Container(
                            width: 50,
                            height: 50,
                            decoration: const BoxDecoration(
                              color: Color(0x33FFFFFF),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, color: Colors.white, size: 26),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (section.label != null)
                                  Text(
                                    section.label!,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                Text(
                                  section.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  section.subtitle,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.5,
                                    height: 1.7,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.white),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
