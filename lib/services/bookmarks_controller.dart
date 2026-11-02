import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A saved place: which section (intro or chapter) and which tab.
class Bookmark {
  final int section;
  final int tab;

  const Bookmark(this.section, this.tab);

  /// Text form used for saving, like "2:3".
  String get key => '$section:$tab';
}

/// Keeps the bookmarks and saves them on the phone.
class BookmarksController extends ChangeNotifier {
  static const _prefsKey = 'bookmarks';

  final List<Bookmark> _items = [];

  List<Bookmark> get items => List.unmodifiable(_items);

  bool isBookmarked(int section, int tab) =>
      _items.any((b) => b.section == section && b.tab == tab);

  /// Reads the saved bookmarks (call once when the app starts).
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_prefsKey) ?? [];
    for (final key in saved) {
      final parts = key.split(':');
      if (parts.length != 2) continue;
      final section = int.tryParse(parts[0]);
      final tab = int.tryParse(parts[1]);
      if (section != null && tab != null) {
        _items.add(Bookmark(section, tab));
      }
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, _items.map((b) => b.key).toList());
  }

  /// Adds the bookmark if it is not there, removes it if it is.
  /// Returns true if it is saved now.
  Future<bool> toggle(int section, int tab) async {
    final index =
        _items.indexWhere((b) => b.section == section && b.tab == tab);
    final nowSaved = index == -1;
    if (nowSaved) {
      _items.add(Bookmark(section, tab));
    } else {
      _items.removeAt(index);
    }
    notifyListeners();
    await _save();
    return nowSaved;
  }

  Future<void> remove(Bookmark bookmark) async {
    _items.removeWhere(
      (b) => b.section == bookmark.section && b.tab == bookmark.tab,
    );
    notifyListeners();
    await _save();
  }
}
