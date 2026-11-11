import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';

import 'controllers/auth_controller.dart';
import 'controllers/course_controller.dart';
import 'controllers/theme_controller.dart';
import 'controllers/vocab_controller.dart';
import 'services/storage_service.dart';
import 'services/supabase_service.dart';
import 'services/tts_service.dart';
import 'theme/app_theme.dart';
import 'views/login_screen.dart';
import 'views/main_layout_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Nạp biến môi trường từ file .env (chứa API Key)
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Dotenv notice: Không tìm thấy hoặc lỗi đọc file .env: $e');
  }

  // Khởi tạo kết nối Supabase (Auth & PostgreSQL)
  await SupabaseService.init();

  // Khởi tạo các controller & service dùng toàn app
  final themeController = Get.put(ThemeController());
  final authController = Get.put(AuthController());
  Get.put(VocabController()); // Dùng chung cho chat và màn ôn tập
  Get.put(CourseController()); // Quản lý khóa học & tiến độ học tập
  await Get.putAsync(() => TtsService().init());
  await themeController.load();
  final loggedIn = await authController.restoreSession();

  // Tự động đẩy toàn bộ dữ liệu đã có lên Supabase ở chế độ nền
  unawaited(StorageService().syncAllLocalDataToSupabase());

  runApp(MyApp(loggedIn: loggedIn));
}

class MyApp extends StatelessWidget {
  final bool loggedIn;

  const MyApp({super.key, required this.loggedIn});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();
    // Obx để đổi theme ngay khi đổi màu / bật tắt Dark Mode
    return Obx(
      () => GetMaterialApp(
        title: 'AI Language Mentor',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.build(themeController.seed, Brightness.light),
        darkTheme: AppTheme.build(themeController.seed, Brightness.dark),
        themeMode: themeController.themeMode,
        // Chuyển trang mượt, nhất quán
        defaultTransition: Transition.rightToLeftWithFade,
        transitionDuration: const Duration(milliseconds: 260),
        home: loggedIn ? const MainLayoutScreen() : const LoginScreen(),
      ),
    );
  }
}
