import 'package:dio/dio.dart';
import 'package:news_app/core/cache/cache_constants.dart';
import 'package:news_app/core/error/exceptions.dart';
import 'package:news_app/features/news_feed/data/models/article_model.dart';

/// Abstract interface for news feed remote data operations
abstract class NewsFeedRemoteDataSource {
  /// Fetch top headlines articles from NewsAPI
  /// Throws [ServerException] on API errors
  /// Throws [TimeoutException] on timeout
  Future<List<ArticleModel>> fetchArticles(int page);
}

/// Implementation of NewsFeedRemoteDataSource using Dio
class NewsFeedRemoteDataSourceImpl implements NewsFeedRemoteDataSource {
  final Dio dio;

  const NewsFeedRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<ArticleModel>> fetchArticles(int page) async {
    try {
      // Calculate date 30 days ago for recent articles
      final fromDate = DateTime.now().subtract(const Duration(days: 30));
      final fromDateStr = fromDate.toIso8601String().split('T').first;

      final response = await dio.get<Map<String, dynamic>>(
        '/everything',
        queryParameters: {
          'q': 'news',
          'from': fromDateStr,
          'sortBy': 'publishedAt',
          'language': 'en',
          'pageSize': CacheConstants.pageSize,
          'page': page,
        },
      );

      final articles = response.data?['articles'] as List<dynamic>?;
      if (articles == null) {
        throw const ServerException('Invalid response format');
      }

      return articles
          .map((json) => ArticleModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      // ErrorInterceptor maps DioException → AppException in e.error
      final mappedError = e.error;
      if (mappedError is AppException) {
        throw mappedError;
      }
      throw ServerException(e.message ?? 'Server error occurred');
    }
  }
}
