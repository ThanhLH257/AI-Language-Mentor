import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/diary_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/speaker_button.dart';

/// Soạn nhật ký, gửi AI chấm điểm và lưu.
class DiaryCreateScreen extends StatefulWidget {
  const DiaryCreateScreen({super.key});

  @override
  State<DiaryCreateScreen> createState() => _DiaryCreateScreenState();
}

class _DiaryCreateScreenState extends State<DiaryCreateScreen> {
  final _textCtrl = TextEditingController();
  final DiaryController _c = Get.find<DiaryController>();
  final _wordCount = 0.obs; // Bộ đếm từ

  @override
  void initState() {
    super.initState();
    _c.resetDraft();
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    // Sửa nội dung thì phải chấm lại
    _c.result.value = null;
    _wordCount.value =
        value.trim().isEmpty ? 0 : value.trim().split(RegExp(r'\s+')).length;
  }

  Future<void> _save() async {
    final ok = await _c.save(_textCtrl.text);
    if (ok) {
      Get.back();
      Get.snackbar('Đã lưu', 'Bài nhật ký đã được lưu');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Viết nhật ký')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hôm nay của bạn thế nào?',
                style: text.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Viết vài câu bằng tiếng Anh, AI sẽ chấm điểm và gợi ý bản tự nhiên hơn.',
                style: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                controller: _textCtrl,
                label: 'Nhật ký tiếng Anh',
                hint: 'Today I...',
                maxLines: 8,
                onChanged: _onChanged,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs, right: 4),
                  child: Obx(
                    () => Text(
                      '${_wordCount.value} từ',
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Obx(
                () => PrimaryButton(
                  label: 'Gửi AI chấm điểm',
                  icon: Icons.auto_awesome_rounded,
                  loading: _c.isLoading.value,
                  onPressed: () => _c.evaluate(_textCtrl.text),
                ),
              ),
              Obx(
                () => _c.errorMessage.value.isEmpty
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.md),
                        child: ErrorBanner(
                          message: _c.errorMessage.value,
                          onRetry: () => _c.evaluate(_textCtrl.text),
                        ),
                      ),
              ),
              // Kết quả xuất hiện mượt
              Obx(
                () => AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildResult(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Khối kết quả chấm điểm.
  Widget _buildResult() {
    final r = _c.result.value;
    if (r == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      key: const ValueKey('result'),
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ScoreBadge(score: r.score, size: 56),
              const SizedBox(width: AppSpacing.md),
              Text('Điểm ${r.score}/10', style: text.titleLarge),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Bản sửa tự nhiên hơn',
                      style: text.labelLarge?.copyWith(
                        color: scheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SpeakerButton(
                      text: r.correctedText,
                      compact: true,
                      iconSize: 20,
                      color: scheme.onPrimaryContainer,
                      activeColor: scheme.primary,
                      tooltip: 'Nghe đọc bản sửa tự nhiên',
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  r.correctedText,
                  style: text.bodyLarge?.copyWith(
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Nhận xét',
            style: text.labelLarge?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(r.feedback, style: text.bodyLarge),
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.bookmark_add_rounded),
            label: const Text('Lưu bài'),
          ),
        ],
      ),
    );
  }
}
