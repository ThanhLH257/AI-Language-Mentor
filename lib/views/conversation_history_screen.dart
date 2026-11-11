import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/history_controller.dart';
import '../models/chat_session.dart';
import '../models/scenario.dart';
import '../theme/app_theme.dart';
import '../theme/scenario_style.dart';
import '../widgets/common_widgets.dart';
import 'roleplay_chat_screen.dart';

/// Danh sách hội thoại cũ; bấm để chat tiếp.
class ConversationHistoryScreen extends StatelessWidget {
  const ConversationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(HistoryController());
    // Nạp lại mỗi lần mở màn hình
    c.load();
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Lịch sử hội thoại')),
      body: Obx(() {
        if (c.isLoading.value && c.sessions.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (c.sessions.isEmpty) {
          return const EmptyState(
            icon: Icons.history_rounded,
            title: 'Chưa có cuộc hội thoại nào',
            message: 'Chọn một kịch bản ở tab Roleplay để bắt đầu luyện nói.',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          itemCount: c.sessions.length,
          itemBuilder: (context, i) {
            final s = c.sessions[i];
            final scenario = _resolveScenario(s);
            final style = ScenarioStyle.of(s.scenarioId);
            final last = s.messages.isEmpty ? '' : s.messages.last.text;

            // Tính điểm sao trung bình của phiên hội thoại (không icon)
            final ratedMsgs =
                s.messages.where((m) => m.isUser && m.rating != null).toList();
            final scoreText = ratedMsgs.isEmpty
                ? ''
                : '${(ratedMsgs.fold<num>(0, (sum, m) => sum + m.rating!) / ratedMsgs.length).toStringAsFixed(1)} / 5.0';

            return FadeSlideIn(
              index: i,
              child: ListTile(
                key: ValueKey(s.id),
                minVerticalPadding: 12,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                ),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: scenario.imagePath != null
                      ? Image.asset(
                          scenario.imagePath!,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: scheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: scheme.primary.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              scenario.emoji,
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        ),
                ),
                title: Text(s.scenarioTitle, style: text.titleMedium),
                subtitle: Text(
                  last,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (scoreText.isNotEmpty)
                      Text(
                        scoreText,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: scheme.primary,
                        ),
                      ),
                    Text(
                      _formatDate(s.updatedAt),
                      style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
                onTap: () => _resume(c, s),
              ),
            );
          },
        );
      }),
    );
  }

  /// Mở lại phiên chat, quay về thì nạp lại danh sách.
  Future<void> _resume(HistoryController c, ChatSession s) async {
    final scenario = _resolveScenario(s);
    await Get.to(() => RoleplayChatScreen(scenario: scenario, session: s));
    c.load();
  }

  /// Khôi phục kịch bản chính xác từ session (kể cả kịch bản Vô hạn / Tùy chỉnh)
  Scenario _resolveScenario(ChatSession s) {
    // 1. Kiểm tra xem có trong 7 kịch bản cố định không
    for (final sc in kScenarios) {
      if (sc.id == s.scenarioId) return sc;
    }

    // 2. Nếu là kịch bản Tùy chỉnh hoặc Free Talk, tái tạo lại đúng kịch bản
    final isFree = s.scenarioId.startsWith('free_talk');
    return Scenario(
      id: s.scenarioId,
      title: s.scenarioTitle,
      aiRole: s.aiRole ?? (isFree ? 'Native Speaking Partner' : 'Speaking Partner'),
      description: s.description ??
          (isFree ? 'Đàm thoại tự do cùng AI Mentor' : 'Kịch bản luyện tập theo yêu cầu'),
      emoji: s.emoji ?? (isFree ? '💬' : '✨'),
      tasks: s.tasks.isNotEmpty
          ? s.tasks
          : (isFree
              ? [
                  'Chia sẻ suy nghĩ hoặc ý kiến cá nhân',
                  'Đặt câu hỏi tương tác với bạn chat',
                  'Duy trì phản xạ hội thoại trôi chảy',
                ]
              : [
                  'Bắt đầu câu chuyện theo tình huống',
                  'Đặt câu hỏi hoặc phản hồi tự nhiên',
                  'Đạt được mục tiêu giao tiếp mong muốn',
                ]),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
}
