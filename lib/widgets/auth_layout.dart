import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme/app_theme.dart';

/// Khung dùng chung cho Đăng nhập / Đăng ký:
/// - Phía trên: Hiệu ứng sóng lan màu (Gradient Wave) chuyển động mượt mà
/// - Ở giữa: Thẻ form căn giữa (Login & Register cùng kích thước chuẩn xác)
/// - Phía dưới: Banner kịch bản đổi ảnh mượt mà bằng AnimatedSwitcher
class AuthLayout extends StatefulWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final bool showBack;

  const AuthLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.showBack = false,
  });

  @override
  State<AuthLayout> createState() => _AuthLayoutState();
}

class _AuthLayoutState extends State<AuthLayout>
    with SingleTickerProviderStateMixin {
  static const List<String> _images = [
    'assets/images/atthecoffeeshop.jpg',
    'assets/images/jobinterview.jpg',
    'assets/images/hotelcheckin.jpg',
    'assets/images/askingfordirection.jpg',
    'assets/images/shoppingforclothes.jpg',
  ];

  static const List<String> _titles = [
    'At the Coffee Shop',
    'Job Interview',
    'Hotel Check-in',
    'Asking for Directions',
    'Shopping for Clothes',
  ];

  static const List<String> _tags = [
    '☕ Quán cà phê',
    '💼 Phỏng vấn',
    '🏨 Khách sạn',
    '🗺️ Hỏi đường',
    '🛍️ Mua sắm',
  ];

  int _index = 0;
  Timer? _timer;
  late final AnimationController _waveCtrl;

  @override
  void initState() {
    super.initState();
    // Đổi ảnh đề tài mượt mà mỗi 4 giây
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted) setState(() => _index = (_index + 1) % _images.length);
    });

    // Chuyển động sóng lan màu ở phía trên
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _waveCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Phía trên: Hiệu ứng sóng lan màu gradient
            _buildWaveHeader(scheme),

            const SizedBox(height: AppSpacing.lg),

            // 2. Ở giữa: Khung form Đăng nhập / Đăng ký CÙNG KÍCH THƯỚC
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: widget.child,
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // 3. Phía dưới: Ảnh kịch bản chuyển đổi mượt mà bằng AnimatedSwitcher
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: _buildBottomHeroImage(scheme),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Hiệu ứng sóng lan màu chuyển động ở phía trên
  Widget _buildWaveHeader(ColorScheme scheme) {
    return AnimatedBuilder(
      animation: _waveCtrl,
      builder: (context, _) {
        final val = _waveCtrl.value;

        return Container(
          width: double.infinity,
          height: 195,
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

              // Logo, nút quay lại & tiêu đề
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
                          if (widget.showBack) ...[
                            IconButton(
                              onPressed: () => Get.back(),
                              icon: const Icon(Icons.arrow_back_rounded),
                              color: Colors.white,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                          ],
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

  /// Banner kịch bản ở phía dưới đổi ảnh mượt mà bằng AnimatedSwitcher
  Widget _buildBottomHeroImage(ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              Icon(Icons.auto_awesome_rounded, size: 16, color: scheme.primary),
              const SizedBox(width: 6),
              Text(
                'Kịch bản luyện giao tiếp thực tế',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: 160,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Hiệu ứng đổi ảnh mượt mà chính xác bằng AnimatedSwitcher
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 700),
                  child: Image.asset(
                    _images[_index],
                    key: ValueKey(_index),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 160,
                  ),
                ),
                // Lớp phủ Gradient đen mờ
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.15),
                        Colors.black.withValues(alpha: 0.82),
                      ],
                    ),
                  ),
                ),
                // Tag chủ đề phía trên
                Positioned(
                  top: 10,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Text(
                      _tags[_index],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // Tiêu đề kịch bản phía dưới
                Positioned(
                  bottom: 12,
                  left: 14,
                  right: 14,
                  child: Text(
                    _titles[_index],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

