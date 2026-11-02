import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/highlight.dart';

/// Keeps the highlights and notes, and saves them on the phone.
class HighlightsController extends ChangeNotifier {
  static const _prefsKey = 'highlights';

  final List<Highlight> _items = [];

  List<Highlight> get items => List.unmodifiable(_items);

  List<Highlight> forTab(int section, int tab) =>
      _items.where((h) => h.section == section && h.tab == tab).toList();

  Highlight? byId(String id) {
    for (final h in _items) {
      if (h.id == id) return h;
    }
    return null;
  }

  /// Reads the saved highlights (call once when the app starts).
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved == null) return;
    try {
      final list = jsonDecode(saved) as List;
      for (final item in list) {
        _items.add(Highlight.fromJson(item as Map<String, dynamic>));
      }
    } catch (_) {
      // If the saved data is broken, we start with an empty list.
      _items.clear();
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode(_items.map((h) => h.toJson()).toList()),
    );
  }

  Future<void> add(Highlight highlight) async {
    _items.add(highlight);
    notifyListeners();
    await _save();
  }

  Future<void> update(Highlight highlight) async {
    final index = _items.indexWhere((h) => h.id == highlight.id);
    if (index == -1) return;
    _items[index] = highlight;
    notifyListeners();
    await _save();
  }

  Future<void> remove(String id) async {
    _items.removeWhere((h) => h.id == id);
    notifyListeners();
    await _save();
  }
}
