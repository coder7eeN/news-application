import 'package:flutter/material.dart';
import 'package:hive_ce/hive.dart';
import 'package:news_app/app.dart';
import 'package:news_app/core/cache/hive_helper.dart';
import 'package:news_app/core/di/injection_container.dart' as di;
import 'package:news_app/features/news_feed/data/models/article_model.dart';

Future<void> main() async {
  // Ensure Flutter binding is initialized before async operations
  WidgetsFlutterBinding.ensureInitialized();

  // Register Hive adapters before opening boxes
  Hive.registerAdapter(ArticleModelAdapter());

  // Initialize Hive local storage
  await HiveHelper.initHive();

  // Initialize dependency injection
  await di.init();

  runApp(const NewsApp());
}
