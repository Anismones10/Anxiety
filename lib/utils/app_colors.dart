import 'package:flutter/material.dart';

/// Marks the "paper" (sepia) theme. It is light, but with warm colors.
class AppPalette extends ThemeExtension<AppPalette> {
  final bool sepia;

  const AppPalette({required this.sepia});

  @override
  AppPalette copyWith({bool? sepia}) => AppPalette(sepia: sepia ?? this.sepia);

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return t < 0.5 ? this : other;
  }
}

/// Colors that change between light, dark and paper (sepia) mode.
/// Use: final ui = AppColors.of(context);  then  ui.surface, ui.text ...
class AppColors {
  final bool dark;
  final bool sepia;

  const AppColors._(this.dark, this.sepia);

  factory AppColors.of(BuildContext context) {
    final theme = Theme.of(context);
    return AppColors._(
      theme.brightness == Brightness.dark,
      theme.extension<AppPalette>()?.sepia ?? false,
    );
  }

  Color _pick(Color light, Color darkColor, Color sepiaColor) =>
      sepia ? sepiaColor : (dark ? darkColor : light);

  /// Page background (behind the cards).
  Color get background => _pick(
        const Color(0xFFF0F2F5),
        const Color(0xFF121212),
        const Color(0xFFE8DCC2),
      );

  /// Cards, panels and the reading page.
  Color get surface => _pick(
        Colors.white,
        const Color(0xFF1E1E1E),
        const Color(0xFFF4ECD8),
      );

  /// Normal text.
  Color get text => _pick(
        const Color(0xFF2C2C2C),
        const Color(0xFFE6E6E6),
        const Color(0xFF3B2F20),
      );

  /// Gray helper text.
  Color get muted => _pick(
        Colors.black54,
        Colors.white60,
        const Color(0xFF7A6A54),
      );

  /// Titles and links (blue; brown in paper mode).
  Color get accent => _pick(
        const Color(0xFF1A5490),
        const Color(0xFF7FB3E8),
        const Color(0xFF6B4423),
      );

  /// Thin lines.
  Color get divider => _pick(
        const Color(0xFFEEEEEE),
        const Color(0xFF333333),
        const Color(0xFFD8CCB0),
      );

  /// Soft gold for small texts.
  Color get gold => _pick(
        const Color(0xFF8B7D4A),
        const Color(0xFFD9BC7A),
        const Color(0xFF8B6F2E),
      );

  /// Shadow under panels (none in dark mode).
  Color get shadow => dark ? Colors.transparent : const Color(0x14000000);
}
