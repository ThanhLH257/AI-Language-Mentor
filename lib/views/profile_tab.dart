import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../controllers/course_controller.dart';
import '../controllers/diary_controller.dart';
import '../controllers/history_controller.dart';
import '../controllers/vocab_controller.dart';
import '../models/course_model.dart';
import '../models/scenario.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import 'course_detail_screen.dart';
import 'settings_screen.dart';

/// Tab 4: Hồ sơ cá nhân và bảng biểu đồ thống kê học tập.
class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final AuthController _auth = Get.find<AuthController>();
  final DiaryController _diary = Get.put(DiaryController());
  final HistoryController _history = Get.put(HistoryController());
  final VocabController _vocab = Get.find<VocabController>();
  final CourseController _course = Get.find<CourseController>();
  bool _isCoursesExpanded = false; // Trạng thái mở rộng / thu gọn danh sách khóa học

  @override
  void initState() {
    super.initState();
    // Nạp lại để số liệu thống kê luôn được làm mới
    _history.load();
    _diary.load();
    _vocab.load();
    _course.load();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ học tập'),
        actions: [
          IconButton(
            tooltip: 'Cài đặt',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Get.to(
              () => const SettingsScreen(),
              transition: Transition.rightToLeftWithFade,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            // 1. Header: Avatar chữ cái đầu + Tên + Email
            Obx(() {
              final u = _auth.currentUser.value;
              final name = u?.name ?? '';
              final initial = name.isEmpty ? '?' : name[0].toUpperCase();
              return FadeSlideIn(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 42,
                      backgroundColor: scheme.primary,
                      child: Text(
                        initial,
                        style: text.headlineMedium?.copyWith(
                          color: scheme.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      name,
                      style: text.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      u?.email ?? '',
                      style: text.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: AppSpacing.lg),

            // 2. Thẻ Đánh giá năng lực tích lũy tổng thể (được ưu tiên lên đầu)
            Obx(() => _buildOverallRatingCard()),
            const SizedBox(height: AppSpacing.lg),

            // 3. Mục Khóa học theo chủ đề của người dùng (nhấn vào để sổ danh sách bài xuống)
            _buildCourseSection(scheme, text),
            const SizedBox(height: AppSpacing.lg),

            // 3. Thống kê 4 chỉ số chính dạng Grid 2x2
            Obx(() {
              final chatCount = _history.sessions.length;
              final diaryCount = _diary.entries.length;
              final vocabCount = _vocab.vocabList.length;
              final sentenceCount = _vocab.practiceSentences.length;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tổng quan tiến độ',
                    style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      _statCard(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: 'Hội thoại',
                        value: '$chatCount',
                        color: const Color(0xFF2563EB),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _statCard(
                        icon: Icons.menu_book_rounded,
                        label: 'Bài nhật ký',
                        value: '$diaryCount',
                        color: const Color(0xFF0D9488),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      _statCard(
                        icon: Icons.bookmarks_outlined,
                        label: 'Từ vựng lưu',
                        value: '$vocabCount',
                        color: const Color(0xFFEA580C),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      _statCard(
                        icon: Icons.edit_note_rounded,
                        label: 'Câu đã luyện',
                        value: '$sentenceCount',
                        color: const Color(0xFF7C3AED),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // 3. Biểu đồ phân bố hoạt động học tập
                  _buildActivityChart(
                    chatCount: chatCount,
                    diaryCount: diaryCount,
                    vocabCount: vocabCount,
                    sentenceCount: sentenceCount,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // 4. Bảng đánh giá kỹ năng học tập
                  _buildSkillProgress(
                    chatCount: chatCount,
                    diaryCount: diaryCount,
                    vocabCount: vocabCount,
                    sentenceCount: sentenceCount,
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  /// Thẻ hiển thị một chỉ số học tập
  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: color.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: color),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Biểu đồ thanh phân bố các hoạt động học tập (sử dụng widgets cơ bản)
  Widget _buildActivityChart({
    required int chatCount,
    required int diaryCount,
    required int vocabCount,
    required int sentenceCount,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final total = chatCount + diaryCount + vocabCount + sentenceCount;

    final chatRatio = total > 0 ? (chatCount / total) : 0.25;
    final diaryRatio = total > 0 ? (diaryCount / total) : 0.25;
    final vocabRatio = total > 0 ? (vocabCount / total) : 0.25;
    final sentenceRatio = total > 0 ? (sentenceCount / total) : 0.25;

    const chatColor = Color(0xFF2563EB);
    const diaryColor = Color(0xFF0D9488);
    const vocabColor = Color(0xFFEA580C);
    const sentenceColor = Color(0xFF7C3AED);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Phân bố hoạt động',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              Text(
                'Tổng: $total mục',
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Thanh biểu đồ tỷ lệ dải màu
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 14,
              child: Row(
                children: [
                  if (chatRatio > 0)
                    Expanded(
                      flex: (chatRatio * 100).toInt().clamp(1, 100),
                      child: Container(color: chatColor),
                    ),
                  if (diaryRatio > 0)
                    Expanded(
                      flex: (diaryRatio * 100).toInt().clamp(1, 100),
                      child: Container(color: diaryColor),
                    ),
                  if (vocabRatio > 0)
                    Expanded(
                      flex: (vocabRatio * 100).toInt().clamp(1, 100),
                      child: Container(color: vocabColor),
                    ),
                  if (sentenceRatio > 0)
                    Expanded(
                      flex: (sentenceRatio * 100).toInt().clamp(1, 100),
                      child: Container(color: sentenceColor),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // Chú thích các màu
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _legendItem('Hội thoại', chatColor, '${(chatRatio * 100).toStringAsFixed(0)}%'),
              _legendItem('Nhật ký', diaryColor, '${(diaryRatio * 100).toStringAsFixed(0)}%'),
              _legendItem('Từ vựng', vocabColor, '${(vocabRatio * 100).toStringAsFixed(0)}%'),
              _legendItem('Câu luyện', sentenceColor, '${(sentenceRatio * 100).toStringAsFixed(0)}%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem(String label, Color color, String percent) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          '$label $percent',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  /// Bảng thanh tiến độ phát triển 4 kỹ năng
  Widget _buildSkillProgress({
    required int chatCount,
    required int diaryCount,
    required int vocabCount,
    required int sentenceCount,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chỉ số kỹ năng ngoại ngữ',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.md),
          _skillRow(
            title: 'Kỹ năng Phản xạ & Giao tiếp',
            current: chatCount,
            target: 10,
            unit: 'phiên',
            color: const Color(0xFF2563EB),
          ),
          const SizedBox(height: 12),
          _skillRow(
            title: 'Kỹ năng Diễn đạt & Viết lách',
            current: diaryCount,
            target: 10,
            unit: 'bài',
            color: const Color(0xFF0D9488),
          ),
          const SizedBox(height: 12),
          _skillRow(
            title: 'Vốn từ vựng tích lũy',
            current: vocabCount,
            target: 30,
            unit: 'từ',
            color: const Color(0xFFEA580C),
          ),
          const SizedBox(height: 12),
          _skillRow(
            title: 'Khả năng Ứng dụng ngữ pháp',
            current: sentenceCount,
            target: 15,
            unit: 'câu',
            color: const Color(0xFF7C3AED),
          ),
        ],
      ),
    );
  }

  /// Mục Khóa học theo chủ đề: Cho phép mở / thu gọn (sổ xuống khi bấm) và chống tràn pixel
  Widget _buildCourseSection(ColorScheme scheme, TextTheme text) {
    return Obx(() {
      final courses = _course.courses;
      final completedCount = _course.completedCount;
      final totalCount = _course.totalCount;
      final progressFraction = totalCount > 0 ? completedCount / totalCount : 0.0;

      return Container(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Bấm vào để sổ danh sách bài học xuống hoặc thu gọn lại
            InkWell(
              onTap: () {
                setState(() {
                  _isCoursesExpanded = !_isCoursesExpanded;
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: scheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.school_rounded, color: scheme.primary, size: 22),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Khóa học theo chủ đề',
                                style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Đã hoàn thành $completedCount / $totalCount khóa học',
                                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: completedCount > 0
                                ? Colors.green.withValues(alpha: 0.15)
                                : scheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${(progressFraction * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: completedCount > 0 ? Colors.green[700] : scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          _isCoursesExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: scheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progressFraction,
                        minHeight: 6,
                        backgroundColor: scheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: Text(
                        _isCoursesExpanded
                            ? '▲ Nhấn để thu gọn danh sách'
                            : '▼ Nhấn để xem & học bài ($totalCount bài)',
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Danh sách bài học (chỉ hiển thị khi người dùng nhấn mở rộng)
            if (_isCoursesExpanded) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  children: courses.map((course) {
                    final progress = _course.getProgress(course.id);
                    final isCompleted = progress?.isCompleted ?? false;
                    final scenario = kScenarios.firstWhereOrNull((s) => s.id == course.scenarioId);

                    return Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? Colors.green.withValues(alpha: 0.04)
                            : scheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isCompleted
                              ? Colors.green.withValues(alpha: 0.3)
                              : scheme.outlineVariant.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: isCompleted
                                ? Colors.green.withValues(alpha: 0.15)
                                : scheme.primary.withValues(alpha: 0.1),
                            child: Text(
                              scenario?.emoji ?? '📚',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  course.title,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 6,
                                  children: [
                                    Text(
                                      '${course.level} • ${course.estimatedMinutes}p',
                                      style: text.bodySmall?.copyWith(fontSize: 11, color: scheme.onSurfaceVariant),
                                    ),
                                    if (isCompleted) ...[
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.check_circle, size: 12, color: Colors.green),
                                          const SizedBox(width: 2),
                                          const Icon(Icons.star_rounded, size: 13, color: Colors.amber),
                                          Text(
                                            (progress?.rating ?? 5.0).toStringAsFixed(1),
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ] else
                                      Text(
                                        'Chưa học',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: scheme.onSurfaceVariant,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                  ],
                                ),
                                if (isCompleted && progress?.review.isNotEmpty == true) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    '"${progress!.review}"',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: text.bodySmall?.copyWith(
                                      fontSize: 11,
                                      fontStyle: FontStyle.italic,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              minimumSize: const Size(60, 32),
                              backgroundColor:
                                  isCompleted ? scheme.secondaryContainer : scheme.primary,
                              foregroundColor:
                                  isCompleted ? scheme.onSecondaryContainer : scheme.onPrimary,
                            ),
                            onPressed: () {
                              if (scenario != null) {
                                Get.to(() => CourseDetailScreen(
                                      course: course,
                                      scenario: scenario,
                                      openChatOnComplete: false,
                                    ));
                              }
                            },
                            child: Text(
                              isCompleted ? 'Học lại' : 'Học ngay',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }

  /// Thẻ Đánh giá năng lực tổng quát bằng Icon Sao (bọc Wrap chống tràn pixel)
  Widget _buildOverallRatingCard() {
    final scheme = Theme.of(context).colorScheme;
    final rating = _calculateOverallRating();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: kStarColor.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kStarColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.stars_rounded, color: kStarColor, size: 28),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Đánh giá năng lực tích lũy',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    StarRating(rating: rating, size: 18, showEmptyMuted: true),
                    Text(
                      rating == 0 ? 'Chưa đánh giá' : '${rating.toStringAsFixed(1)} / 5.0',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: kStarColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Tính trung bình cộng số sao tích lũy từ Hội thoại, Nhật ký và Luyện câu
  double _calculateOverallRating() {
    double totalSum = 0;
    int count = 0;

    // 1. Sao từ tin nhắn hội thoại Roleplay
    for (final s in _history.sessions) {
      for (final m in s.messages) {
        if (m.isUser && m.rating != null) {
          totalSum += m.rating!;
          count++;
        }
      }
    }

    // 2. Sao từ bài nhật ký (quy đổi thang 10 sang 5 sao: score / 2)
    for (final d in _diary.entries) {
      totalSum += (d.score / 2.0).clamp(1.0, 5.0);
      count++;
    }

    // 3. Sao từ các câu luyện từ vựng
    for (final p in _vocab.practiceSentences) {
      totalSum += p.rating.clamp(1, 5);
      count++;
    }

    if (count == 0) return 0.0;
    return double.parse((totalSum / count).toStringAsFixed(1));
  }

  Widget _skillRow({
    required String title,
    required int current,
    required int target,
    required String unit,
    required Color color,
  }) {
    final percent = (current / target).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            Text(
              '$current/$target $unit',
              style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 7,
            backgroundColor: color.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
