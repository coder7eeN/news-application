import 'package:flutter/material.dart';
import 'package:news_app/features/bookmark/presentation/pages/bookmark_page.dart';
import 'package:news_app/features/news_feed/domain/entities/article.dart';
import 'package:news_app/features/news_feed/presentation/pages/news_feed_page.dart';

class AppRouter {
  const AppRouter._();

  static const String newsFeed = '/';
  static const String articleDetail = '/article-detail';
  static const String search = '/search';
  static const String bookmarks = '/bookmarks';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case newsFeed:
        return MaterialPageRoute<void>(
          builder: (_) => const NewsFeedPage(),
        );
      case articleDetail:
        final article = settings.arguments! as Article;
        // ArticleDetailPage will be added in US-08
        return MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            appBar: AppBar(title: Text(article.title)),
            body: const Center(child: Text('Article Detail — Coming Soon')),
          ),
        );
      case search:
        // SearchPage will be added in US-06
        return MaterialPageRoute<void>(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Search — Coming Soon')),
          ),
        );
      case bookmarks:
        return MaterialPageRoute<void>(
          builder: (_) => const BookmarkPage(),
        );
      default:
        return MaterialPageRoute<void>(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Page not found')),
          ),
        );
    }
  }
}
