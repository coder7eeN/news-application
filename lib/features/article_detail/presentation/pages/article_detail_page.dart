import 'package:flutter/material.dart';
import 'package:news_app/features/article_detail/presentation/notifier/article_detail_notifier.dart';
import 'package:news_app/features/bookmark/presentation/notifier/bookmark_notifier.dart';
import 'package:news_app/features/news_feed/domain/entities/article.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ArticleDetailPage extends StatefulWidget {
  final Article article;

  const ArticleDetailPage({super.key, required this.article});

  @override
  State<ArticleDetailPage> createState() => _ArticleDetailPageState();
}

class _ArticleDetailPageState extends State<ArticleDetailPage> {
  late final WebViewController _webController;
  late final ArticleDetailNotifier _notifier;

  @override
  void initState() {
    super.initState();
    _notifier = ArticleDetailNotifier();

    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: _notifier.onPageStarted,
          onProgress: _notifier.onProgress,
          onPageFinished: _notifier.onPageFinished,
        ),
      )
      ..loadRequest(Uri.parse(widget.article.url));
  }

  @override
  void dispose() {
    _notifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.article.sourceName),
        actions: [
          Consumer<BookmarkNotifier>(
            builder: (context, notifier, _) {
              final isBookmarked = notifier.isBookmarked(widget.article.id);
              return IconButton(
                icon: Icon(
                  isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                ),
                onPressed: () => notifier.toggleBookmark(widget.article),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _webController),

          // Loading progress bar (ValueListenableBuilder — no setState needed)
          ValueListenableBuilder<bool>(
            valueListenable: _notifier.isLoading,
            builder: (_, loading, _) {
              if (!loading) return const SizedBox.shrink();
              return ValueListenableBuilder<int>(
                valueListenable: _notifier.progress,
                builder: (_, prog, _) => LinearProgressIndicator(
                  value: prog / 100,
                  backgroundColor: Colors.transparent,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
