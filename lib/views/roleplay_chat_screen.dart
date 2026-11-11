import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/roleplay_controller.dart';
import '../controllers/vocab_controller.dart';
import '../models/chat_message.dart';
import '../models/chat_session.dart';
import '../models/scenario.dart';
import '../models/vocabulary.dart';
import '../theme/app_theme.dart';
import '../theme/scenario_style.dart';
import '../widgets/common_widgets.dart';
import '../widgets/speaker_button.dart';

/// Phòng chat với AI. Hỗ trợ chat mới hoặc tiếp tục đoạn cũ ([session]).
class RoleplayChatScreen extends StatefulWidget {
  final Scenario scenario;
  final ChatSession? session;

  const RoleplayChatScreen({super.key, required this.scenario, this.session});

  @override
  State<RoleplayChatScreen> createState() => _RoleplayChatScreenState();
}

class _RoleplayChatScreenState extends State<RoleplayChatScreen> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  late final RoleplayController _c;
  late final String _tag;
  bool _tasksOpen = true; // Bảng nhiệm vụ đang mở hay thu gọn

  @override
  void initState() {
    super.initState();
    // Tag riêng để mỗi phòng chat có controller độc lập
    _tag = DateTime.now().microsecondsSinceEpoch.toString();
    _c = Get.put(
      RoleplayController(
        scenario: widget.scenario,
        resumeSession: widget.session,
      ),
      tag: _tag,
    );
    // Tự cuộn xuống cuối khi có tin nhắn mới hoặc AI đang gõ
    ever(_c.messages, (_) => _scrollToBottom());
    ever(_c.isLoading, (_) => _scrollToBottom());
    // Đoạn chat cũ thì thu gọn nhiệm vụ cho rộng chỗ
    _tasksOpen = widget.session == null;
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    Get.delete<RoleplayController>(tag: _tag);
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send() {
    final text = _inputCtrl.text;
    if (text.trim().isEmpty) return;
    _inputCtrl.clear();
    _c.sendMessage(text);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = ScenarioStyle.of(widget.scenario.id);
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: widget.scenario.imagePath != null
                  ? Image.asset(
                      widget.scenario.imagePath!,
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: style.color.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(style.icon, size: 20, color: style.color),
                    ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.scenario.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    widget.scenario.aiRole,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Hiển thị số điểm sao trung bình của hội thoại ở góc trên bên phải (không cần icon)
          Obx(() {
            final ratedMsgs =
                _c.messages.where((m) => m.isUser && m.rating != null).toList();
            if (ratedMsgs.isEmpty) {
              return const SizedBox.shrink();
            }
            final total = ratedMsgs.fold<num>(0, (sum, m) => sum + m.rating!);
            final avg = (total / ratedMsgs.length).toStringAsFixed(1);
            return Center(
              child: Container(
                margin: const EdgeInsets.only(right: AppSpacing.md),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  '$avg / 5.0',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildTasks(),
            Expanded(child: _buildMessages()),
            Obx(
              () => _c.errorMessage.value.isEmpty
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.sm,
                        AppSpacing.md,
                        0,
                      ),
                      child: ErrorBanner(
                        message: _c.errorMessage.value,
                        onRetry: _c.retry,
                      ),
                    ),
            ),
            _buildInput(),
          ],
        ),
      ),
    );
  }

  /// Bảng nhiệm vụ: thu gọn / mở rộng mượt, tick khi AI xác nhận hoàn thành.
  Widget _buildTasks() {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Obx(() {
      final tasks = _c.activeTasks.toList();
      final done = _c.completedTasks.toList();
      final allDone = tasks.isNotEmpty && done.length >= tasks.length;
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: scheme.secondaryContainer.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => setState(() => _tasksOpen = !_tasksOpen),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Icon(
                      allDone ? Icons.emoji_events_rounded : Icons.flag_rounded,
                      size: 20,
                      color: scheme.onSecondaryContainer,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        allDone
                            ? 'Hoàn thành mục tiêu! 🎉'
                            : 'Mục tiêu: ${done.length}/${tasks.length}',
                        style: text.titleMedium?.copyWith(
                          color: scheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _tasksOpen ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.expand_more_rounded,
                        color: scheme.onSecondaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              alignment: Alignment.topCenter,
              child: _tasksOpen
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        0,
                        AppSpacing.md,
                        12,
                      ),
                      child: Column(
                        children: [
                          for (final task in tasks)
                            _buildTaskRow(task, done.contains(task)),
                        ],
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      );
    });
  }

  /// Một dòng nhiệm vụ: icon tick khi xong, chữ gạch ngang.
  Widget _buildTaskRow(String task, bool isDone) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: Icon(
              isDone
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              key: ValueKey(isDone),
              size: 22,
              color: isDone
                  ? const Color(0xFF16A34A)
                  : scheme.onSecondaryContainer,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              task,
              style: text.bodyMedium?.copyWith(
                color: scheme.onSecondaryContainer,
                decoration: isDone ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessages() {
    return Obx(() {
      final loading = _c.isLoading.value;
      if (_c.messages.isEmpty && !loading) {
        return EmptyState(
          icon: Icons.waving_hand_rounded,
          title: 'Bắt đầu cuộc trò chuyện',
          message:
              'Hãy chào ${widget.scenario.aiRole} bằng tiếng Anh để bắt đầu nhé!',
        );
      }
      final count = _c.messages.length + (loading ? 1 : 0);
      return ListView.builder(
        controller: _scrollCtrl,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        itemCount: count,
        itemBuilder: (context, i) {
          // Mục cuối khi đang tải là bong bóng "AI đang gõ"
          if (i >= _c.messages.length) return const TypingBubble();
          final m = _c.messages[i];
          return FadeSlideIn(
            key: ValueKey('${m.time.microsecondsSinceEpoch}_${m.role}'),
            child: _buildBubble(m),
          );
        },
      );
    });
  }

  /// Bóng thoại của user (kèm sao) hoặc AI.
  Widget _buildBubble(ChatMessage m) {
    final scheme = Theme.of(context).colorScheme;
    final isUser = m.isUser;
    final maxWidth = MediaQuery.of(context).size.width * 0.78;

    // Góc bo bất đối xứng: góc gần người nói nhọn hơn
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: Radius.circular(isUser ? 18 : 4),
      bottomRight: Radius.circular(isUser ? 4 : 18),
    );

    return Column(
      crossAxisAlignment:
          isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: AppSpacing.xs),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          constraints: BoxConstraints(maxWidth: maxWidth),
          decoration: BoxDecoration(
            color: isUser ? scheme.primary : scheme.surfaceContainerHighest,
            borderRadius: radius,
          ),
          child: Text(
            m.text,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: isUser ? scheme.onPrimary : scheme.onSurface,
                ),
          ),
        ),
        // Nút nghe câu thoại của AI
        if (!isUser)
          Padding(
            padding: const EdgeInsets.only(top: 2, left: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SpeakerButton(
                  text: m.text,
                  iconSize: 18,
                  compact: true,
                  tooltip: 'Nghe AI nói',
                ),
                Text(
                  'Nghe AI nói',
                  style: TextStyle(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        // Sao + nút xem cách sửa nằm dưới bóng thoại user
        if (isUser && m.rating != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                StarRating(rating: m.rating!),
                const SizedBox(width: AppSpacing.xs),
                TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: const Size(48, 44), // vùng chạm >= 44px
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: () => _showSuggestion(m),
                  child: const Text('Xem cách sửa'),
                ),
              ],
            ),
          ),
        // Nhắc nhở khi user trả lời lạc đề
        if (isUser && m.onTopic == false)
          Container(
            constraints: BoxConstraints(maxWidth: maxWidth),
            margin: const EdgeInsets.only(bottom: AppSpacing.xs),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: scheme.tertiaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.report_problem_rounded,
                  size: 18,
                  color: scheme.onTertiaryContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    (m.offTopicNote ?? '').isEmpty
                        ? 'Câu trả lời của bạn chưa đúng chủ đề đang nói.'
                        : m.offTopicNote!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onTertiaryContainer,
                        ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.xs),
      ],
    );
  }

  /// BottomSheet hiển thị câu sửa + giải thích.
  void _showSuggestion(ChatMessage m) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        final text = Theme.of(ctx).textTheme;
        Widget section(
          IconData icon,
          String title,
          String body,
          Color color, {
          bool canSpeak = false,
        }) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: AppSpacing.sm + 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: text.labelLarge?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          if (canSpeak && body.trim().isNotEmpty) ...[
                            const SizedBox(width: 6),
                            SpeakerButton(
                              text: body,
                              compact: true,
                              iconSize: 18,
                              tooltip: 'Nghe phát âm',
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(body.isEmpty ? '—' : body, style: text.bodyLarge),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text('Nhận xét câu của bạn', style: text.titleLarge),
                    const Spacer(),
                    if (m.rating != null) StarRating(rating: m.rating!),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                section(
                  Icons.chat_bubble_outline_rounded,
                  'Câu của bạn',
                  m.text,
                  scheme.onSurfaceVariant,
                ),
                section(
                  Icons.check_circle_rounded,
                  'Gợi ý tự nhiên hơn',
                  m.suggestion ?? '',
                  scheme.primary,
                  canSpeak: true,
                ),
                section(
                  Icons.lightbulb_rounded,
                  'Giải thích',
                  m.explanation ?? '',
                  kStarColor,
                ),
                // Từ vựng gợi ý + nút lưu vào sổ tay
                if (m.recommendedVocab.isNotEmpty) ...[
                  const Divider(),
                  const SizedBox(height: AppSpacing.md),
                  Text('Từ vựng gợi ý', style: text.titleMedium),
                  const SizedBox(height: AppSpacing.sm),
                  for (final v in m.recommendedVocab)
                    _VocabSuggestionRow(vocab: v),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInput() {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _inputCtrl,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(
                hintText: 'Nhập tiếng Anh...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide(color: scheme.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Obx(
            () => IconButton.filled(
              tooltip: 'Gửi',
              iconSize: 24,
              style: IconButton.styleFrom(minimumSize: const Size(52, 52)),
              icon: const Icon(Icons.arrow_upward_rounded),
              onPressed: _c.isLoading.value ? null : _send,
            ),
          ),
        ],
      ),
    );
  }
}

/// Một dòng từ vựng gợi ý trong BottomSheet, có nút "Lưu từ vựng".
class _VocabSuggestionRow extends StatelessWidget {
  final Vocabulary vocab;

  const _VocabSuggestionRow({required this.vocab});

  @override
  Widget build(BuildContext context) {
    final vocabCtrl = Get.find<VocabController>();
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  children: [
                    Text(vocab.word, style: text.titleMedium),
                    SpeakerButton(
                      text: vocab.word,
                      compact: true,
                      iconSize: 18,
                      tooltip: 'Nghe phát âm từ "${vocab.word}"',
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
                Text(vocab.meaning, style: text.bodyLarge),
                if (vocab.example.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            vocab.example,
                            style: text.bodyMedium?.copyWith(
                              fontStyle: FontStyle.italic,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        SpeakerButton(
                          text: vocab.example,
                          compact: true,
                          iconSize: 16,
                          tooltip: 'Nghe ví dụ',
                        ),
                      ],
                    ),
                  ),
                if (vocab.displayUsage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      vocab.displayUsage,
                      style: text.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Đổi trạng thái nút ngay khi lưu
          Obx(() {
            final saved = vocabCtrl.isSaved(vocab.word);
            return TextButton.icon(
              style: TextButton.styleFrom(minimumSize: const Size(48, 44)),
              onPressed: saved
                  ? null
                  : () async {
                      await vocabCtrl.addVocab(vocab);
                      Get.snackbar(
                        'Đã lưu',
                        '"${vocab.word}" đã được thêm vào sổ tay',
                      );
                    },
              icon: Icon(
                saved ? Icons.check_rounded : Icons.bookmark_add_outlined,
                size: 20,
              ),
              label: Text(saved ? 'Đã lưu' : 'Lưu từ vựng'),
            );
          }),
        ],
      ),
    );
  }
}
