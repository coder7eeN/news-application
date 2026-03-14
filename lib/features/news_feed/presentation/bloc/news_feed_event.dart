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
