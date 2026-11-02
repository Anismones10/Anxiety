import 'package:flutter/material.dart';

/// Gold colors, used for the intro card.
const List<Color> introColors = [Color(0xFFC9A961), Color(0xFF8B7D4A)];

/// Takes CSS text like "linear-gradient(135deg, #2c7bb6, #1a5490)"
/// and returns the colors inside it as Flutter colors.
List<Color> parseGradient(String css) {
  final matches = RegExp(r'#([0-9a-fA-F]{6})').allMatches(css);
  final colors = matches
      .map((m) => Color(int.parse('FF${m.group(1)}', radix: 16)))
      .toList();
  if (colors.length >= 2) return colors;
  // Fallback (blue) if the text has no colors.
  return const [Color(0xFF1A5490), Color(0xFF062445)];
}

/// Colors of a section: gold for the intro (css is null), else from the CSS.
List<Color> sectionColors(String? css) {
  if (css == null) return introColors;
  return parseGradient(css);
}
