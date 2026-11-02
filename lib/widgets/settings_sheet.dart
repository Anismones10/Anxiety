import 'package:flutter/material.dart';
import '../services/settings_controller.dart';
import '../utils/app_colors.dart';

/// Opens the settings panel from the bottom of the screen.
void showSettingsSheet(BuildContext context, SettingsController settings) {
  showModalBottomSheet(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => SettingsSheet(settings: settings),
  );
}

class SettingsSheet extends StatelessWidget {
  final SettingsController settings;

  const SettingsSheet({super.key, required this.settings});

  @override
  Widget build(BuildContext context) {
    final ui = AppColors.of(context);

    // ListenableBuilder redraws this panel when the settings change.
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'اندازهٔ فونت',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Slider(
                  value: settings.fontSize,
                  min: SettingsController.minSize,
                  max: SettingsController.maxSize,
                  divisions: 16,
                  label: settings.fontSize.round().toString(),
                  onChanged: settings.setFontSize,
                  onChangeEnd: (_) => settings.save(),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: ui.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'نمونهٔ متن کتاب\nخط دوم، برای دیدن فاصلهٔ خطوط',
                    style: TextStyle(
                      fontFamily: settings.fontFamily,
                      fontSize: settings.fontSize,
                      height: settings.lineHeight,
                      color: ui.text,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'فاصلهٔ خطوط',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Slider(
                  value: settings.lineHeight,
                  min: SettingsController.minLineHeight,
                  max: SettingsController.maxLineHeight,
                  divisions: 12,
                  label: settings.lineHeight.toStringAsFixed(1),
                  onChanged: settings.setLineHeight,
                  onChangeEnd: (_) => settings.save(),
                ),
                const SizedBox(height: 8),
                const Text(
                  'نوع فونت',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final f in appFonts)
                      ChoiceChip(
                        label: Text(
                          f.label,
                          style: TextStyle(fontFamily: f.family, fontSize: 16),
                        ),
                        selected: settings.fontFamily == f.family,
                        onSelected: (_) => settings.setFontFamily(f.family),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  'حالت نمایش',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final item in const [
                      (AppThemeChoice.light, 'روشن'),
                      (AppThemeChoice.sepia, 'کاغذی'),
                      (AppThemeChoice.dark, 'تیره'),
                      (AppThemeChoice.system, 'مطابق گوشی'),
                    ])
                      ChoiceChip(
                        label: Text(item.$2),
                        selected: settings.themeChoice == item.$1,
                        onSelected: (_) => settings.setThemeChoice(item.$1),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('افزودن ارجاع هنگام کپی'),
                  subtitle: const Text(
                    'نام کتاب، نویسنده، فصل و مبحث به متن کپی‌شده اضافه می‌شود',
                  ),
                  value: settings.copyWithCitation,
                  onChanged: settings.setCopyWithCitation,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
