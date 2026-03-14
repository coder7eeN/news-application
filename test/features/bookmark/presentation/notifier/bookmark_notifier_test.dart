import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:news_app/features/bookmark/data/datasources/bookmark_local_datasource.dart';
import 'package:news_app/features/bookmark/presentation/notifier/bookmark_notifier.dart';
import 'package:news_app/features/news_feed/domain/entities/article.dart';

class MockBookmarkLocalDataSource extends Mock
    implements BookmarkLocalDataSource {}

void main() {
  late MockBookmarkLocalDataSource mockDataSource;

  final tArticle = Article(
    id: 'https://example.com/1',
    title: 'Test Article',
    url: 'https://example.com/1',
    publishedAt: DateTime(2026, 3, 14),
    sourceName: 'Test Source',
  );

  setUp(() {
    mockDataSource = MockBookmarkLocalDataSource();
  });

  BookmarkNotifier createNotifier() {
    when(() => mockDataSource.getAllBookmarks()).thenReturn([]);
    return BookmarkNotifier(localDataSource: mockDataSource);
  }

  group('loadBookmarks', () {
    test('loads bookmarks from data source on construction', () {
      when(() => mockDataSource.getAllBookmarks()).thenReturn([tArticle]);

      final notifier = BookmarkNotifier(localDataSource: mockDataSource);

      expect(notifier.bookmarks, [tArticle]);
      verify(() => mockDataSource.getAllBookmarks()).called(1);
      notifier.dispose();
    });
  });

  group('toggleBookmark', () {
    test('adds article when not bookmarked', () {
      final notifier = createNotifier();
      when(() => mockDataSource.isBookmarked(tArticle.id)).thenReturn(false);
      when(() => mockDataSource.saveBookmark(tArticle)).thenReturn(null);
      when(() => mockDataSource.getAllBookmarks()).thenReturn([tArticle]);

      notifier.toggleBookmark(tArticle);

      verify(() => mockDataSource.saveBookmark(tArticle)).called(1);
      expect(notifier.bookmarks, [tArticle]);
      notifier.dispose();
    });

    test('removes article when already bookmarked', () {
      final notifier = createNotifier();
      when(() => mockDataSource.isBookmarked(tArticle.id)).thenReturn(true);
      when(() => mockDataSource.removeBookmark(tArticle.id)).thenReturn(null);
      when(() => mockDataSource.getAllBookmarks()).thenReturn([]);

      notifier.toggleBookmark(tArticle);

      verify(() => mockDataSource.removeBookmark(tArticle.id)).called(1);
      expect(notifier.bookmarks, isEmpty);
      notifier.dispose();
    });
  });

  group('isBookmarked', () {
    test('returns true when article is bookmarked', () {
      final notifier = createNotifier();
      when(() => mockDataSource.isBookmarked(tArticle.id)).thenReturn(true);

      expect(notifier.isBookmarked(tArticle.id), isTrue);
      notifier.dispose();
    });

    test('returns false when article is not bookmarked', () {
      final notifier = createNotifier();
      when(() => mockDataSource.isBookmarked(tArticle.id)).thenReturn(false);

      expect(notifier.isBookmarked(tArticle.id), isFalse);
      notifier.dispose();
    });
  });

  group('notifyListeners', () {
    test('notifies listeners on toggleBookmark', () {
      final notifier = createNotifier();
      var callCount = 0;
      notifier.addListener(() => callCount++);

      when(() => mockDataSource.isBookmarked(tArticle.id)).thenReturn(false);
      when(() => mockDataSource.saveBookmark(tArticle)).thenReturn(null);
      when(() => mockDataSource.getAllBookmarks()).thenReturn([tArticle]);

      notifier.toggleBookmark(tArticle);

      expect(callCount, 1);
      notifier.dispose();
    });
  });
}
