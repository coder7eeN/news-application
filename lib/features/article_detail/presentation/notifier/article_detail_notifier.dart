import 'package:flutter/foundation.dart';

/// Tracks WebView loading state for the article detail screen
class ArticleDetailNotifier {
  /// true while Webview is loading the page
  final ValueNotifier<bool> isLoading = ValueNotifier(true);

  /// 0-100 progress for linear progress indicator
  final ValueNotifier<int> progress = ValueNotifier(0);

  void onPageStarted(String url) {
    isLoading.value = true;
    progress.value = 0;
  }

  void onProgress(int p) {
    progress.value = p;
  }

  void onPageFinished(String url) {
    isLoading.value = false;
    progress.value = 100;
  }

  void dispose() {
    isLoading.dispose();
    progress.dispose();
  }
}
