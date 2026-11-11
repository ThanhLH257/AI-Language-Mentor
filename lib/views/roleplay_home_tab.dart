import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../controllers/course_controller.dart';
import '../models/course_model.dart';
import '../models/scenario.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'conversation_history_screen.dart';
import 'course_detail_screen.dart';
import 'roleplay_chat_screen.dart';

/// Tab 1: danh sách 7 kịch bản nhập vai + 1 ô sắp ra mắt.
class RoleplayHomeTab extends StatelessWidget {
  const RoleplayHomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthController>();
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    // Tổng số ô = 7 kịch bản + 1 ô sắp ra mắt
    final totalCount = kScenarios.length + 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Lời chào + nút lịch sử
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.sm,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Obx(() {
                      final name = auth.currentUser.value?.name ?? '';
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name.isEmpty ? 'Xin chào!' : 'Xin chào, $name',
                            style: text.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text('Hôm nay luyện gì nào?', style: text.headlineMedium),
                        ],
                      );
                    }),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Lịch sử hội thoại',
                    icon: const Icon(Icons.history_rounded),
                    onPressed: () =>
                        Get.to(() => const ConversationHistoryScreen()),
                  ),
                ],
              ),
            ),
            // Danh sách kịch bản dạng lưới với ảnh nền
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 240,
                  crossAxisSpacing: AppSpacing.md,
                  mainAxisSpacing: AppSpacing.md,
                  mainAxisExtent: 200,
                ),
                itemCount: totalCount,
                itemBuilder: (context, i) {
                  // Ô cuối cùng là "Sắp ra mắt"
                  if (i == kScenarios.length) {
                    return FadeSlideIn(
                      index: i,
                      child: const _ComingSoonTile(),
                    );
                  }

                  return FadeSlideIn(
                    index: i,
                    child: _ScenarioImageTile(scenario: kScenarios[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Thẻ kịch bản sử dụng hình ảnh thực tế làm nền.
class _ScenarioImageTile extends StatelessWidget {
  final Scenario scenario;

  const _ScenarioImageTile({required this.scenario});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Ảnh nền từ thư mục assets/images/
          if (scenario.imagePath != null)
            Image.asset(
              scenario.imagePath!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: const Center(
                  child: Icon(Icons.image_not_supported_outlined, size: 40),
                ),
              ),
            )
          else
            Container(color: Theme.of(context).colorScheme.primaryContainer),

          // 2. Lớp phủ Gradient tối màu để làm nổi bật văn bản
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.1),
                  Colors.black.withValues(alpha: 0.4),
                  Colors.black.withValues(alpha: 0.85),
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),

          // 3. Huy hiệu vai nhân vật ở góc trên
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.person_pin_rounded,
                    color: Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    scenario.aiRole,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. Tiêu đề và mô tả ở góc dưới
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  scenario.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        offset: Offset(0, 1),
                        blurRadius: 3,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  scenario.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // 5. Hiệu ứng chạm InkWell
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _handleScenarioTap(context, scenario),
            ),
          ),
        ],
      ),
    );
  }

  /// Xử lý khi nhấn vào đề tài: kiểm tra đã học khóa học chưa
  void _handleScenarioTap(BuildContext context, Scenario scenario) {
    final courseController = Get.find<CourseController>();
    final isCompleted = courseController.isCompleted(scenario.id);
    final isSnoozed = courseController.isSnoozed(scenario.id);

    // Nếu đã hoàn thành khóa học hoặc đã tick không hiển thị trong 1 ngày -> Vào thẳng hội thoại
    if (isCompleted || isSnoozed) {
      Get.to(() => RoleplayChatScreen(scenario: scenario));
      return;
    }

    // Nếu chưa học: kiểm tra khóa học tương ứng
    final course = courseController.findCourseByScenario(scenario.id);
    if (course == null) {
      Get.to(() => RoleplayChatScreen(scenario: scenario));
      return;
    }

    // Hiển thị hộp thoại gợi ý học khóa học ngắn
    showDialog<void>(
      context: context,
      builder: (dialogCtx) {
        bool dontShowForOneDay = false;

        return StatefulBuilder(
          builder: (context, setState) {
            final scheme = Theme.of(context).colorScheme;
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Text(scenario.emoji, style: const TextStyle(fontSize: 26)),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Chuẩn bị kiến thức',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bạn chưa hoàn thành khóa học ngắn cho đề tài "${scenario.title}".',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Học trước từ vựng và mẫu câu giao tiếp trọng tâm (khoảng ${course.estimatedMinutes} phút) sẽ giúp bạn tự tin giao tiếp và đạt điểm cao hơn với AI!',
                    style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () {
                      setState(() {
                        dontShowForOneDay = !dontShowForOneDay;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Row(
                      children: [
                        Checkbox(
                          value: dontShowForOneDay,
                          onChanged: (val) {
                            setState(() {
                              dontShowForOneDay = val ?? false;
                            });
                          },
                        ),
                        const Expanded(
                          child: Text(
                            'Không hiển thị lại trong 1 ngày',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    if (dontShowForOneDay) {
                      await courseController.snoozeCourse(scenario.id);
                    }
                    Navigator.of(dialogCtx).pop();
                    Get.to(() => RoleplayChatScreen(scenario: scenario));
                  },
                  child: const Text('Vào hội thoại ngay'),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    if (dontShowForOneDay) {
                      await courseController.snoozeCourse(scenario.id);
                    }
                    Navigator.of(dialogCtx).pop();
                    Get.to(
                      () => CourseDetailScreen(
                        course: course,
                        scenario: scenario,
                        openChatOnComplete: true,
                      ),
                    );
                  },
                  icon: const Icon(Icons.school_outlined, size: 18),
                  label: const Text('Học khóa học ngay'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Thẻ "Sắp ra mắt" bổ sung vào danh sách.
class _ComingSoonTile extends StatelessWidget {
  const _ComingSoonTile();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.7),
          style: BorderStyle.solid,
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Nội dung trung tâm
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: scheme.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: scheme.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Sắp ra mắt',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Airport, Doctor, Travel...',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Nhãn "Coming Soon" ở góc trên
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Mới',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: scheme.onPrimaryContainer,
                ),
              ),
            ),
          ),

          // Hiệu ứng tương tác
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                Get.snackbar(
                  'Sắp ra mắt',
                  'Các chủ đề giao tiếp mới (Sân bay, Bác sĩ, Đặt vé) đang được bổ sung!',
                  snackPosition: SnackPosition.BOTTOM,
                  margin: const EdgeInsets.all(16),
                  duration: const Duration(seconds: 2),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
