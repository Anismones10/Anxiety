import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Remembers (1) where the reader stopped, and (2) which parts (tabs)
/// of the book the reader has finished.
class ReadingProgress extends ChangeNotifier {
  static const _sectionKey = 'last_section';
  static const _tabKey = 'last_tab';
  static const _fractionKey = 'last_fraction';
  static const _readKey = 'read_tabs';

  /// A tab counts as "read" when the reader reaches this part of it (0..1).
  static const double readThreshold = 0.9;

  int? _section;
  int _tab = 0;
  double _fraction = 0;
  final Set<String> _read = {}; // like "2:3" = chapter 2, tab 3

  bool get hasProgress => _section != null;
  int get section => _section ?? 0;
  int get tab => _tab;
  double get fraction => _fraction;

  bool isRead(int section, int tab) => _read.contains('$section:$tab');

  /// Reads the saved data (call once when the app starts).
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _section = prefs.getInt(_sectionKey);
    _tab = prefs.getInt(_tabKey) ?? 0;
    _fraction = prefs.getDouble(_fractionKey) ?? 0;
    _read.addAll(prefs.getStringList(_readKey) ?? const <String>[]);
  }

  Future<void> _saveRead() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_readKey, _read.toList());
  }

  /// Marks a tab as read (for example a short page that fits on one screen).
  Future<void> markRead(int section, int tab) async {
    if (!_read.add('$section:$tab')) return; // it was already read
    notifyListeners();
    await _saveRead();
  }

  /// Saves the place and tells the screens (the home screen shows it).
  /// If the reader is near the end of the tab, the tab counts as read.
  Future<void> save(int section, int tab, double fraction) async {
    _section = section;
    _tab = tab;
    _fraction = fraction;
    final newlyRead =
        fraction >= readThreshold && _read.add('$section:$tab');
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_sectionKey, section);
    await prefs.setInt(_tabKey, tab);
    await prefs.setDouble(_fractionKey, fraction);
    if (newlyRead) await _saveRead();
  }
}
