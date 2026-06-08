import 'package:flutter/material.dart';
import 'package:delivery_front/shared/services/local_storage_service.dart';

class ThemeController {
  static const String _key = 'app_theme_mode';

  static final ValueNotifier<ThemeMode> themeMode =
      ValueNotifier(ThemeMode.light);

  static Future<void> init() async {
    final saved = await LocalStorageService.getString(_key);
    if (saved == 'dark') {
      themeMode.value = ThemeMode.dark;
    } else {
      themeMode.value = ThemeMode.light;
    }
  }

  static Future<void> toggle() async {
    final isDark = themeMode.value == ThemeMode.dark;
    themeMode.value = isDark ? ThemeMode.light : ThemeMode.dark;
    await LocalStorageService.setString(_key, isDark ? 'light' : 'dark');
  }

  static bool get isDark => themeMode.value == ThemeMode.dark;
}
