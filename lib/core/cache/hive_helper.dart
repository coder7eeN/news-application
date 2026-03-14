import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:news_app/core/cache/cache_constants.dart';

/// Helper class for Hive initialization and box management
class HiveHelper {
  const HiveHelper._();

  /// Initialize Hive and open all required boxes
  /// Must be called before any Hive operations
  static Future<void> initHive() async {
    // Initialize Hive for Flutter
    await Hive.initFlutter();

    // Open required boxes
    await Hive.openBox<dynamic>(CacheConstants.feedBoxName);
    await Hive.openBox<dynamic>(CacheConstants.bookmarksBoxName);
  }

  /// Get an already-opened Hive box by name
  /// Throws HiveError if box is not open
  static Box<T> getBox<T>(String name) {
    return Hive.box<T>(name);
  }
}
