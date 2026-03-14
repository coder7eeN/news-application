// ignore_for_file: overridden_fields, annotate_overrides

import 'package:hive_ce/hive.dart';
import 'package:news_app/features/news_feed/domain/entities/article.dart';

part 'article_model.g.dart';

/// Data model for Article with JSON and Hive serialization
/// Extends domain entity to inherit all properties
@HiveType(typeId: 0)
class ArticleModel extends Article {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final String? description;
  @HiveField(3)
  final String? urlToImage;
  @HiveField(4)
  final String url;
  @HiveField(5)
  final String? content;
  @HiveField(6)
  final DateTime publishedAt;
  @HiveField(7)
  final String sourceName;
  @HiveField(8)
  final String? author;

  const ArticleModel({
    required this.id,
    required this.title,
    this.description,
    this.urlToImage,
    required this.url,
    this.content,
    required this.publishedAt,
    required this.sourceName,
    this.author,
  }) : super(
          id: id,
          title: title,
          description: description,
          urlToImage: urlToImage,
          url: url,
          content: content,
          publishedAt: publishedAt,
          sourceName: sourceName,
          author: author,
        );

  /// Map news API response JSON to model
  factory ArticleModel.fromJson(Map<String, dynamic> json) {
    final url = (json['url'] as String?) ?? '';
    return ArticleModel(
      id: url,
      // URL is stable unique ID from NewsAPI
      title: (json['title'] as String?) ?? '',
      description: json['description'] as String?,
      urlToImage: json['urlToImage'] as String?,
      url: url,
      content: json['content'] as String?,
      publishedAt:
      DateTime.tryParse((json['publishedAt'] as String?) ?? '') ??
          DateTime.now(),
      sourceName:
      ((json['source'] as Map<String, dynamic>?)?['name'] as String?) ??
          'Unknown',
      author: json['author'] as String?,
    );
  }

  /// Convert ArticleModel to JSON for API requests
  Map<String, dynamic> toJson() => {
        'url': url,
        'title': title,
        'description': description,
        'urlToImage': urlToImage,
        'content': content,
        'publishedAt': publishedAt.toIso8601String(),
        'source': {'name': sourceName},
        'author': author,
      };
}
