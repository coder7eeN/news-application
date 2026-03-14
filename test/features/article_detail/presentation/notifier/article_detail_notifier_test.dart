import 'package:flutter_test/flutter_test.dart';
import 'package:news_app/features/article_detail/presentation/notifier/article_detail_notifier.dart';
import 'package:news_app/features/article_detail/presentation/notifier/article_detail_state.dart';
import 'package:news_app/features/news_feed/domain/entities/article.dart';

void main() {
  late ArticleDetailNotifier notifier;

  setUp(() {
    notifier = ArticleDetailNotifier();
  });

  tearDown(() => notifier.dispose());

  final tArticle = Article(
    id: 'https://example.com/1',
    title: 'Test Article',
    url: 'https://example.com/1',
    publishedAt: DateTime(2026, 3, 14),
    sourceName: 'Test Source',
    description: 'Test description',
  );

  test('initial state is ArticleDetailLoading', () {
    expect(notifier.value, const ArticleDetailLoading());
  });

  test('loadArticle transitions to ArticleDetailLoaded', () {
    notifier.loadArticle(tArticle);
    expect(notifier.value, ArticleDetailLoaded(article: tArticle));
  });

  test('setError transitions to ArticleDetailError', () {
    notifier.setError('Something went wrong');
    expect(notifier.value, const ArticleDetailError('Something went wrong'));
  });

  test('loadArticle after error returns to loaded state', () {
    notifier.setError('Something went wrong');
    notifier.loadArticle(tArticle);
    expect(notifier.value, ArticleDetailLoaded(article: tArticle));
  });
}
