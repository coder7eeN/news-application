import 'package:equatable/equatable.dart';

/// Base class for all search events
abstract class SearchEvent extends Equatable {
  const SearchEvent();
}

/// Dispatched when the search query text changes
class SearchQueryChanged extends SearchEvent {
  final String query;

  const SearchQueryChanged(this.query);

  @override
  List<Object> get props => [query];
}
