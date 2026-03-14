import 'package:equatable/equatable.dart';
import 'package:news_app/features/news_feed/domain/entities/article.dart';

/// Base class for all search states
abstract class SearchState extends Equatable {
  const SearchState();
}

/// Initial state — empty search bar
class SearchInitial extends SearchState {
  const SearchInitial();

  @override
  List<Object> get props => [];
}

/// Loading state — spinner
class SearchLoading extends SearchState {
  const SearchLoading();

  @override
  List<Object> get props => [];
}

/// Loaded state — results list
class SearchLoaded extends SearchState {
  final List<Article> articles;

  const SearchLoaded({required this.articles});

  @override
  List<Object> get props => [articles];
}

/// Empty state — no results found
class SearchEmpty extends SearchState {
  const SearchEmpty();

  @override
  List<Object> get props => [];
}

/// Error state — error message
class SearchError extends SearchState {
  final String message;

  const SearchError(this.message);

  @override
  List<Object> get props => [message];
}
