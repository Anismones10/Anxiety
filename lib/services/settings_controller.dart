import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:shared_preferences/shared_preferences.dart';

/// The look of the app: light, dark, paper (sepia), or the same as the phone.
enum AppThemeChoice { light, dark, sepia, system }

/// One font the reader can choose.
class AppFont {
  final String family; // must match the name in pubspec.yaml
  final String label; // name shown to the user
  const AppFont(this.family, this.label);
}

const List<AppFont> appFonts = [
  AppFont('Vazirmatn', 'وزیرمتن'),
  AppFont('NotoNaskhArabic', 'نسخ'),
  AppFont('Amiri', 'امیری'),
];

/// Keeps the reader settings (font, size, line spacing, light/dark, citation)
/// and saves them on the phone.
class SettingsController extends ChangeNotifier {
  static const _fontKey = 'font_family';
  static const _sizeKey = 'font_size';
  static const _themeKey = 'theme_mode';
  static const _lineKey = 'line_height';
  static const _citeKey = 'copy_with_citation';
  static const double minSize = 14;
  static const double maxSize = 30;
  static const double minLineHeight = 1.6;
  static const double maxLineHeight = 2.8;

  String _fontFamily = 'Vazirmatn';
  double _fontSize = 17;
  AppThemeChoice _themeChoice = AppThemeChoice.light;
  double _lineHeight = 2.1;
  bool _copyWithCitation = true;

  String get fontFamily => _fontFamily;
  double get fontSize => _fontSize;
  AppThemeChoice get themeChoice => _themeChoice;

  /// The ThemeMode Flutter needs (paper mode is a light theme).
  ThemeMode get themeMode => switch (_themeChoice) {
        AppThemeChoice.dark => ThemeMode.dark,
        AppThemeChoice.system => ThemeMode.system,
        _ => ThemeMode.light,
      };
  double get lineHeight => _lineHeight;
  bool get copyWithCitation => _copyWithCitation;

  /// Reads the saved settings (call once when the app starts).
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();

    final savedFont = prefs.getString(_fontKey);
    if (savedFont != null && appFonts.any((f) => f.family == savedFont)) {
      _fontFamily = savedFont;
    }

    final savedSize = prefs.getDouble(_sizeKey);
    if (savedSize != null) {
      _fontSize = savedSize.clamp(minSize, maxSize).toDouble();
    }

    final savedTheme = prefs.getString(_themeKey);
    if (savedTheme != null) {
      _themeChoice =
          AppThemeChoice.values.asNameMap()[savedTheme] ?? AppThemeChoice.light;
    }

    final savedLine = prefs.getDouble(_lineKey);
    if (savedLine != null) {
      _lineHeight = savedLine.clamp(minLineHeight, maxLineHeight).toDouble();
    }

    _copyWithCitation = prefs.getBool(_citeKey) ?? true;
  }

  /// Saves the current settings on the phone.
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fontKey, _fontFamily);
    await prefs.setDouble(_sizeKey, _fontSize);
    await prefs.setString(_themeKey, _themeChoice.name);
    await prefs.setDouble(_lineKey, _lineHeight);
    await prefs.setBool(_citeKey, _copyWithCitation);
  }

  void setFontFamily(String family) {
    _fontFamily = family;
    notifyListeners(); // tells the screens to redraw
    save();
  }

  /// Called many times while the slider moves (does not save yet).
  void setFontSize(double size) {
    _fontSize = size;
    notifyListeners();
  }

  void setThemeChoice(AppThemeChoice choice) {
    _themeChoice = choice;
    notifyListeners();
    save();
  }

  /// Called many times while the slider moves (does not save yet).
  void setLineHeight(double value) {
    _lineHeight = value;
    notifyListeners();
  }

  void setCopyWithCitation(bool value) {
    _copyWithCitation = value;
    notifyListeners();
    save();
  }
}
