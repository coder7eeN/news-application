import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:news_app/core/error/failures.dart';
import 'package:news_app/features/news_feed/domain/entities/article.dart';
import 'package:news_app/features/news_feed/domain/repositories/i_news_feed_repository.dart';
import 'package:news_app/features/news_feed/domain/usecases/get_latest_articles.dart';

class MockNewsFeedRepository extends Mock implements INewsFeedRepository {}

void main() {
  late GetLatestArticlesUseCase useCase;
  late MockNewsFeedRepository mockRepository;

  setUp(() {
    mockRepository = MockNewsFeedRepository();
    useCase = GetLatestArticlesUseCase(mockRepository);
  });

  final tArticles = [
    Article(
      id: 'https://example.com/1',
      title: 'Test Article 1',
      url: 'https://example.com/1',
      publishedAt: DateTime(2026, 3, 14),
      sourceName: 'Test Source',
    ),
    Article(
      id: 'https://example.com/2',
      title: 'Test Article 2',
      url: 'https://example.com/2',
      publishedAt: DateTime(2026, 3, 13),
      sourceName: 'Another Source',
    ),
  ];

  group('call', () {
    test('should return list of articles on success', () async {
      // arrange
      when(() => mockRepository.getLatestArticles(any()))
          .thenAnswer((_) async => Right(tArticles));

      // act
      final result = await useCase(1);

      // assert
      expect(result, Right<Failure, List<Article>>(tArticles));
      verify(() => mockRepository.getLatestArticles(1)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return ServerFailure when repository fails', () async {
      // arrange
      const tFailure = ServerFailure();
      when(() => mockRepository.getLatestArticles(any()))
          .thenAnswer((_) async => const Left(tFailure));

      // act
      final result = await useCase(1);

      // assert
      expect(result, const Left<Failure, List<Article>>(tFailure));
      verify(() => mockRepository.getLatestArticles(1)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return NoInternetFailure when offline', () async {
      // arrange
      const tFailure = NoInternetFailure();
      when(() => mockRepository.getLatestArticles(any()))
          .thenAnswer((_) async => const Left(tFailure));

      // act
      final result = await useCase(1);

      // assert
      expect(result, const Left<Failure, List<Article>>(tFailure));
    });

    test('should pass correct page parameter to repository', () async {
      // arrange
      when(() => mockRepository.getLatestArticles(any()))
          .thenAnswer((_) async => Right(tArticles));

      // act
      await useCase(2);

      // assert
      verify(() => mockRepository.getLatestArticles(2)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });
  });
}
