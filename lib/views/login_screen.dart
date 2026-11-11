import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

/// Mục kịch bản mẫu cho banner phía dưới
class _ScenarioHeroItem {
  final String title;
  final String subtitle;
  final String imagePath;
  final String tag;

  const _ScenarioHeroItem({
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.tag,
  });
}

const List<_ScenarioHeroItem> _kHeroScenarios = [
  _ScenarioHeroItem(
    title: 'At the Coffee Shop',
    subtitle: 'Luyện gọi đồ uống & điều chỉnh đường, đá',
    imagePath: 'assets/images/atthecoffeeshop.jpg',
    tag: '☕ Quán cà phê',
  ),
  _ScenarioHeroItem(
    title: 'Job Interview',
    subtitle: 'Tự tin trả lời phỏng vấn xin việc',
    imagePath: 'assets/images/jobinterview.jpg',
    tag: '💼 Phỏng vấn',
  ),
  _ScenarioHeroItem(
    title: 'Hotel Check-in',
    subtitle: 'Thủ tục nhận phòng & hỏi dịch vụ',
    imagePath: 'assets/images/hotelcheckin.jpg',
    tag: '🏨 Khách sạn',
  ),
  _ScenarioHeroItem(
    title: 'Asking for Directions',
    subtitle: 'Hỏi và chỉ đường tự nhiên như người bản xứ',
    imagePath: 'assets/images/askingfordirection.jpg',
    tag: '🗺️ Hỏi đường',
  ),
  _ScenarioHeroItem(
    title: 'Shopping for Clothes',
    subtitle: 'Thử đồ, chọn size và mua sắm thời trang',
    imagePath: 'assets/images/shoppingforclothes.jpg',
    tag: '🛍️ Mua sắm',
  ),
];

/// Màn hình Đăng nhập & Đăng ký:
/// - Phía trên: Sóng lan màu gradient chuyển động mượt mà
/// - Ở giữa: Khung form Đăng nhập & Đăng ký mở rộng bề ngang, 2 nút tab có khoảng cách nhỏ ở giữa
/// - Phía dưới: Banner kịch bản tự co giãn lấp đầy đáy màn hình (tính toán chiều cao tường minh, không dùng IntrinsicHeight)
class LoginScreen extends StatefulWidget {
  final bool initialRegister;

  const LoginScreen({super.key, this.initialRegister = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final AuthController _auth = Get.find<AuthController>();

  late bool _isRegister;

  @override
  void initState() {
    super.initState();
    _isRegister = widget.initialRegister;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _switchMode(bool register) {
    if (_isRegister == register) return;
    setState(() {
      _isRegister = register;
      _auth.errorMessage.value = '';
    });
  }

  void _submit() {
    if (_isRegister) {
      _auth.register(_nameCtrl.text, _emailCtrl.text, _passCtrl.text);
    } else {
      _auth.login(_emailCtrl.text, _passCtrl.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    const double topHeight = 190.0;
    const double formHeight = 455.0; // Tăng chiều cao để chứa trọn vẹn thông báo lỗi, tránh overflow 17px
    const double gap = 16.0;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Tính toán chiều cao khối dưới chính xác để lấp đầy màn hình mà không gây lỗi vô hạn
          final screenH = constraints.maxHeight;
          final usedH = topHeight + gap + formHeight + gap;
          final bottomH = (screenH - usedH).clamp(140.0, 420.0);

          return SingleChildScrollView(
            child: Column(
              children: [
                // 1. Phía trên: Hiệu ứng sóng lan màu gradient
                _WaveHeader(
                  height: topHeight,
                  title: _isRegister ? 'Tạo tài khoản' : 'Chào mừng trở lại',
                  subtitle: _isRegister
                      ? 'Bắt đầu hành trình nâng tầm tiếng Anh cùng AI'
                      : 'Đăng nhập để tiếp tục luyện phản xạ giao tiếp',
                ),

                const SizedBox(height: gap),

                // 2. Ở giữa: Khung form MỞ RỘNG BỀ NGANG, kích thước đồng nhất
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: _buildEqualSizedAuthCard(scheme, formHeight),
                    ),
                  ),
                ),

                const SizedBox(height: gap),

                // 3. Phía dưới: Khối kịch bản lấp đầy phần đáy màn hình (chiều cao tính toán tường minh)
                _BottomTopicBanner(height: bottomH),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Khung form Đăng nhập & Đăng ký mở rộng bề ngang (Chiều cao cố định)
  Widget _buildEqualSizedAuthCard(ColorScheme scheme, double height) {
    return SizedBox(
      height: height,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md + 2,
        ),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.35),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Thanh gạt chuyển đổi: 2 nút tách dạt ra hai bên, có khoảng trắng nhỏ ở giữa
            _buildModeSwitcher(scheme),

            // Khu vực trường nhập liệu 3 ô cân bằng cho cả 2 chế độ
            SizedBox(
              height: 185,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _isRegister
                    ? Column(
                        key: const ValueKey('register_fields'),
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AppTextField(
                            controller: _nameCtrl,
                            label: 'Họ tên',
                            icon: Icons.person_outline_rounded,
                          ),
                          AppTextField(
                            controller: _emailCtrl,
                            label: 'Email',
                            icon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          AppTextField(
                            controller: _passCtrl,
                            label: 'Mật khẩu (tối thiểu 6 ký tự)',
                            icon: Icons.lock_outline_rounded,
                            isPassword: true,
                          ),
                        ],
                      )
                    : Column(
                        key: const ValueKey('login_fields'),
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          AppTextField(
                            controller: _emailCtrl,
                            label: 'Email',
                            icon: Icons.mail_outline_rounded,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          AppTextField(
                            controller: _passCtrl,
                            label: 'Mật khẩu',
                            icon: Icons.lock_outline_rounded,
                            isPassword: true,
                          ),
                          // Nút đăng nhập Google tượng trưng
                          _buildGoogleSignInButton(scheme),
                        ],
                      ),
              ),
            ),

            // Báo lỗi (nếu có)
            Obx(() {
              if (_auth.errorMessage.value.isEmpty) {
                return const SizedBox(height: 2);
              }
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: scheme.errorContainer.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: scheme.error.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 20,
                      color: scheme.onErrorContainer,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        _auth.errorMessage.value,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: scheme.onErrorContainer,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

            // Nút hành động chính
            Obx(
              () => PrimaryButton(
                label: _isRegister ? 'Đăng ký ngay' : 'Đăng nhập',
                icon: _isRegister
                    ? Icons.person_add_rounded
                    : Icons.login_rounded,
                loading: _auth.isLoading.value,
                onPressed: _submit,
              ),
            ),

            // Dòng chuyển đổi bên dưới
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isRegister ? 'Đã có tài khoản?' : 'Chưa có tài khoản?',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                  TextButton(
                    onPressed: () => _switchMode(!_isRegister),
                    child: Text(
                      _isRegister ? 'Đăng nhập' : 'Đăng ký ngay',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Nút Đăng nhập với Google thông qua Supabase OAuth
  Widget _buildGoogleSignInButton(ColorScheme scheme) {
    return Obx(
      () => OutlinedButton(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.6),
          ),
        ),
        onPressed: _auth.isLoading.value ? null : () => _auth.loginWithGoogle(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo chữ G chuẩn màu Google
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: const Text(
                'G',
                style: TextStyle(
                  color: Color(0xFF4285F4),
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Đăng nhập với Google',
              style: TextStyle(
                color: scheme.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Thanh gạt chọn chế độ: 2 nút tách dạt ra hai bên, có khoảng trắng nhỏ ở giữa
  Widget _buildModeSwitcher(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Nút Đăng nhập dạt sang trái
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _switchMode(false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: !_isRegister ? scheme.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: !_isRegister
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    'Đăng nhập',
                    style: TextStyle(
                      fontWeight:
                          !_isRegister ? FontWeight.bold : FontWeight.normal,
                      color:
                          !_isRegister ? scheme.primary : scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Khoảng trắng nhỏ ở giữa giữa hai nút
          const SizedBox(width: 8),

          // Nút Đăng ký dạt sang phải
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _switchMode(true),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _isRegister ? scheme.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _isRegister
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    'Đăng ký',
                    style: TextStyle(
                      fontWeight:
                          _isRegister ? FontWeight.bold : FontWeight.normal,
                      color:
                          _isRegister ? scheme.primary : scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Banner kịch bản ở phía dưới: chiều cao nhận trực tiếp tường minh, loại bỏ hoàn toàn lỗi vô hạn
class _BottomTopicBanner extends StatefulWidget {
  final double height;

  const _BottomTopicBanner({required this.height});

  @override
  State<_BottomTopicBanner> createState() => _BottomTopicBannerState();
}

class _BottomTopicBannerState extends State<_BottomTopicBanner> {
  int _index = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Tự động chuyển đổi đề tài mượt mà mỗi 4 giây
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) setState(() => _index = (_index + 1) % _kHeroScenarios.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final item = _kHeroScenarios[_index];

    return Container(
      width: double.infinity,
      height: widget.height,
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(36), // Bo cong đối xứng với phần trên
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(36),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Ảnh đề tài chuyển đổi mượt mà
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 700),
              child: Image.asset(
                item.imagePath,
                key: ValueKey(_index),
                fit: BoxFit.cover,
                width: double.infinity,
                height: widget.height,
              ),
            ),

            // Lớp phủ Gradient đen mờ giúp nổi bật văn bản
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.88),
                    Colors.black.withValues(alpha: 0.25),
                  ],
                ),
              ),
            ),

            // Nội dung đề tài hiển thị bên trong banner
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Huy hiệu đề tài & dãy chấm trang
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          item.tag,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Chỉ báo các chấm chuyển đề tài
                      Row(
                        children: List.generate(_kHeroScenarios.length, (i) {
                          final isActive = i == _index;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 2.5),
                            width: isActive ? 18 : 6,
                            height: 5,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),

                  // Tên đề tài & mô tả kịch bản
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Column(
                      key: ValueKey(item.title),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget hiệu ứng sóng lan màu gradient chuyển động ở đầu trang
class _WaveHeader extends StatefulWidget {
  final double height;
  final String title;
  final String subtitle;

  const _WaveHeader({
    required this.height,
    required this.title,
    required this.subtitle,
  });

  @override
  State<_WaveHeader> createState() => _WaveHeaderState();
}

class _WaveHeaderState extends State<_WaveHeader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final val = _ctrl.value;

        return Container(
          width: double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1.0 + val * 0.4, -1.0),
              end: Alignment(1.0 - val * 0.4, 1.0),
              colors: [
                scheme.primary,
                scheme.tertiary,
                const Color(0xFF6366F1),
                const Color(0xFF0EA5E9),
              ],
            ),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(36),
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.25),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.antiAlias,
            children: [
              // Vòng sóng lan màu 1 (trái trên)
              Positioned(
                top: -30 + val * 20,
                left: -20 + val * 30,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.25),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
              // Vòng sóng lan màu 2 (phải dưới)
              Positioned(
                bottom: -40 - val * 15,
                right: -20 - val * 25,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF38BDF8).withValues(alpha: 0.35),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Vòng sóng lan màu 3 (giữa phải)
              Positioned(
                top: 20 + val * 15,
                right: 50 - val * 20,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFA855F7).withValues(alpha: 0.3),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Nội dung logo và lời chào
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.35),
                              ),
                            ),
                            child: const Icon(
                              Icons.record_voice_over_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          const Text(
                            'AI Language Mentor',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Column(
                          key: ValueKey(widget.title),
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.subtitle,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
