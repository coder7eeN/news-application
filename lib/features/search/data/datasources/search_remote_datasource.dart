import 'package:dio/dio.dart';
import 'package:news_app/core/error/exceptions.dart';
import 'package:news_app/features/news_feed/data/models/article_model.dart';

/// Abstract interface for search remote data operations
abstract class SearchRemoteDataSource {
  /// Search articles by keyword from NewsAPI
  /// Throws [ServerException] on API errors
  /// Rethrows [DioException] on cancellation
  Future<List<ArticleModel>> searchArticles(String query);

  /// Cancel any pending search request
  void cancelPendingSearch();
}

/// Implementation using Dio with CancelToken for request cancellation
class SearchRemoteDataSourceImpl implements SearchRemoteDataSource {
  final Dio dio;
  CancelToken? _cancelToken;

  SearchRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<ArticleModel>> searchArticles(String query) async {
    _cancelToken?.cancel('superseded by new query');
    _cancelToken = CancelToken();

    try {
      final response = await dio.get<Map<String, dynamic>>(
        '/everything',
        queryParameters: {'q': query, 'pageSize': 20, 'language': 'en'},
        cancelToken: _cancelToken,
      );

      final articles = response.data?['articles'] as List<dynamic>?;
      if (articles == null) {
        throw const ServerException('Invalid response format');
      }

      return articles
          .map((json) => ArticleModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) rethrow;
      final mappedError = e.error;
      if (mappedError is AppException) throw mappedError;
      throw ServerException(e.message ?? 'Server error occurred');
    }
  }

  @override
  void cancelPendingSearch() {
    _cancelToken?.cancel('search cancelled');
    _cancelToken = null;
  }
}
