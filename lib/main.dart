import 'package:flutter/material.dart';
import 'package:news_app/app.dart';
import 'package:news_app/core/cache/hive_helper.dart';
import 'package:news_app/core/di/injection_container.dart' as di;

Future<void> main() async {
  // Ensure Flutter binding is initialized before async operations
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive local storage
  await HiveHelper.initHive();

  // Initialize dependency injection
  await di.init();

  runApp(const NewsApp());
}
