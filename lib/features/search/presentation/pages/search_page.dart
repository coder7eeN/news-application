import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app/core/di/injection_container.dart';
import 'package:news_app/features/article_detail/presentation/pages/article_detail_page.dart';
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

class _SearchView extends StatelessWidget {
  const _SearchView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search articles...',
            border: InputBorder.none,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                context.read<SearchBloc>().add(const SearchQueryChanged(''));
              },
            ),
          ),
          onChanged: (query) {
            context.read<SearchBloc>().add(SearchQueryChanged(query));
          },
        ),
      ),
      body: BlocBuilder<SearchBloc, SearchState>(
        builder: (context, state) {
          if (state is SearchInitial) {
            return const Center(child: Text('Search for news articles'));
          }
          if (state is SearchLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is SearchLoaded) {
            return ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: state.articles.length,
              itemBuilder: (context, index) {
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
            );
          }
          if (state is SearchEmpty) {
            return const Center(child: Text('No articles found'));
          }
          if (state is SearchError) {
            return Center(child: Text(state.message));
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
