import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../services/storage_service.dart';
import '../theme/app_theme.dart';

/// Quản lý Dark Mode và màu chủ đạo.
class ThemeController extends GetxController {
  final StorageService _storage = StorageService();

  final isDark = false.obs;
  final paletteIndex = 0.obs;

  ThemeMode get themeMode => isDark.value ? ThemeMode.dark : ThemeMode.light;
  Color get seed => kPalettes[paletteIndex.value].seed;

  /// Nạp cấu hình đã lưu.
  Future<void> load() async {
    isDark.value = await _storage.getDarkMode();
    final i = await _storage.getPaletteIndex();
    paletteIndex.value = (i >= 0 && i < kPalettes.length) ? i : 0;
  }

  Future<void> toggle(bool value) async {
    isDark.value = value;
    await _storage.setDarkMode(value);
  }

  /// Chọn màu chủ đạo.
  Future<void> setPalette(int index) async {
    paletteIndex.value = index;
    await _storage.setPaletteIndex(index);
  }
}
