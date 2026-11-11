import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/course_controller.dart';
import '../models/course_model.dart';
import '../models/scenario.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/speaker_button.dart';
import 'roleplay_chat_screen.dart';

/// Màn hình học khóa học nhỏ chuẩn bị cho đề tài hội thoại và đánh giá khóa học.
class CourseDetailScreen extends StatefulWidget {
  final CourseModel course;
  final Scenario scenario;
  final bool openChatOnComplete;

  const CourseDetailScreen({
    super.key,
    required this.course,
    required this.scenario,
    this.openChatOnComplete = true,
  });

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  final CourseController _courseController = Get.find<CourseController>();
  final TextEditingController _reviewController = TextEditingController();

  double _selectedRating = 5.0;
  final Map<int, int?> _quizAnswers = {}; // Lưu câu trả lời của từng quiz (index -> selectedOptionIndex)
  bool _isSubmitted = false;

  @override
  void initState() {
    super.initState();
    // Nạp lại đánh giá cũ nếu đã từng học
    final existing = _courseController.getProgress(widget.course.id);
    if (existing != null) {
      _selectedRating = existing.rating;
      _reviewController.text = existing.review;
    }
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  /// Lưu hoàn thành khóa học và đánh giá
  Future<void> _submitCourse() async {
    setState(() => _isSubmitted = true);

    await _courseController.completeCourse(
      courseId: widget.course.id,
      rating: _selectedRating,
      review: _reviewController.text,
    );

    if (!mounted) return;

    Get.snackbar(
      'Thành công',
      'Bạn đã hoàn thành khóa học và lưu đánh giá thành công!',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.withValues(alpha: 0.85),
      colorText: Colors.white,
      margin: const EdgeInsets.all(AppSpacing.md),
      duration: const Duration(seconds: 2),
    );

    if (widget.openChatOnComplete) {
      // Thay thế màn hình khóa học bằng màn hình chat
      Get.off(() => RoleplayChatScreen(scenario: widget.scenario));
    } else {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.course.title),
        actions: [
          if (widget.openChatOnComplete)
            TextButton(
              onPressed: () {
                Get.off(() => RoleplayChatScreen(scenario: widget.scenario));
              },
              child: const Text('Vào chat ngay'),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Banner giới thiệu khóa học
              _buildCourseHeader(scheme, text),
              const SizedBox(height: AppSpacing.lg),

              // 2. Phần Từ vựng trọng tâm
              _buildSectionHeader(
                icon: Icons.menu_book_rounded,
                title: 'Từ vựng & Cụm từ quan trọng',
                count: '${widget.course.vocabularies.length} từ',
              ),
              const SizedBox(height: AppSpacing.sm),
              ...widget.course.vocabularies.map((v) => _buildVocabCard(v, scheme, text)),
              const SizedBox(height: AppSpacing.lg),

              // 3. Mẫu câu đối đáp mẫu
              if (widget.course.sampleDialogues.isNotEmpty) ...[
                _buildSectionHeader(
                  icon: Icons.chat_outlined,
                  title: 'Hội thoại mẫu tham khảo',
                  count: '${widget.course.sampleDialogues.length} câu',
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildDialogueSection(scheme, text),
                const SizedBox(height: AppSpacing.lg),
              ],

              // 4. Mẹo giao tiếp thực tế
              if (widget.course.conversationTips.isNotEmpty) ...[
                _buildSectionHeader(
                  icon: Icons.lightbulb_outline_rounded,
                  title: 'Mẹo giao tiếp thực tế',
                  count: null,
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildTipsCard(scheme, text),
                const SizedBox(height: AppSpacing.lg),
              ],

              // 5. Bài tập trắc nghiệm nhanh
              if (widget.course.quizzes.isNotEmpty) ...[
                _buildSectionHeader(
                  icon: Icons.quiz_outlined,
                  title: 'Luyện tập trắc nghiệm ngắn',
                  count: '${widget.course.quizzes.length} câu',
                ),
                const SizedBox(height: AppSpacing.sm),
                ...widget.course.quizzes.asMap().entries.map(
                      (entry) => _buildQuizCard(entry.key, entry.value, scheme, text),
                    ),
                const SizedBox(height: AppSpacing.lg),
              ],

              // 6. Đánh giá khóa học
              _buildRatingSection(scheme, text),
              const SizedBox(height: AppSpacing.xl),

              // 7. Nút hoàn thành
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitted ? null : _submitCourse,
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(
                    widget.openChatOnComplete
                        ? 'Hoàn thành & Bắt đầu Hội Thoại Ngay'
                        : 'Lưu Đánh Giá & Hoàn Thành',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  /// Banner thông tin khóa học
  Widget _buildCourseHeader(ColorScheme scheme, TextTheme text) {
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  widget.scenario.emoji,
                  style: const TextStyle(fontSize: 28),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.course.title,
                      style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Chip(
                          label: Text(widget.course.level),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          labelStyle: const TextStyle(fontSize: 11),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.schedule, size: 14, color: scheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.course.estimatedMinutes} phút',
                          style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            widget.course.description,
            style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  /// Tiêu đề từng mục
  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    String? count,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: scheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        if (count != null) ...[
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: scheme.primary,
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Thẻ từ vựng có nút phát âm TTS
  Widget _buildVocabCard(CourseVocab vocab, ColorScheme scheme, TextTheme text) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vocab.word,
                        style: text.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: scheme.primary,
                        ),
                      ),
                      if (vocab.phonetic.isNotEmpty)
                        Text(
                          vocab.phonetic,
                          style: text.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                    ],
                  ),
                ),
                SpeakerButton(text: vocab.word, tooltip: 'Nghe từ vựng'),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              vocab.meaning,
              style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Ví dụ: "${vocab.exampleSentence}"',
                      style: text.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                    ),
                  ),
                  SpeakerButton(
                    text: vocab.exampleSentence,
                    compact: true,
                    iconSize: 18,
                    tooltip: 'Nghe ví dụ',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Danh sách câu đối đáp mẫu
  Widget _buildDialogueSection(ColorScheme scheme, TextTheme text) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: widget.course.sampleDialogues.asMap().entries.map((entry) {
            final index = entry.key;
            final d = entry.value;
            final isUser = d.speaker.toLowerCase() == 'you';

            return Column(
              children: [
                if (index > 0) const Divider(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: isUser
                            ? scheme.primary.withValues(alpha: 0.15)
                            : scheme.secondary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        d.speaker,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isUser ? scheme.primary : scheme.secondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d.text,
                            style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            d.translation,
                            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    SpeakerButton(text: d.text, compact: true, iconSize: 18),
                  ],
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Thẻ mẹo giao tiếp
  Widget _buildTipsCard(ColorScheme scheme, TextTheme text) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: widget.course.conversationTips.map((tip) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💡 ', style: TextStyle(fontSize: 16)),
                  Expanded(
                    child: Text(
                      tip,
                      style: text.bodyMedium?.copyWith(height: 1.3),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Thẻ bài tập trắc nghiệm ngắn
  Widget _buildQuizCard(
    int quizIndex,
    CourseQuizQuestion quiz,
    ColorScheme scheme,
    TextTheme text,
  ) {
    final selectedOption = _quizAnswers[quizIndex];
    final hasAnswered = selectedOption != null;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Câu ${quizIndex + 1}: ${quiz.question}',
              style: text.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...quiz.options.asMap().entries.map((optionEntry) {
              final optIndex = optionEntry.key;
              final optText = optionEntry.value;

              Color? bgColor;
              Color? borderColor;
              if (hasAnswered) {
                if (optIndex == quiz.correctIndex) {
                  bgColor = Colors.green.withValues(alpha: 0.15);
                  borderColor = Colors.green;
                } else if (selectedOption == optIndex) {
                  bgColor = Colors.red.withValues(alpha: 0.15);
                  borderColor = Colors.red;
                }
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _quizAnswers[quizIndex] = optIndex;
                    });
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: bgColor ?? scheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: borderColor ??
                            (selectedOption == optIndex
                                ? scheme.primary
                                : scheme.outlineVariant.withValues(alpha: 0.4)),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          String.fromCharCode(65 + optIndex), // A, B, C, D
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: hasAnswered && optIndex == quiz.correctIndex
                                ? Colors.green
                                : scheme.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            optText,
                            style: text.bodyMedium,
                          ),
                        ),
                        if (hasAnswered && optIndex == quiz.correctIndex)
                          const Icon(Icons.check_circle, color: Colors.green, size: 18),
                        if (hasAnswered &&
                            selectedOption == optIndex &&
                            optIndex != quiz.correctIndex)
                          const Icon(Icons.cancel, color: Colors.red, size: 18),
                      ],
                    ),
                  ),
                ),
              );
            }),
            if (hasAnswered && quiz.explanation.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        quiz.explanation,
                        style: text.bodySmall?.copyWith(color: Colors.blue[800]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Phần đánh giá số sao và nhận xét khóa học
  Widget _buildRatingSection(ColorScheme scheme, TextTheme text) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star_rounded, color: Colors.amber, size: 24),
              const SizedBox(width: 8),
              Text(
                'Đánh giá khóa học này',
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Mỗi lần học hãy cho biết độ hữu ích của kiến thức bài học đối với bạn:',
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.sm),

          // 5 ngôi sao tương tác
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starValue = index + 1.0;
              final isFilled = starValue <= _selectedRating;
              return IconButton(
                onPressed: () {
                  setState(() {
                    _selectedRating = starValue;
                  });
                },
                icon: Icon(
                  isFilled ? Icons.star_rounded : Icons.star_border_rounded,
                  color: Colors.amber,
                  size: 34,
                ),
              );
            }),
          ),
          Center(
            child: Text(
              '${_selectedRating.toInt()} / 5 sao (${_getRatingLabel(_selectedRating)})',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: scheme.primary,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Nhận xét
          TextField(
            controller: _reviewController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Nhận xét của bạn (không bắt buộc)',
              hintText: 'Ví dụ: Bài học rất dễ hiểu, từ vựng rất thực tế...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: scheme.surface,
            ),
          ),
        ],
      ),
    );
  }

  String _getRatingLabel(double rating) {
    if (rating >= 5) return 'Rất hữu ích';
    if (rating >= 4) return 'Hữu ích';
    if (rating >= 3) return 'Bình thường';
    if (rating >= 2) return 'Cần cải thiện';
    return 'Chưa hài lòng';
  }
}
