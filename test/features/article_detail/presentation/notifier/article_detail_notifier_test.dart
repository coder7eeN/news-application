import 'package:flutter_test/flutter_test.dart';
import 'package:news_app/features/article_detail/presentation/notifier/article_detail_notifier.dart';

void main() {
  late ArticleDetailNotifier notifier;

  setUp(() {
    notifier = ArticleDetailNotifier();
  });

  tearDown(() => notifier.dispose());

  test('initial isLoading is true', () {
    expect(notifier.isLoading.value, true);
  });

  test('initial progress is 0', () {
    expect(notifier.progress.value, 0);
  });

  test('onPageStarted sets isLoading to true and progress to 0', () {
    notifier.onPageFinished('https://example.com');
    notifier.onPageStarted('https://example.com');
    expect(notifier.isLoading.value, true);
    expect(notifier.progress.value, 0);
  });

  test('onProgress updates progress value', () {
    notifier.onProgress(50);
    expect(notifier.progress.value, 50);
  });

  test('onPageFinished sets isLoading to false and progress to 100', () {
    notifier.onPageFinished('https://example.com');
    expect(notifier.isLoading.value, false);
    expect(notifier.progress.value, 100);
  });
}
