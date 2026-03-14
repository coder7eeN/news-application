import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:news_app/features/article_detail/presentation/pages/article_detail_page.dart';
import 'package:news_app/features/bookmark/presentation/pages/bookmark_page.dart';
import 'package:news_app/features/news_feed/domain/entities/article.dart';
import 'package:news_app/features/news_feed/presentation/pages/news_feed_page.dart';
import 'package:news_app/features/search/presentation/pages/search_page.dart';

class AppRouter {
  const AppRouter._();

  static const String newsFeed = '/';
  static const String articleDetail = '/article-detail';
  static const String search = '/search';
  static const String bookmarks = '/bookmarks';

  static final GoRouter router = GoRouter(
    initialLocation: newsFeed,
    routes: [
      GoRoute(
        path: newsFeed,
        builder: (context, state) => const NewsFeedPage(),
      ),
      GoRoute(
        path: articleDetail,
        builder: (context, state) {
          final article = state.extra! as Article;
          return ArticleDetailPage(article: article);
        },
      ),
      GoRoute(path: search, builder: (context, state) => const SearchPage()),
      GoRoute(
        path: bookmarks,
        builder: (context, state) => const BookmarkPage(),
      ),
    ],
    errorBuilder: (context, state) =>
        const Scaffold(body: Center(child: Text('Page not found'))),
  );
}
