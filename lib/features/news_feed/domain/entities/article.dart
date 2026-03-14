import 'package:equatable/equatable.dart';

/// Pure Dart entity representing a news article
/// No Flutter framework dependencies, no JSON serialization
class Article extends Equatable {
  final String id; // URL used as stable unique ID
  final String title;
  final String? description;
  final String? urlToImage;
  final String url;
  final String? content;
  final DateTime publishedAt;
  final String sourceName;
  final String? author;

  const Article({
    required this.id,
    required this.title,
    this.description,
    this.urlToImage,
    required this.url,
    this.content,
    required this.publishedAt,
    required this.sourceName,
    this.author,
  });

  @override
  List<Object?> get props => [id];
}
