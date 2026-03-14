import 'package:equatable/equatable.dart';

abstract class NewsFeedEvent extends Equatable {
  const NewsFeedEvent();
}

/// Dispatched to fetch the first page of latest articles
class FetchLatestArticles extends NewsFeedEvent {
  const FetchLatestArticles();

  @override
  List<Object> get props => [];
}

/// Dispatched to load the next page of articles
class FetchNextPage extends NewsFeedEvent {
  const FetchNextPage();

  @override
  List<Object> get props => [];
}

/// Dispatched on pull-to-refresh to reset and reload from page 1
class RefreshFeed extends NewsFeedEvent {
  const RefreshFeed();

  @override
  List<Object> get props => [];
}
