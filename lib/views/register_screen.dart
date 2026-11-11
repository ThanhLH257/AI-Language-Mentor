import 'package:flutter/material.dart';

import 'login_screen.dart';

/// Màn hình đăng ký: mở trực tiếp LoginScreen ở chế độ đăng ký với trải nghiệm chuyển tab mượt mà.
class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const LoginScreen(initialRegister: true);
  }
}
