import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../book_info.dart';
import '../utils/app_colors.dart';

/// About screen: the book, the app, and the app developer.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ui = AppColors.of(context);

    return Scaffold(
      backgroundColor: ui.background,
      appBar: AppBar(title: const Text('دربارهٔ برنامه')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---- Logo (on a white circle, so it is visible in dark mode too) ----
          Center(
            child: Container(
              width: 132,
              height: 132,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: ui.dark ? Colors.transparent : const Color(0x26000000),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Image.asset('assets/images/logo.png', fit: BoxFit.contain),
            ),
          ),
          const SizedBox(height: 16),

          // ---- Book title card ----
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFF0D3A6B),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFC9A961), width: 2),
            ),
            child: const Text(
              bookTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.bold,
                height: 1.7,
              ),
            ),
          ),

          // ---- About the book (copied from the book's own title page) ----
          const _SectionTitle('دربارهٔ کتاب'),
          const _Panel(
            child: Column(
              children: [
                _InfoRow(Icons.person_outline, 'نویسنده', authorFullName),
                _InfoRow(Icons.school_outlined, 'استاد راهنما', supervisorName),
                _InfoRow(
                  Icons.account_balance_outlined,
                  'پوهنتون',
                  universityName,
                ),
                _InfoRow(Icons.domain_outlined, 'پوهنحی', facultyName),
                _InfoRow(
                  Icons.account_tree_outlined,
                  'دیپارتمنت',
                  departmentName,
                ),
                _InfoRow(Icons.menu_book_outlined, 'تعداد صفحات', bookPages),
                _InfoRow(Icons.topic_outlined, 'موضوع', bookSubject),
                _InfoRow(
                  Icons.calendar_today_outlined,
                  'سال انتشار',
                  bookYear,
                  isLast: true,
                ),
              ],
            ),
          ),

          // ---- Author's Telegram channel ----
          const _SectionTitle('ارتباط با نویسنده'),
          _Panel(
            child: _LinkTile(
              icon: Icons.send_rounded,
              color: const Color(0xFF29A9EB),
              label: 'کانال تلگرام نویسنده',
              value: authorTelegramHandle,
              uri: Uri.parse(authorTelegramUrl),
            ),
          ),

          // ---- About the app ----
          const _SectionTitle('دربارهٔ برنامه'),
          const _Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'این برنامه برای خواندن آسان این مونوگراف ساخته شده است. '
                  'متن کتاب دقیقاً همان متن اصلی پژوهش است و در برنامه '
                  'هیچ تغییری در آن داده نشده؛ فقط شکل نمایش و امکانات خواندن '
                  'اضافه شده است.',
                  style: TextStyle(height: 2, fontSize: 14.5),
                ),
                SizedBox(height: 12),
                _Feature(
                  Icons.tab_outlined,
                  'فصل‌ها و مبحث‌ها با تب‌های بالا، مثل کتاب اصلی',
                ),
                _Feature(
                  Icons.search,
                  'جستجو در کل کتاب، با نمایش جملهٔ اطراف کلمه',
                ),
                _Feature(
                  Icons.bookmark_border,
                  'نشانک برای ذخیرهٔ جاهایی که می‌خواهید دوباره بخوانید',
                ),
                _Feature(
                  Icons.text_fields,
                  'تغییر اندازه و نوع فونت (وزیرمتن، نسخ، امیری)',
                ),
                _Feature(
                  Icons.wifi_off_outlined,
                  'کار کردن بدون اینترنت',
                ),
              ],
            ),
          ),

          // ---- Developer ----
          const _SectionTitle('برنامه‌نویسی'),
          _Panel(
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.code_rounded, color: ui.accent, size: 30),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        developerName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: ui.accent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _LinkTile(
                  icon: Icons.email_rounded,
                  color: const Color(0xFFE0584F),
                  label: 'ایمیل',
                  value: developerEmail,
                  uri: Uri(scheme: 'mailto', path: developerEmail),
                ),
                const SizedBox(height: 10),
                _LinkTile(
                  icon: Icons.code_rounded,
                  color: const Color(0xFF6E7681),
                  label: 'گیت‌هاب',
                  value: developerGithubName,
                  uri: Uri.parse(developerGithubUrl),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              'نسخهٔ $appVersion',
              style: TextStyle(color: ui.muted, fontSize: 12.5),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

/// Small title above a group.
class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 22, 4, 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: AppColors.of(context).accent,
        ),
      ),
    );
  }
}

/// White rounded box.
class _Panel extends StatelessWidget {
  final Widget child;

  const _Panel({required this.child});

  @override
  Widget build(BuildContext context) {
    final ui = AppColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ui.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: ui.shadow,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// One line: icon, label (gray) and value.
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  const _InfoRow(this.icon, this.label, this.value, {this.isLast = false});

  @override
  Widget build(BuildContext context) {
    final ui = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: ui.divider)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFFC9A961)),
          const SizedBox(width: 10),
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: TextStyle(color: ui.muted, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14.5, height: 1.7),
            ),
          ),
        ],
      ),
    );
  }
}

/// One feature line with an icon.
class _Feature extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Feature(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xFFC9A961)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: const TextStyle(height: 1.8, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}

/// A tappable row (like a contact card): icon, label, value, "open" icon.
/// Tap opens the link in the right app (Telegram, mail, browser/GitHub...).
class _LinkTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final Uri uri;

  const _LinkTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.uri,
  });

  Future<void> _open(BuildContext context) async {
    var opened = false;
    try {
      // externalApplication = open in another app, not inside ours.
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      opened = false;
    }
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('باز کردن لینک ممکن نشد')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ui = AppColors.of(context);
    final radius = BorderRadius.circular(12);
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: ui.background,
          borderRadius: radius,
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: InkWell(
          borderRadius: radius,
          onTap: () => _open(context),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(color: ui.muted, fontSize: 12),
                      ),
                      const SizedBox(height: 2),
                      // The value is English letters, so it is shown left-to-right.
                      Text(
                        value,
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.open_in_new,
                  size: 18,
                  color: color.withValues(alpha: 0.85),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
