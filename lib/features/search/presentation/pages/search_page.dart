import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:news_app/core/di/injection_container.dart';
import 'package:news_app/core/router/app_router.dart';
import 'package:news_app/core/widgets/error_view.dart';
import 'package:news_app/core/widgets/offline_banner.dart';
import 'package:news_app/core/widgets/shimmer_list.dart';
import 'package:news_app/features/news_feed/presentation/widgets/article_card.dart';
import 'package:news_app/features/search/presentation/bloc/search_bloc.dart';
import 'package:news_app/features/search/presentation/bloc/search_event.dart';
import 'package:news_app/features/search/presentation/bloc/search_state.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SearchBloc>(),
      child: const _SearchView(),
    );
  }
}

class _SearchView extends StatefulWidget {
  const _SearchView();

  @override
  State<_SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<_SearchView> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_isNearBottom) return;
    final state = context.read<SearchBloc>().state;
    if (state is SearchLoaded && !state.isLoadingMore && !state.hasReachedMax) {
      context.read<SearchBloc>().add(const SearchLoadMore());
    }
  }

  bool get _isNearBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    const scrollThreshold = 0.8;
    return currentScroll >= maxScroll * scrollThreshold;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search articles...',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            border: InputBorder.none,
            prefixIcon: const Icon(Icons.search, color: Colors.white),
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear, color: Colors.white),
              onPressed: () {
                context.read<SearchBloc>().add(const SearchQueryChanged(''));
                _searchController.clear();
              },
            ),
          ),
          onChanged: (query) {
            context.read<SearchBloc>().add(SearchQueryChanged(query));
          },
        ),
      ),
      body: OfflineBanner(
        child: BlocConsumer<SearchBloc, SearchState>(
          listener: (context, state) {
            if (state is SearchLoaded && state.paginationError != null) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(state.paginationError!),
                    action: SnackBarAction(
                      label: 'Retry',
                      onPressed: () => context.read<SearchBloc>().add(
                        const SearchLoadMore(),
                      ),
                    ),
                  ),
                );
            }
          },
          builder: (context, state) {
            if (state is SearchInitial) {
              return const Center(child: Text('Search for news articles'));
            }
            if (state is SearchLoading) {
              return const ShimmerList();
            }
            if (state is SearchLoaded) {
              final itemCount = state.isLoadingMore
                  ? state.articles.length + 1
                  : state.articles.length;
              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(8),
                itemCount: itemCount,
                itemBuilder: (context, index) {
                  if (index >= state.articles.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final article = state.articles[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ArticleCard(
                      article: article,
                      onTap: () =>
                          context.push(AppRouter.articleDetail, extra: article),
                    ),
                  );
                },
              );
            }
            if (state is SearchEmpty) {
              return const ErrorView(
                message: 'No articles found',
                icon: Icons.search_off,
              );
            }
            if (state is SearchError) {
              return ErrorView(message: state.message);
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
