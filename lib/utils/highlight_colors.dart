import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Names of the 3 highlight colors.
const List<String> highlightNames = ['زرد', 'سبز', 'صورتی'];

const _light = ['#ffe082', '#b7e4c1', '#f8c4d8'];
const _dark = ['#6f5d12', '#1f5c37', '#6e2b48'];
const _paper = ['#f0d77a', '#bcd9a5', '#e9b8c0'];

/// CSS color text (like "#ffe082") of a highlight color, for the current look.
String highlightHex(int index, AppColors ui) {
  final list = ui.sepia ? _paper : (ui.dark ? _dark : _light);
  return list[index.clamp(0, list.length - 1)];
}

/// The same color as a Flutter color.
Color highlightColor(int index, AppColors ui) {
  final hex = highlightHex(index, ui);
  return Color(int.parse('FF${hex.substring(1)}', radix: 16));
}
