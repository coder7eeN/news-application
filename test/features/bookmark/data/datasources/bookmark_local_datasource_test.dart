import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:news_app/features/bookmark/data/datasources/bookmark_local_datasource.dart';
import 'package:news_app/features/news_feed/data/models/article_model.dart';
import 'package:news_app/features/news_feed/domain/entities/article.dart';

class MockBox extends Mock implements Box<Object?> {}

void main() {
  late MockBox mockBox;
  late BookmarkLocalDataSourceImpl datasource;

  final tArticle = Article(
    id: 'https://example.com/1',
    title: 'Test Article',
    url: 'https://example.com/1',
    publishedAt: DateTime(2026, 3, 14),
    sourceName: 'Test Source',
  );

  final tArticleModel = ArticleModel(
    id: 'https://example.com/1',
    title: 'Test Article',
    url: 'https://example.com/1',
    publishedAt: DateTime(2026, 3, 14),
    sourceName: 'Test Source',
  );

  setUp(() {
    mockBox = MockBox();
    datasource = BookmarkLocalDataSourceImpl(box: mockBox);
  });

  group('getAllBookmarks', () {
    test('returns sorted list of ArticleModels from box', () {
      final older = ArticleModel(
        id: 'https://example.com/2',
        title: 'Older',
        url: 'https://example.com/2',
        publishedAt: DateTime(2026, 3, 13),
        sourceName: 'Source',
      );
      when(() => mockBox.values).thenReturn([older, tArticleModel]);

      final result = datasource.getAllBookmarks();

      // Sorted descending by publishedAt — tArticleModel (14th) comes first
      expect(result.first.id, tArticleModel.id);
      expect(result.last.id, older.id);
    });

    test('ignores non-ArticleModel entries', () {
      when(() => mockBox.values).thenReturn(['stale_string', tArticleModel]);

      final result = datasource.getAllBookmarks();

      expect(result, [tArticleModel]);
    });
  });

  group('saveBookmark', () {
    test('converts plain Article to ArticleModel before storing', () {
      when(() => mockBox.put(any<dynamic>(), any<dynamic>())).thenAnswer(
        (_) async {},
      );

      datasource.saveBookmark(tArticle);

      final captured = verify(
        () => mockBox.put(tArticle.id, captureAny<dynamic>()),
      ).captured;
      expect(captured.first, isA<ArticleModel>());
    });

    test('stores ArticleModel directly without wrapping', () {
      when(() => mockBox.put(any<dynamic>(), any<dynamic>())).thenAnswer(
        (_) async {},
      );

      datasource.saveBookmark(tArticleModel);

      final captured = verify(
        () => mockBox.put(tArticleModel.id, captureAny<dynamic>()),
      ).captured;
      expect(identical(captured.first, tArticleModel), isTrue);
    });
  });

  group('removeBookmark', () {
    test('deletes entry by articleId', () {
      when(() => mockBox.delete(any<dynamic>())).thenAnswer((_) async {});

      datasource.removeBookmark(tArticle.id);

      verify(() => mockBox.delete(tArticle.id)).called(1);
    });
  });

  group('isBookmarked', () {
    test('returns true when key exists', () {
      when(() => mockBox.containsKey(tArticle.id)).thenReturn(true);

      expect(datasource.isBookmarked(tArticle.id), isTrue);
    });

    test('returns false when key does not exist', () {
      when(() => mockBox.containsKey(tArticle.id)).thenReturn(false);

      expect(datasource.isBookmarked(tArticle.id), isFalse);
    });
  });
}
