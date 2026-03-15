import 'package:dio/dio.dart';
import 'package:news_app/core/cache/cache_constants.dart';
import 'package:news_app/core/error/exceptions.dart';
import 'package:news_app/features/news_feed/data/models/article_model.dart';

/// Abstract interface for news feed remote data operations
abstract class NewsFeedRemoteDataSource {
  /// Fetch articles from NewsAPI
  /// Returns (articles, totalResults)
  /// Throws [ServerException] on API errors
  /// Throws [TimeoutException] on timeout
  Future<(List<ArticleModel>, int)> fetchArticles(int page);
}

/// Implementation of NewsFeedRemoteDataSource using Dio
class NewsFeedRemoteDataSourceImpl implements NewsFeedRemoteDataSource {
  final Dio dio;

  const NewsFeedRemoteDataSourceImpl({required this.dio});

  @override
  Future<(List<ArticleModel>, int)> fetchArticles(int page) async {
    try {
      final now = DateTime.now();
      final lastMonth = DateTime(now.year, now.month - 1, now.day);
      final fromDateStr = lastMonth.toIso8601String().split('T').first;

      final response = await dio.get<Map<String, dynamic>>(
        '/everything',
        queryParameters: {
          'q': 'tesla',
          'from': fromDateStr,
          'sortBy': 'publishedAt',
          'language': 'en',
          'pageSize': CacheConstants.pageSize,
          'page': page,
        },
      );

      final data = response.data;
      final articles = data?['articles'] as List<dynamic>?;
      final totalResults = data?['totalResults'] as int? ?? 0;

      if (articles == null) {
        throw const ServerException('Invalid response format');
      }

      final models = articles
          .map((json) => ArticleModel.fromJson(json as Map<String, dynamic>))
          .toList();

      return (models, totalResults);
    } on DioException catch (e) {
      final mappedError = e.error;
      if (mappedError is AppException) {
        throw mappedError;
      }
      throw ServerException(e.message ?? 'Server error occurred');
    }
  }
}
