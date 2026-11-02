import 'models/book.dart';
import 'services/bookmarks_controller.dart';
import 'services/highlights_controller.dart';
import 'services/reading_progress.dart';
import 'services/search_index.dart';
import 'services/settings_controller.dart';

/// Everything the screens need, in one place.
class AppState {
  final Book book;
  final SettingsController settings;
  final BookmarksController bookmarks;
  final HighlightsController highlights;
  final ReadingProgress progress;
  final SearchIndex search;

  const AppState({
    required this.book,
    required this.settings,
    required this.bookmarks,
    required this.highlights,
    required this.progress,
    required this.search,
  });
}
