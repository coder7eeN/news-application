import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_app/core/di/injection_container.dart';
import 'package:news_app/features/news_feed/presentation/bloc/news_feed_bloc.dart';
import 'package:news_app/features/news_feed/presentation/bloc/news_feed_event.dart';
import 'package:news_app/features/news_feed/presentation/bloc/news_feed_state.dart';
import 'package:news_app/features/news_feed/presentation/widgets/article_card.dart';

class NewsFeedPage extends StatelessWidget {
  const NewsFeedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<NewsFeedBloc>()..add(const FetchLatestArticles()),
      child: Scaffold(
        appBar: AppBar(title: const Text('News')),
        body: BlocBuilder<NewsFeedBloc, NewsFeedState>(
          builder: (context, state) {
            if (state is NewsFeedLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is NewsFeedLoaded) {
              return ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: state.articles.length,
                itemBuilder: (context, index) {
                  final article = state.articles[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ArticleCard(
                      article: article,
                      onTap: () {
                        // Article detail navigation will be added in US-08
                      },
                    ),
                  );
                },
              );
            }
            if (state is NewsFeedError) {
              return Center(child: Text(state.message));
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
