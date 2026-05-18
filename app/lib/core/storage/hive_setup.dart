import 'package:hive_flutter/hive_flutter.dart';

class HiveSetup {
  HiveSetup._();

  static const expensesBox = 'expenses_cache';
  static const groupsBox = 'groups_cache';
  static const activityBox = 'activity_cache';
  static const settingsBox = 'settings';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox(expensesBox),
      Hive.openBox(groupsBox),
      Hive.openBox(activityBox),
      Hive.openBox(settingsBox),
    ]);
  }
}
