import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:news_app/core/di/injection_container.dart';
import 'package:news_app/core/router/app_router.dart';
import 'package:news_app/core/theme/app_theme.dart';
import 'package:news_app/features/bookmark/presentation/notifier/bookmark_notifier.dart';

class NewsApp extends StatelessWidget {
  const NewsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: sl<BookmarkNotifier>(),
      child: MaterialApp.router(
        title: 'News App',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
