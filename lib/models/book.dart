/// One tab (topic). `content` is the original HTML, never changed.
class BookTab {
  final String name;
  final String content;

  const BookTab({required this.name, required this.content});

  factory BookTab.fromJson(Map<String, dynamic> json) {
    return BookTab(
      name: json['name'] as String,
      content: json['content'] as String,
    );
  }
}

/// One chapter with its tabs.
class Chapter {
  final String num;
  final String title;
  final String desc;
  final String color; // CSS gradient text from the HTML
  final List<BookTab> tabs;

  const Chapter({
    required this.num,
    required this.title,
    required this.desc,
    required this.color,
    required this.tabs,
  });

  factory Chapter.fromJson(Map<String, dynamic> json) {
    return Chapter(
      num: json['num'] as String,
      title: json['title'] as String,
      desc: json['desc'] as String,
      color: json['color'] as String,
      tabs: (json['tabs'] as List)
          .map((t) => BookTab.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// A "section" is one card on the home screen:
/// the intro (index 0) or one chapter (index 1, 2, 3...).
/// Bookmarks and search results point to (section index, tab index).
class Section {
  final String title;
  final String? label; // small text above the title (chapter number)
  final String subtitle;
  final String? color; // CSS gradient text, or null for the intro
  final List<BookTab> tabs;

  const Section({
    required this.title,
    this.label,
    required this.subtitle,
    this.color,
    required this.tabs,
  });

  /// Title with the chapter number, for the app bar and lists.
  String get fullTitle => label == null ? title : '$label: $title';
}

/// The whole book: intro tabs + chapters.
class Book {
  final List<BookTab> introTabs;
  final List<Chapter> chapters;

  Book({required this.introTabs, required this.chapters});

  /// Intro first, then the chapters. Built once, when first used.
  late final List<Section> sections = [
    Section(
      title: 'مقدمات کتاب',
      subtitle: introTabs.map((t) => t.name).join(' • '),
      tabs: introTabs,
    ),
    for (final c in chapters)
      Section(
        title: c.title,
        label: c.num,
        subtitle: c.desc,
        color: c.color,
        tabs: c.tabs,
      ),
  ];

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      introTabs: (json['intro']['tabs'] as List)
          .map((t) => BookTab.fromJson(t as Map<String, dynamic>))
          .toList(),
      chapters: (json['chapters'] as List)
          .map((c) => Chapter.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }
}
