import 'package:flutter/material.dart';

/// Khoảng cách chuẩn toàn app (thang 4/8).
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

/// Một màu chủ đạo người dùng có thể chọn trong Cài đặt.
class AppPalette {
  final String name;
  final Color seed;
  const AppPalette(this.name, this.seed);
}

/// Danh sách màu giao diện (9 màu chủ đạo đa dạng phong cách).
const List<AppPalette> kPalettes = [
  AppPalette('Teal', Color(0xFF0D9488)),
  AppPalette('Xanh dương', Color(0xFF2563EB)),
  AppPalette('Tím', Color(0xFF7C3AED)),
  AppPalette('Hồng', Color(0xFFE11D48)),
  AppPalette('Cam', Color(0xFFEA580C)),
  AppPalette('Xanh lá', Color(0xFF16A34A)),
  AppPalette('Xanh chàm', Color(0xFF4F46E5)),
  AppPalette('Hổ phách', Color(0xFFD97706)),
  AppPalette('Đỏ Ruby', Color(0xFFDC2626)),
];

/// Màu sao đánh giá (đủ tương phản trên cả nền sáng và tối).
const Color kStarColor = Color(0xFFF59E0B);

/// Tạo ThemeData Material 3 theo màu chủ đạo.
class AppTheme {
  static const String fontFamily = 'BeVietnamPro';

  static ThemeData build(Color seed, Brightness brightness) {
    final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
    final base = ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      fontFamily: fontFamily,
    );

    // Thang chữ: nội dung >= 16px, line-height thoáng
    final text = base.textTheme.copyWith(
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        height: 1.25,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(fontSize: 16, height: 1.5),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(fontSize: 15, height: 1.5),
    );

    final fieldShape = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    );

    return base.copyWith(
      textTheme: text,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge?.copyWith(color: scheme.onSurface),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        border: fieldShape,
        enabledBorder: fieldShape,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: text.titleMedium,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: text.titleMedium,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: scheme.primaryContainer,
        height: 68,
        labelTextStyle: WidgetStatePropertyAll(
          text.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.5),
        space: 1,
      ),
    );
  }
}

