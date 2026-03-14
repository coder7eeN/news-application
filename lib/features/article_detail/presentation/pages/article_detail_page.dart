import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:news_app/core/di/injection_container.dart';
import 'package:news_app/core/widgets/error_view.dart';
import 'package:news_app/features/article_detail/presentation/notifier/article_detail_notifier.dart';
import 'package:news_app/features/article_detail/presentation/notifier/article_detail_state.dart';
import 'package:news_app/features/bookmark/presentation/notifier/bookmark_notifier.dart';
import 'package:news_app/features/news_feed/domain/entities/article.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ArticleDetailPage extends StatefulWidget {
  final Article article;

  const ArticleDetailPage({super.key, required this.article});

  @override
  State<ArticleDetailPage> createState() => _ArticleDetailPageState();
}

class _ArticleDetailPageState extends State<ArticleDetailPage> {
  late final ArticleDetailNotifier _notifier;

  @override
  void initState() {
    super.initState();
    _notifier = sl<ArticleDetailNotifier>()..loadArticle(widget.article);
  }

  @override
  void dispose() {
    _notifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ArticleDetailState>(
      valueListenable: _notifier,
      builder: (context, state, _) {
        if (state is ArticleDetailLoading) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (state is ArticleDetailLoaded) {
          return _ArticleDetailView(article: state.article);
        }
        if (state is ArticleDetailError) {
          return Scaffold(
            appBar: AppBar(),
            body: ErrorView(
              message: state.message,
              onRetry: () => _notifier.loadArticle(widget.article),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _ArticleDetailView extends StatelessWidget {
  final Article article;

  const _ArticleDetailView({required this.article});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(article.sourceName),
        actions: [
          Consumer<BookmarkNotifier>(
            builder: (context, notifier, _) {
              final isBookmarked = notifier.isBookmarked(article.id);
              return IconButton(
                icon: Icon(
                  isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                ),
                onPressed: () => notifier.toggleBookmark(article),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (article.urlToImage != null)
              Image.network(
                article.urlToImage!,
                height: 250,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox(height: 250),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildMetaRow(context),
                  if (article.description != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      article.description!,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                  if (article.content != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      article.content!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              _ArticleWebViewPage(article: article),
                        ),
                      ),
                      icon: const Icon(Icons.open_in_browser),
                      label: const Text('Read Full Article'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaRow(BuildContext context) {
    final parts = <String>[article.sourceName];
    if (article.author != null) {
      parts.add(article.author!);
    }
    parts.add(_formatDate(article.publishedAt));

    return Text(
      parts.join(' · '),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Colors.grey[600],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _ArticleWebViewPage extends StatefulWidget {
  final Article article;

  const _ArticleWebViewPage({required this.article});

  @override
  State<_ArticleWebViewPage> createState() => _ArticleWebViewPageState();
}

class _ArticleWebViewPageState extends State<_ArticleWebViewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onWebResourceError: (error) => setState(() {
            _isLoading = false;
            _errorMessage = error.description;
          }),
        ),
      )
      ..loadRequest(Uri.parse(widget.article.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.article.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Column(
        children: [
          if (_isLoading) const LinearProgressIndicator(),
          Expanded(
            child: _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Could not load article.\n${widget.article.url}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : WebViewWidget(controller: _controller),
          ),
        ],
      ),
    );
  }
}
