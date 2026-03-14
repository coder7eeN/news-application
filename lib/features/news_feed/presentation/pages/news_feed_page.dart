import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app/core/di/injection_container.dart';
import 'package:news_app/core/widgets/error_view.dart';
import 'package:news_app/core/widgets/offline_banner.dart';
import 'package:news_app/features/article_detail/presentation/pages/article_detail_page.dart';
import 'package:news_app/features/bookmark/presentation/pages/bookmark_page.dart';
import 'package:news_app/features/news_feed/presentation/bloc/news_feed_bloc.dart';
import 'package:news_app/features/news_feed/presentation/bloc/news_feed_event.dart';
import 'package:news_app/features/news_feed/presentation/bloc/news_feed_state.dart';
import 'package:news_app/features/news_feed/presentation/widgets/article_card.dart';
import 'package:news_app/features/search/presentation/pages/search_page.dart';

class NewsFeedPage extends StatelessWidget {
  const NewsFeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<NewsFeedBloc>()..add(const FetchLatestArticles()),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('News'),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const SearchPage(),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.bookmark),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => const BookmarkPage(),
                ),
              ),
            ),
          ],
        ),
        body: const OfflineBanner(child: _NewsFeedView()),
      ),
    );
  }
}

class _NewsFeedView extends StatefulWidget {
  const _NewsFeedView();

  @override
  State<_NewsFeedView> createState() => _NewsFeedViewState();
}

class _NewsFeedViewState extends State<_NewsFeedView> {
  final _scrollController = ScrollController();

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
    super.dispose();
  }

  void _onScroll() {
    if (_isNearBottom) {
      context.read<NewsFeedBloc>().add(const FetchNextPage());
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
    return BlocConsumer<NewsFeedBloc, NewsFeedState>(
      listener: (context, state) {
        if (state is NewsFeedLoaded && state.paginationError != null) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(state.paginationError!),
                action: SnackBarAction(
                  label: 'Retry',
                  onPressed: () =>
                      context.read<NewsFeedBloc>().add(const FetchNextPage()),
                ),
              ),
            );
        }
      },
      builder: (context, state) {
        if (state is NewsFeedLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is NewsFeedLoaded) {
          final itemCount =
              state.isLoadingMore
                  ? state.articles.length + 1
                  : state.articles.length;
          return RefreshIndicator(
            onRefresh: () async {
              final bloc = context.read<NewsFeedBloc>();
              final future = bloc.stream.firstWhere(
                (s) => s is NewsFeedLoaded || s is NewsFeedError,
              );
              bloc.add(const RefreshFeed());
              await future.timeout(
                const Duration(seconds: 10),
                onTimeout: () => state,
              );
            },
            child: ListView.builder(
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
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            ArticleDetailPage(article: article),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        }
        if (state is NewsFeedError) {
          return ErrorView(
            message: state.message,
            icon: Icons.wifi_off,
            onRetry: () =>
                context.read<NewsFeedBloc>().add(const FetchLatestArticles()),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
