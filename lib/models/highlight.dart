/// A piece of text the reader marked with a color, with an optional note.
/// `start` and `end` are positions in the readable text of the tab.
class Highlight {
  final String id;
  final int section;
  final int tab;
  final int start;
  final int end;
  final String text; // the marked text (used to find it again if needed)
  final int color; // 0 = yellow, 1 = green, 2 = pink
  final String note; // empty if there is no note
  final int createdAt;

  const Highlight({
    required this.id,
    required this.section,
    required this.tab,
    required this.start,
    required this.end,
    required this.text,
    required this.color,
    required this.note,
    required this.createdAt,
  });

  Highlight copyWith({int? color, String? note}) {
    return Highlight(
      id: id,
      section: section,
      tab: tab,
      start: start,
      end: end,
      text: text,
      color: color ?? this.color,
      note: note ?? this.note,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'section': section,
        'tab': tab,
        'start': start,
        'end': end,
        'text': text,
        'color': color,
        'note': note,
        'createdAt': createdAt,
      };

  factory Highlight.fromJson(Map<String, dynamic> json) {
    return Highlight(
      id: json['id'] as String,
      section: json['section'] as int,
      tab: json['tab'] as int,
      start: json['start'] as int,
      end: json['end'] as int,
      text: json['text'] as String,
      color: (json['color'] as int?) ?? 0,
      note: (json['note'] as String?) ?? '',
      createdAt: (json['createdAt'] as int?) ?? 0,
    );
  }
}
