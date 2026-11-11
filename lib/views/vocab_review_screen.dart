import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/vocab_controller.dart';
import '../models/practice_sentence.dart';
import '../models/vocabulary.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/speaker_button.dart';

/// Màn hình ôn tập từ vựng: lật thẻ flashcard và luyện đặt câu cùng AI.
class VocabReviewScreen extends StatefulWidget {
  const VocabReviewScreen({super.key});

  @override
  State<VocabReviewScreen> createState() => _VocabReviewScreenState();
}

class _VocabReviewScreenState extends State<VocabReviewScreen> {
  final VocabController _c = Get.find<VocabController>();
  final _sentenceCtrl = TextEditingController();

  int _mode = 0; // 0: Lật thẻ, 1: Luyện đặt câu
  int _index = 0; // Vị trí từ đang xem
  bool _flipped = false; // Thẻ đang lật hay chưa

  @override
  void initState() {
    super.initState();
    _c.resetCheck();
    _c.load(); // Nạp lại dữ liệu đảm bảo đồng bộ
  }

  @override
  void dispose() {
    _sentenceCtrl.dispose();
    super.dispose();
  }

  /// Chuyển sang từ khác và reset trạng thái.
  void _goTo(int index, int total) {
    if (total == 0) return;
    setState(() {
      _index = (index % total + total) % total; // Xoay vòng an toàn
      _flipped = false;
    });
    _sentenceCtrl.clear();
    _c.resetCheck();
  }

  void _setMode(int mode) {
    setState(() {
      _mode = mode;
      _flipped = false;
    });
    _sentenceCtrl.clear();
    _c.resetCheck();
  }

  /// Hộp thoại xác nhận trước khi xóa từ vựng
  void _confirmDeleteVocab(Vocabulary vocab, int index) {
    Get.defaultDialog(
      title: 'Xác nhận xóa',
      middleText: 'Bạn có chắc muốn xóa từ "${vocab.word}" khỏi sổ tay không?',
      textConfirm: 'Xóa',
      textCancel: 'Hủy',
      confirmTextColor: Colors.white,
      buttonColor: Theme.of(context).colorScheme.error,
      onConfirm: () async {
        Get.back();
        await _c.removeVocab(vocab.id);
        if (_c.vocabList.isNotEmpty) {
          _goTo(index, _c.vocabList.length);
        }
        Get.snackbar(
          'Đã xóa',
          'Đã xóa từ "${vocab.word}" khỏi sổ tay',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sổ tay từ vựng'),
        actions: [
          // Nút xem câu đã lưu trên góc phải, chuyển màn hình trượt ngang
          IconButton(
            tooltip: 'Câu đã lưu',
            icon: const Icon(Icons.history_edu_rounded),
            onPressed: () => Get.to(
              () => const SavedSentencesScreen(),
              transition: Transition.rightToLeftWithFade,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Thanh chuyển chế độ: Lật thẻ & Luyện đặt câu
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.xs,
              ),
              child: _buildModeChips(),
            ),
            const Divider(),

            // Nội dung theo chế độ (được bọc trong 1 Obx an toàn)
            Expanded(
              child: Obx(() {
                final vocabList = _c.vocabList.toList();

                if (vocabList.isEmpty) {
                  return const EmptyState(
                    icon: Icons.bookmark_border_rounded,
                    title: 'Sổ tay đang trống',
                    message:
                        'Trong lúc Roleplay, bấm "Xem cách sửa" rồi "Lưu từ vựng" để thêm từ vào đây.',
                  );
                }

                final safeIndex = _index.clamp(0, vocabList.length - 1);
                final vocab = vocabList[safeIndex];

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCounter(safeIndex, vocabList.length, vocab),
                      const SizedBox(height: AppSpacing.md),
                      if (_mode == 0)
                        _buildFlashcard(vocab, safeIndex, vocabList)
                      else
                        _buildPractice(vocab, safeIndex, vocabList.length),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  /// 2 chip chọn chế độ ôn tập: Lật thẻ & Luyện đặt câu.
  Widget _buildModeChips() {
    return Obx(() {
      final vocabCount = _c.vocabList.length;

      return Row(
        children: [
          Expanded(
            child: ChoiceChip(
              avatar: const Icon(Icons.style_rounded, size: 18),
              label: Text('Lật thẻ ($vocabCount)'),
              selected: _mode == 0,
              onSelected: (_) => _setMode(0),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: ChoiceChip(
              avatar: const Icon(Icons.edit_rounded, size: 18),
              label: const Text('Luyện đặt câu'),
              selected: _mode == 1,
              onSelected: (_) => _setMode(1),
            ),
          ),
        ],
      );
    });
  }

  /// Hiển thị chỉ số "Từ x / y" và nút xóa từ có xác nhận.
  Widget _buildCounter(int index, int total, Vocabulary vocab) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text(
          'Từ ${index + 1} / $total',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
        ),
        const Spacer(),
        IconButton(
          tooltip: 'Xóa từ này khỏi sổ tay',
          icon: Icon(
            Icons.delete_outline_rounded,
            color: scheme.error.withValues(alpha: 0.8),
          ),
          onPressed: () => _confirmDeleteVocab(vocab, index),
        ),
      ],
    );
  }

  // ---------------- CHẾ ĐỘ 1: LẬT THẺ (FLASHCARD) ----------------

  Widget _buildFlashcard(
    Vocabulary vocab,
    int index,
    List<Vocabulary> vocabList,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final total = vocabList.length;

    // Mặt trước: Chỉ có từ vựng, phiên âm, điểm sao, TUYỆT ĐỐI KHÔNG có nghĩa
    final front = Column(
      key: const ValueKey('front'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        StarRating(
          rating: vocab.averageRating,
          size: 26,
          showEmptyMuted: true,
        ),
        const SizedBox(height: 6),
        Text(
          vocab.practiceCount == 0
              ? 'Chưa luyện tập (0 sao)'
              : 'Độ thành thạo (${vocab.practiceCount} câu)',
          style: text.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          children: [
            Text(
              vocab.word,
              textAlign: TextAlign.center,
              style: text.headlineMedium?.copyWith(
                fontSize: 34,
                fontWeight: FontWeight.bold,
              ),
            ),
            SpeakerButton(
              text: vocab.word,
              iconSize: 26,
              tooltip: 'Nghe phát âm từ "${vocab.word}"',
            ),
          ],
        ),
        if (vocab.displayPhonetic.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: scheme.primary.withValues(alpha: 0.25),
              ),
            ),
            child: Text(
              vocab.displayPhonetic,
              textAlign: TextAlign.center,
              style: text.titleMedium?.copyWith(
                color: scheme.primary,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        Text(
          'Chạm vào thẻ để xem nghĩa & ví dụ',
          style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
      ],
    );

    // Mặt sau: Mới hiển thị nghĩa tiếng Việt, câu ví dụ và ngữ cảnh
    final back = Column(
      key: const ValueKey('back'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Từ vựng và phiên âm nhắc lại ở đầu mặt sau
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          children: [
            Text(
              vocab.word,
              style: text.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: scheme.onSurfaceVariant,
              ),
            ),
            if (vocab.displayPhonetic.isNotEmpty)
              Text(
                vocab.displayPhonetic,
                style: text.bodyMedium?.copyWith(
                  color: scheme.primary,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          vocab.meaning,
          textAlign: TextAlign.center,
          style: text.titleLarge?.copyWith(
            color: scheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (vocab.example.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    vocab.example,
                    textAlign: TextAlign.center,
                    style: text.bodyLarge?.copyWith(fontStyle: FontStyle.italic),
                  ),
                ),
                SpeakerButton(
                  text: vocab.example,
                  compact: true,
                  iconSize: 20,
                  tooltip: 'Nghe ví dụ',
                ),
              ],
            ),
          ),
        ],
        if (vocab.displayUsage.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              vocab.displayUsage,
              textAlign: TextAlign.center,
              style: text.bodySmall?.copyWith(color: scheme.primary),
            ),
          ),
        ],
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Thẻ lật Flashcard
        GestureDetector(
          onTap: () => setState(() => _flipped = !_flipped),
          child: Card(
            margin: EdgeInsets.zero,
            color: _flipped
                ? scheme.primaryContainer.withValues(alpha: 0.6)
                : scheme.surfaceContainerHighest,
            child: Container(
              width: double.infinity,
              height: 280,
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _flipped ? back : front,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Các nút điều hướng và chuyển sang luyện câu
        Row(
          children: [
            IconButton.filledTonal(
              tooltip: 'Từ trước',
              iconSize: 26,
              icon: const Icon(Icons.chevron_left_rounded),
              onPressed: () => _goTo(index - 1, total),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _setMode(1),
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: const Text('Luyện câu với từ này'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            IconButton.filled(
              tooltip: 'Từ tiếp theo',
              iconSize: 26,
              icon: const Icon(Icons.chevron_right_rounded),
              onPressed: () => _goTo(index + 1, total),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.lg),
        const Divider(),
        const SizedBox(height: AppSpacing.xs),

        // Danh sách bấm nhanh toàn bộ từ vựng ở khoảng trống bên dưới
        // RÀNG BUỘC: CHỈ HIỂN THỊ TỪ TIẾNG ANH & PHIÊN ÂM, KHÔNG HIỆN NGHĨA!
        Text(
          'Danh sách từ bấm nhanh ($total)',
          style: text.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        _buildQuickSelectList(vocabList, index),
      ],
    );
  }

  /// Danh sách bấm nhanh: CHỈ HIỆN TỪ TIẾNG ANH VÀ PHIÊN ÂM (KHÔNG HIỆN NGHĨA)
  Widget _buildQuickSelectList(List<Vocabulary> list, int selectedIndex) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      separatorBuilder: (_, _) => const SizedBox(height: 6),
      itemBuilder: (context, i) {
        final item = list[i];
        final isSelected = i == selectedIndex;

        return InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _goTo(i, list.length),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? scheme.primaryContainer.withValues(alpha: 0.7)
                  : scheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? scheme.primary
                    : scheme.outlineVariant.withValues(alpha: 0.3),
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                // Icon chỉ báo từ đang chọn
                Icon(
                  isSelected
                      ? Icons.play_arrow_rounded
                      : Icons.circle_outlined,
                  size: 18,
                  color: isSelected ? scheme.primary : scheme.outline,
                ),
                const SizedBox(width: AppSpacing.sm),

                // Từ tiếng Anh & phiên âm (dùng Wrap chống tràn giao diện)
                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 2,
                    children: [
                      Text(
                        item.word,
                        style: text.titleMedium?.copyWith(
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected
                              ? scheme.primary
                              : scheme.onSurface,
                        ),
                      ),
                      if (item.displayPhonetic.isNotEmpty)
                        Text(
                          item.displayPhonetic,
                          style: text.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? scheme.primary
                                : scheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),

                // Đánh giá sao thành thạo
                StarRating(
                  rating: item.averageRating,
                  size: 13,
                  showEmptyMuted: true,
                ),
                const SizedBox(width: 4),

                // Nút nghe phát âm nhanh
                SpeakerButton(
                  text: item.word,
                  compact: true,
                  iconSize: 18,
                  tooltip: 'Nghe từ "${item.word}"',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------- CHẾ ĐỘ 2: LUYỆN ĐẶT CÂU VỚI AI ----------------

  Widget _buildPractice(Vocabulary vocab, int index, int total) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Thẻ từ mục tiêu
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: scheme.primaryContainer.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Từ mục tiêu',
                    style: text.labelLarge?.copyWith(
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  StarRating(
                    rating: vocab.averageRating,
                    size: 15,
                    showEmptyMuted: true,
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Đổi từ khác',
                    icon: const Icon(Icons.skip_next_rounded, size: 20),
                    onPressed: () => _goTo(index + 1, total),
                  ),
                ],
              ),
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text(
                    vocab.word,
                    style: text.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                  SpeakerButton(
                    text: vocab.word,
                    compact: true,
                    iconSize: 20,
                    color: scheme.onPrimaryContainer,
                    activeColor: scheme.primary,
                    tooltip: 'Nghe phát âm từ "${vocab.word}"',
                  ),
                  if (vocab.displayPhonetic.isNotEmpty)
                    Text(
                      vocab.displayPhonetic,
                      style: text.titleSmall?.copyWith(
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w600,
                        color: scheme.onPrimaryContainer.withValues(alpha: 0.9),
                      ),
                    ),
                ],
              ),
              Text(
                vocab.meaning,
                style: text.bodyMedium?.copyWith(
                  color: scheme.onPrimaryContainer,
                ),
              ),
              if (vocab.displayUsage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    vocab.displayUsage,
                    style: text.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: scheme.onPrimaryContainer.withValues(alpha: 0.8),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Ô nhập liệu
        AppTextField(
          controller: _sentenceCtrl,
          label: 'Câu của bạn (tiếng Anh)',
          hint: 'Viết một câu chứa "${vocab.word}"...',
          maxLines: 3,
        ),
        const SizedBox(height: AppSpacing.md),

        // Nút gửi kiểm tra
        Obx(
          () => PrimaryButton(
            label: 'Kiểm tra bằng AI',
            icon: Icons.auto_awesome_rounded,
            loading: _c.isChecking.value,
            onPressed: () => _c.checkSentence(vocab, _sentenceCtrl.text),
          ),
        ),

        // Thông báo lỗi (nếu có)
        Obx(
          () => _c.errorMessage.value.isEmpty
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: ErrorBanner(message: _c.errorMessage.value),
                ),
        ),

        // Kết quả AI đánh giá
        Obx(
          () => AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildCheckResult(vocab, index, total),
          ),
        ),
      ],
    );
  }

  /// Hiển thị kết quả AI đánh giá câu
  Widget _buildCheckResult(Vocabulary vocab, int index, int total) {
    final r = _c.checkResult.value;
    if (r == null) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    const okColor = Color(0xFF16A34A);
    final color = r.isCorrect ? okColor : scheme.error;
    final originalSentence = _sentenceCtrl.text.trim();

    Widget block(String title, String body, {bool canSpeak = false}) {
      if (body.trim().isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: text.labelLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (canSpeak)
                  SpeakerButton(
                    text: body,
                    compact: true,
                    iconSize: 18,
                    tooltip: 'Nghe phát âm',
                  ),
              ],
            ),
            const SizedBox(height: 2),
            Text(body, style: text.bodyLarge),
          ],
        ),
      );
    }

    return Padding(
      key: const ValueKey('check_result'),
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Đánh giá sao của AI cho câu vừa viết
            Row(
              children: [
                StarRating(rating: r.rating, size: 24),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  r.isCorrect ? 'Chuẩn ngữ pháp!' : 'Cần cải thiện',
                  style: text.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Độ thành thạo của từ "${vocab.word}" đã được cập nhật!',
              style: text.bodySmall?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),

            block('Bản sửa tự nhiên hơn', r.correctedSentence, canSpeak: true),
            block('Nhận xét từ AI', r.feedback),
            block('Ngữ cảnh sử dụng câu này', r.sentenceUsage),

            const SizedBox(height: AppSpacing.md),
            const Divider(),

            // Nút "Lưu câu vào sổ tay"
            Obx(() {
              final saved = _c.isSentenceSaved(originalSentence);
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        saved ? scheme.surfaceContainer : scheme.primary,
                    foregroundColor:
                        saved ? scheme.onSurface : scheme.onPrimary,
                  ),
                  onPressed: saved
                      ? null
                      : () async {
                          final practice = PracticeSentence(
                            id: DateTime.now().microsecondsSinceEpoch.toString(),
                            vocabWord: vocab.word,
                            originalSentence: originalSentence,
                            correctedSentence: r.correctedSentence,
                            rating: r.rating,
                            isCorrect: r.isCorrect,
                            feedback: r.feedback,
                            sentenceUsage: r.sentenceUsage,
                            createdAt: DateTime.now(),
                          );
                          await _c.addPracticeSentence(practice);
                          Get.snackbar(
                            'Đã lưu câu',
                            'Câu đã được thêm vào mục câu đã lưu',
                            snackPosition: SnackPosition.BOTTOM,
                          );
                        },
                  icon: Icon(
                    saved
                        ? Icons.bookmark_added_rounded
                        : Icons.bookmark_add_rounded,
                  ),
                  label: Text(
                    saved ? 'Câu này đã được lưu' : 'Lưu câu vào sổ tay',
                  ),
                ),
              );
            }),

            // Gợi ý từ vựng liên quan (kèm nút lưu từ)
            if (r.recommendedVocab.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                'Từ vựng hữu ích từ câu này:',
                style: text.labelLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              for (final v in r.recommendedVocab) _buildVocabSnippet(v),
            ],

            const SizedBox(height: AppSpacing.md),
            // Nút chuyển tiếp và nút xem câu đã lưu
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _goTo(index + 1, total),
                    icon: const Icon(Icons.skip_next_rounded),
                    label: const Text('Từ tiếp theo'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                IconButton.filledTonal(
                  tooltip: 'Xem câu đã lưu',
                  icon: const Icon(Icons.history_edu_rounded),
                  onPressed: () => Get.to(
                    () => const SavedSentencesScreen(),
                    transition: Transition.rightToLeftWithFade,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Khối từ vựng gợi ý kèm nút lưu từ
  Widget _buildVocabSnippet(Vocabulary vocab) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  children: [
                    Text(
                      vocab.word,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SpeakerButton(
                      text: vocab.word,
                      compact: true,
                      iconSize: 16,
                      tooltip: 'Nghe phát âm',
                    ),
                    if (vocab.displayPhonetic.isNotEmpty)
                      Text(
                        vocab.displayPhonetic,
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w600,
                          color: scheme.primary,
                        ),
                      ),
                  ],
                ),
                Text(
                  vocab.meaning,
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Obx(() {
            final saved = _c.isSaved(vocab.word);
            return TextButton.icon(
              onPressed: saved
                  ? null
                  : () async {
                      await _c.addVocab(vocab);
                      Get.snackbar(
                        'Đã lưu từ',
                        '"${vocab.word}" đã được thêm vào sổ tay từ vựng',
                        snackPosition: SnackPosition.BOTTOM,
                      );
                    },
              icon: Icon(
                saved ? Icons.check_rounded : Icons.bookmark_add_outlined,
                size: 16,
              ),
              label: Text(saved ? 'Đã lưu' : 'Lưu từ'),
            );
          }),
        ],
      ),
    );
  }
}

/// Màn hình danh sách câu đã luyện & lưu lại (chuyển qua bằng hiệu ứng trượt ngang).
class SavedSentencesScreen extends StatelessWidget {
  const SavedSentencesScreen({super.key});

  /// Hộp thoại xác nhận trước khi xóa câu đã lưu
  void _confirmDeleteSentence(
    BuildContext context,
    VocabController c,
    PracticeSentence s,
  ) {
    Get.defaultDialog(
      title: 'Xác nhận xóa câu',
      middleText: 'Bạn có chắc chắn muốn xóa câu này khỏi danh sách đã lưu không?',
      textConfirm: 'Xóa',
      textCancel: 'Hủy',
      confirmTextColor: Colors.white,
      buttonColor: Theme.of(context).colorScheme.error,
      onConfirm: () async {
        Get.back();
        await c.removePracticeSentence(s.id);
        Get.snackbar(
          'Đã xóa',
          'Đã xóa câu khỏi sổ tay',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      },
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final c = Get.find<VocabController>();
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Câu đã lưu'),
      ),
      body: Obx(() {
        final list = c.practiceSentences.toList();
        if (list.isEmpty) {
          return const EmptyState(
            icon: Icons.history_edu_rounded,
            title: 'Chưa có câu nào được lưu',
            message:
                'Hãy sang chế độ "Luyện đặt câu", viết câu và bấm "Lưu câu vào sổ tay" để xem lại tại đây.',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: list.length,
          itemBuilder: (context, i) {
            final s = list[i];
            const okColor = Color(0xFF16A34A);
            final statusColor = s.isCorrect ? okColor : scheme.error;

            return Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.primaryContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            s.vocabWord,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: scheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        StarRating(rating: s.rating, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          s.isCorrect ? 'Chuẩn' : 'Đã sửa',
                          style: TextStyle(
                            fontSize: 12,
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          tooltip: 'Xóa câu này',
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: scheme.error.withValues(alpha: 0.8),
                          ),
                          onPressed: () =>
                              _confirmDeleteSentence(context, c, s),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Text(
                          'Câu của bạn:',
                          style: text.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        SpeakerButton(
                          text: s.originalSentence,
                          compact: true,
                          iconSize: 16,
                          tooltip: 'Nghe câu của bạn',
                        ),
                      ],
                    ),
                    Text(s.originalSentence, style: text.bodyMedium),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          'Bản sửa tự nhiên hơn:',
                          style: text.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        SpeakerButton(
                          text: s.correctedSentence,
                          compact: true,
                          iconSize: 16,
                          tooltip: 'Nghe bản sửa tự nhiên',
                        ),
                      ],
                    ),
                    Text(
                      s.correctedSentence,
                      style: text.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: scheme.primary,
                      ),
                    ),
                    if (s.displayUsage.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        s.displayUsage,
                        style: text.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      _formatDate(s.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
