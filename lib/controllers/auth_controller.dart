import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../controllers/course_controller.dart';
import '../models/user_account.dart';
import '../services/storage_service.dart';
import '../services/supabase_service.dart';
import '../views/login_screen.dart';
import '../views/main_layout_screen.dart';

/// Quản lý đăng nhập, đăng ký, đăng nhập Google (Supabase OAuth) và đăng xuất.
class AuthController extends GetxController {
  final StorageService _storage = StorageService();

  final currentUser = Rxn<UserAccount>();
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  StreamSubscription<AuthState>? _authSub;

  @override
  void onInit() {
    super.onInit();
    _listenSupabaseAuthChanges();
  }

  @override
  void onClose() {
    _authSub?.cancel();
    super.onClose();
  }

  /// Lắng nghe sự kiện đăng nhập thành công từ Google OAuth (Deep Link callback).
  void _listenSupabaseAuthChanges() {
    if (!SupabaseService.isInitialized) return;
    _authSub = SupabaseService.client.auth.onAuthStateChange.listen(
      (data) async {
        final event = data.event;
        final session = data.session;
        if (event == AuthChangeEvent.signedIn && session?.user != null) {
          await _syncFromSupabaseUser(session!.user, navigateHome: true);
        }
      },
      onError: (Object err) {
        debugPrint('Supabase Auth stream error: $err');
        errorMessage.value = 'Đăng nhập Google thất bại: $err';
        isLoading.value = false;
      },
    );
  }

  /// Đồng bộ thông tin User từ Supabase (Google / Email) về bộ nhớ ứng dụng.
  Future<void> _syncFromSupabaseUser(
    User sbUser, {
    String? fallbackName,
    String? fallbackPassword,
    bool navigateHome = false,
  }) async {
    final mail = (sbUser.email ?? '').trim().toLowerCase();
    if (mail.isEmpty) return;

    final meta = sbUser.userMetadata ?? {};
    final displayName = (meta['full_name'] as String?) ??
        (meta['name'] as String?) ??
        fallbackName ??
        mail.split('@').first;

    final users = await _storage.loadUsers();
    final idx = users.indexWhere((u) => u.email == mail);
    final account = UserAccount(
      name: displayName.trim().isNotEmpty ? displayName.trim() : mail,
      email: mail,
      password: fallbackPassword ?? (idx >= 0 ? users[idx].password : 'google_oauth'),
    );

    if (idx >= 0) {
      users[idx] = account;
    } else {
      users.add(account);
    }
    await _storage.saveUsers(users);
    await _storage.setCurrentUserEmail(mail);

    final alreadyLoggedIn = currentUser.value?.email == mail;
    currentUser.value = account;
    isLoading.value = false;

    if (Get.isRegistered<CourseController>()) {
      await Get.find<CourseController>().load();
    }
    unawaited(_storage.syncAllLocalDataToSupabase());

    if (navigateHome && (!alreadyLoggedIn || Get.currentRoute != '/MainLayoutScreen')) {
      Get.offAll(() => const MainLayoutScreen());
    }
  }

  /// Khôi phục phiên đăng nhập; trả về true nếu đã đăng nhập.
  Future<bool> restoreSession() async {
    // 1. Kiểm tra phiên Supabase hiện tại (bao gồm phiên đăng nhập Google)
    if (SupabaseService.isInitialized) {
      final sbUser = SupabaseService.client.auth.currentUser;
      if (sbUser != null && sbUser.email != null) {
        await _syncFromSupabaseUser(sbUser, navigateHome: false);
        return true;
      }
    }

    // 2. Fallback kiểm tra phiên lưu cục bộ
    final email = await _storage.getCurrentUserEmail();
    if (email == null) return false;
    final users = await _storage.loadUsers();
    final found = users.where((u) => u.email == email);
    if (found.isEmpty) return false;
    currentUser.value = found.first;
    if (Get.isRegistered<CourseController>()) {
      Get.find<CourseController>().load();
    }
    return true;
  }

  /// Đăng nhập bằng tài khoản Google thông qua Supabase OAuth.
  Future<void> loginWithGoogle() async {
    errorMessage.value = '';
    if (!SupabaseService.isInitialized) {
      errorMessage.value = 'Chưa khởi tạo được kết nối Supabase';
      return;
    }
    try {
      isLoading.value = true;
      await SupabaseService.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: SupabaseService.redirectUrl,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
    } on AuthException catch (e) {
      errorMessage.value = 'Lỗi xác thực Google: ${e.message}';
    } catch (e) {
      errorMessage.value = 'Không thể mở đăng nhập Google: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> login(String email, String password) async {
    errorMessage.value = '';
    final mail = email.trim().toLowerCase();
    if (mail.isEmpty || password.isEmpty) {
      errorMessage.value = 'Vui lòng nhập đầy đủ email và mật khẩu';
      return;
    }
    isLoading.value = true;

    // 1. Thử đăng nhập qua Supabase Auth trước
    if (SupabaseService.isInitialized) {
      try {
        final res = await SupabaseService.client.auth.signInWithPassword(
          email: mail,
          password: password,
        );
        if (res.user != null) {
          await _syncFromSupabaseUser(
            res.user!,
            fallbackPassword: password,
            navigateHome: true,
          );
          isLoading.value = false;
          return;
        }
      } catch (e) {
        debugPrint('Supabase email login fallback to local: $e');
      }
    }

    // 2. Fallback kiểm tra tài khoản lưu cục bộ
    final users = await _storage.loadUsers();
    final found = users.where(
      (u) => u.email == mail && u.password == password,
    );
    if (found.isEmpty) {
      errorMessage.value = 'Email hoặc mật khẩu không đúng';
    } else {
      currentUser.value = found.first;
      await _storage.setCurrentUserEmail(found.first.email);
      if (Get.isRegistered<CourseController>()) {
        await Get.find<CourseController>().load();
      }
      unawaited(_storage.syncAllLocalDataToSupabase());
      Get.offAll(() => const MainLayoutScreen());
    }
    isLoading.value = false;
  }

  Future<void> register(String name, String email, String password) async {
    errorMessage.value = '';
    final mail = email.trim().toLowerCase();
    if (name.trim().isEmpty || mail.isEmpty || password.isEmpty) {
      errorMessage.value = 'Vui lòng nhập đầy đủ thông tin';
      return;
    }
    if (!GetUtils.isEmail(mail)) {
      errorMessage.value = 'Email không hợp lệ';
      return;
    }
    if (password.length < 6) {
      errorMessage.value = 'Mật khẩu phải từ 6 ký tự';
      return;
    }
    isLoading.value = true;

    // 1. Đăng ký đồng bộ lên Supabase Auth (nếu có mạng)
    if (SupabaseService.isInitialized) {
      try {
        await SupabaseService.client.auth.signUp(
          email: mail,
          password: password,
          data: {'full_name': name.trim()},
        );
      } catch (e) {
        debugPrint('Supabase signUp warning: $e');
      }
    }

    // 2. Lưu tài khoản cục bộ và đăng nhập ngay
    final users = await _storage.loadUsers();
    if (users.any((u) => u.email == mail)) {
      errorMessage.value = 'Email đã được đăng ký';
    } else {
      final user = UserAccount(name: name.trim(), email: mail, password: password);
      users.add(user);
      await _storage.saveUsers(users);
      currentUser.value = user;
      await _storage.setCurrentUserEmail(mail);
      if (Get.isRegistered<CourseController>()) {
        await Get.find<CourseController>().load();
      }
      unawaited(_storage.syncAllLocalDataToSupabase());
      Get.offAll(() => const MainLayoutScreen());
    }
    isLoading.value = false;
  }

  Future<void> logout() async {
    if (SupabaseService.isInitialized) {
      try {
        await SupabaseService.client.auth.signOut();
      } catch (e) {
        debugPrint('Supabase signOut warning: $e');
      }
    }
    await _storage.setCurrentUserEmail(null);
    currentUser.value = null;
    if (Get.isRegistered<CourseController>()) {
      await Get.find<CourseController>().load();
    }
    Get.offAll(() => const LoginScreen());
  }
}
