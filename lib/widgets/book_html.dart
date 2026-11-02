import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import '../services/settings_controller.dart';
import '../utils/app_colors.dart';
import '../utils/highlight_colors.dart';

/// Shows the ORIGINAL html of one tab.
/// The text is never changed. We only add styles (colors, boxes, fonts),
/// the same look as the original HTML file (and a dark version).
class BookHtml extends StatelessWidget {
  final String html;
  final SettingsController settings;

  /// Called when the reader taps a link (we use links for highlights).
  /// Return true if the tap was handled.
  final Future<bool> Function(String url)? onTapUrl;

  const BookHtml({
    super.key,
    required this.html,
    required this.settings,
    this.onTapUrl,
  });

  @override
  Widget build(BuildContext context) {
    final ui = AppColors.of(context);
    final dark = ui.dark;

    // Pick the light or the dark color.
    // (paper mode has its own warm colors; if none is given, the light one is used)
    String c(String light, String darkColor, [String? paper]) =>
        ui.sepia ? (paper ?? light) : (dark ? darkColor : light);

    // Text color as css, used inside highlights.
    final textHex = ui.sepia ? '#3b2f20' : (dark ? '#e6e6e6' : '#2c2c2c');

    return HtmlWidget(
      html,
      onTapUrl: onTapUrl,
      // Build at once (not step by step), so the page height is known
      // right away. We need this to jump to a saved place or search result.
      buildAsync: false,
      textStyle: TextStyle(
        fontFamily: settings.fontFamily,
        fontSize: settings.fontSize,
        height: settings.lineHeight,
        color: ui.text,
      ),
      // Called for every html element. We return css styles for it.
      customStylesBuilder: (element) {
        final tag = element.localName;
        bool has(String name) => element.classes.contains(name);
        bool parentHas(String name) =>
            element.parent?.classes.contains(name) ?? false;

        // Search result mark (added only while showing a search result)
        if (tag == 'mark') {
          return {'background-color': '#ffb74d', 'color': '#000000'};
        }

        // A highlight made by the reader: <a href="hl:id:color:hasNote">
        if (tag == 'a') {
          final href = element.attributes['href'] ?? '';
          if (href.startsWith('hl:')) {
            final parts = href.split(':');
            final color = parts.length > 2 ? (int.tryParse(parts[2]) ?? 0) : 0;
            final hasNote = parts.length > 3 && parts[3] == '1';
            return {
              'background-color': highlightHex(color, ui),
              'color': textHex,
              // A line under the text means: this highlight has a note.
              'text-decoration': hasNote ? 'underline' : 'none',
            };
          }
        }

        // Quran verse box
        if (has('ayah')) {
          return {
            'background-color': c('#fffdf5', '#2a2719', '#efe4c6'),
            'border-right': '4px solid #c9a961',
            'padding': '16px 18px',
            'margin': '16px 0',
            'border-radius': '8px',
            'font-family': 'Amiri',
            'font-size': '1.2em',
            'line-height': (settings.lineHeight + 0.1).toStringAsFixed(2),
            'color': c('#1a5490', '#9cc4f0', '#5b3a14'),
            'text-align': 'center',
          };
        }
        // Verse reference (sura and number)
        if (has('ayah-ref')) {
          return {
            'display': 'block',
            'font-family': 'Vazirmatn',
            'font-size': '0.65em',
            'color': c('#8b7d4a', '#d9bc7a', '#8b6f2e'),
            'font-weight': 'bold',
            'margin-top': '8px',
          };
        }
        // Hadith box
        if (has('hadith')) {
          return {
            'background-color': c('#f0f7f0', '#1d2b21', '#e6e9d0'),
            'border-right': '4px solid #2d8a4e',
            'padding': '14px 16px',
            'margin': '16px 0',
            'border-radius': '8px',
            'font-size': '0.95em',
          };
        }
        if (tag == 'strong' && parentHas('hadith')) {
          return {'color': c('#2d8a4e', '#6fcf97'), 'display': 'block'};
        }
        // Important note box
        if (has('note')) {
          return {
            'background-color': c('#fff4e6', '#33271a', '#f1ddb8'),
            'border-right': '4px solid #e67e22',
            'padding': '14px 16px',
            'margin': '16px 0',
            'border-radius': '8px',
            'font-size': '0.92em',
          };
        }
        if (tag == 'strong' && parentHas('note')) {
          return {'color': c('#d35400', '#f0a15c', '#a04a12')};
        }
        // Title page (cover inside the first tab)
        if (has('title-page')) {
          return {
            'background-color': '#0d3a6b',
            'border': '2px solid #c9a961',
            'border-radius': '14px',
            'padding': '30px 20px',
            'margin-bottom': '20px',
            'text-align': 'center',
            'color': '#ffffff',
          };
        }
        if (has('bismillah')) {
          return {
            'font-family': 'Amiri',
            'font-size': '1.4em',
            'color': '#c9a961',
            'margin-bottom': '20px',
          };
        }
        if (has('line')) {
          return {
            'width': '50px',
            'height': '2px',
            'background-color': '#c9a961',
            'margin': '15px auto',
          };
        }
        if (has('info')) {
          return {'font-size': '0.85em', 'line-height': '2.2'};
        }
        if (tag == 'strong' && parentHas('info')) {
          return {'color': '#c9a961'};
        }
        if (tag == 'h2' && parentHas('title-page')) {
          return {
            'font-size': '1.2em',
            'color': '#ffffff',
            'margin-bottom': '15px',
          };
        }

        // Normal headings and text
        if (tag == 'h3') {
          return {
            'font-size': '1.15em',
            'font-weight': 'bold',
            'color': c('#1a5490', '#7fb3e8', '#6b4423'),
            'margin': '28px 0 14px',
            'padding-right': '14px',
            'border-right': '4px solid #c9a961',
          };
        }
        if (tag == 'h4') {
          return {
            'font-size': '1.05em',
            'font-weight': 'bold',
            'color': c('#2c3e50', '#c8d3de', '#4a3a28'),
            'margin': '22px 0 10px',
            'padding-right': '10px',
            'border-right': '3px solid ${c('#1a5490', '#7fb3e8', '#8b6f2e')}',
          };
        }
        if (tag == 'p') {
          return {'text-align': 'justify', 'margin-bottom': '18px'};
        }
        if (tag == 'li') {
          return {'margin-bottom': '8px'};
        }
        return null; // no special style
      },
    );
  }
}
