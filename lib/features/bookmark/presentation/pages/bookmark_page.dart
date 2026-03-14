import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:news_app/core/router/app_router.dart';
import 'package:news_app/features/bookmark/presentation/notifier/bookmark_notifier.dart';
import 'package:news_app/features/news_feed/presentation/widgets/article_card.dart';

class BookmarkPage extends StatelessWidget {
  const BookmarkPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bookmarks')),
      body: Consumer<BookmarkNotifier>(
        builder: (context, notifier, _) {
          final bookmarks = notifier.bookmarks;

          if (bookmarks.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.bookmark_border,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No saved articles',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: bookmarks.length,
            itemBuilder: (context, index) {
              final article = bookmarks[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ArticleCard(
                  article: article,
                  onTap: () => context.push(
                    AppRouter.articleDetail,
                    extra: article,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
