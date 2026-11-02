import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'app_state.dart';
import 'screens/splash_screen.dart';
import 'services/book_loader.dart';
import 'services/bookmarks_controller.dart';
import 'services/highlights_controller.dart';
import 'services/reading_progress.dart';
import 'services/search_index.dart';
import 'services/settings_controller.dart';
import 'utils/app_colors.dart';
import 'widgets/soft_page_transition.dart';

Future<void> main() async {
  // Needed because we use plugins before runApp.
  WidgetsFlutterBinding.ensureInitialized();

  final settings = SettingsController();
  await settings.load(); // saved font, size and light/dark

  final bookmarks = BookmarksController();
  await bookmarks.load(); // saved bookmarks

  final highlights = HighlightsController();
  await highlights.load(); // saved highlights and notes

  final progress = ReadingProgress();
  await progress.load(); // where the reader stopped

  final book = await loadBook(); // reads assets/book.json

  final app = AppState(
    book: book,
    settings: settings,
    bookmarks: bookmarks,
    highlights: highlights,
    progress: progress,
    search: SearchIndex.build(book), // text index for searching
  );

  runApp(MyApp(app: app));
}

class MyApp extends StatelessWidget {
  final AppState app;

  const MyApp({super.key, required this.app});

  static const _seed = Color(0xFF1A5490);

  /// The themes: light, dark, and "paper" (sepia, a light theme with warm colors).
  ThemeData _theme(Brightness brightness, {bool paper = false}) {
    // Soft fade + slide when pages change (all platforms).
    final transitions = PageTransitionsTheme(
      builders: {
        for (final p in TargetPlatform.values)
          p: const SoftPageTransitionsBuilder(),
      },
    );

    if (paper) {
      return ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seed,
          brightness: Brightness.light,
        ).copyWith(surface: const Color(0xFFF4ECD8)),
        scaffoldBackgroundColor: const Color(0xFFE8DCC2),
        fontFamily: 'Vazirmatn',
        pageTransitionsTheme: transitions,
        extensions: const [AppPalette(sepia: true)],
      );
    }
    return ThemeData(
      brightness: brightness,
      fontFamily: 'Vazirmatn',
      colorSchemeSeed: _seed,
      pageTransitionsTheme: transitions,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild when the user changes light/dark in the settings.
    return ListenableBuilder(
      listenable: app.settings,
      builder: (context, _) {
        return MaterialApp(
          title: 'اضطراب در قرآن',
          debugShowCheckedModeBanner: false,
          theme: _theme(
            Brightness.light,
            paper: app.settings.themeChoice == AppThemeChoice.sepia,
          ),
          darkTheme: _theme(Brightness.dark),
          themeMode: app.settings.themeMode,
          // Persian system texts (copy/paste menu, tooltips...).
          locale: const Locale('fa'),
          supportedLocales: const [Locale('fa')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          // Make the whole app right-to-left.
          builder: (context, child) =>
              Directionality(textDirection: TextDirection.rtl, child: child!),
          home: SplashScreen(app: app), // splash, then the home screen
        );
      },
    );
  }
}
