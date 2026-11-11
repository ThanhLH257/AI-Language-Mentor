import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Quản lý kết nối Supabase (Auth + PostgreSQL Database).
class SupabaseService {
  /// Lấy cấu hình Supabase từ biến môi trường (.env)
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabasePublishableKey =>
      dotenv.env['SUPABASE_PUBLISHABLE_KEY'] ?? '';

  /// Deep link callback cho đăng nhập Google OAuth trên Android/iOS.
  static const String redirectUrl = 'io.supabase.lgwithai://login-callback/';

  static bool _initialized = false;

  static bool get isInitialized => _initialized;

  static SupabaseClient get client => Supabase.instance.client;

  /// Khởi tạo Supabase khi mở ứng dụng.
  static Future<void> init() async {
    if (_initialized) return;

    final url = supabaseUrl.trim();
    final key = supabasePublishableKey.trim();

    if (url.isEmpty || key.isEmpty) {
      debugPrint(
        'Supabase notice: Chưa cấu hình SUPABASE_URL hoặc SUPABASE_PUBLISHABLE_KEY trong file .env',
      );
      return;
    }

    try {
      await Supabase.initialize(
        url: url,
        publishableKey: key,
      );
      _initialized = true;
    } catch (e) {
      debugPrint('Supabase init warning: $e');
    }
  }
}
