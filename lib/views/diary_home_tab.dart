import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/diary_controller.dart';
import '../models/diary_entry.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/speaker_button.dart';
import 'diary_create_screen.dart';

/// Tab 2: danh sách nhật ký đã chấm.
class DiaryHomeTab extends StatelessWidget {
  const DiaryHomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(DiaryController());
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Nhật ký của bạn')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.to(() => const DiaryCreateScreen()),
        icon: const Icon(Icons.edit_rounded),
        label: const Text('Viết bài'),
      ),
      body: Obx(() {
        if (c.entries.isEmpty) {
          return const EmptyState(
            icon: Icons.menu_book_rounded,
            title: 'Chưa có bài nhật ký',
            message: 'Viết vài câu tiếng Anh mỗi ngày, AI sẽ chấm điểm và sửa giúp bạn.',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 96, top: AppSpacing.xs),
          itemCount: c.entries.length,
          itemBuilder: (context, i) {
            final e = c.entries[i];
            return FadeSlideIn(
              index: i,
              child: ListTile(
                key: ValueKey(e.id),
                minVerticalPadding: 12,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                ),
                leading: ScoreBadge(score: e.score),
                title: Text(
                  e.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.bodyLarge,
                ),
                subtitle: Text(
                  _formatDate(e.createdAt),
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
                trailing: IconButton(
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: scheme.error.withValues(alpha: 0.8),
                  ),
                  tooltip: 'Xóa bài viết',
                  onPressed: () => _confirmDelete(context, c, e),
                ),
                onTap: () => _showDetail(context, c, e),
              ),
            );
          },
        );
      }),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  /// Xác nhận trước khi xóa bài nhật ký
  void _confirmDelete(BuildContext context, DiaryController c, DiaryEntry e) {
    Get.defaultDialog(
      title: 'Xác nhận xóa',
      middleText: 'Bạn có chắc chắn muốn xóa bài nhật ký này không?',
      textConfirm: 'Xóa',
      textCancel: 'Hủy',
      confirmTextColor: Colors.white,
      buttonColor: Theme.of(context).colorScheme.error,
      onConfirm: () async {
        Get.back(); // Đóng dialog
        await c.deleteEntry(e.id);
        Get.snackbar(
          'Đã xóa',
          'Đã xóa bài nhật ký thành công',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      },
    );
  }

  /// Xem chi tiết bài đã chấm.
  void _showDetail(BuildContext context, DiaryController c, DiaryEntry e) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        final text = Theme.of(ctx).textTheme;
        Widget block(
          String title,
          String body, {
          Color? bg,
          bool canSpeak = false,
        }) =>
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: bg ?? scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
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
                      if (canSpeak && body.trim().isNotEmpty)
                        SpeakerButton(
                          text: body,
                          compact: true,
                          iconSize: 18,
                          tooltip: 'Nghe phát âm',
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(body, style: text.bodyLarge),
                ],
              ),
            );
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
              children: [
                Row(
                  children: [
                    ScoreBadge(score: e.score, size: 44),
                    const SizedBox(width: AppSpacing.sm + 4),
                    Text('Điểm ${e.score}/10', style: text.titleLarge),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: scheme.error,
                      ),
                      tooltip: 'Xóa bài này',
                      onPressed: () {
                        Navigator.pop(ctx);
                        _confirmDelete(context, c, e);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                block('Bài gốc', e.content),
                block(
                  'Bản sửa tự nhiên hơn',
                  e.correctedText,
                  bg: scheme.primaryContainer.withValues(alpha: 0.6),
                  canSpeak: true,
                ),
                block('Nhận xét', e.feedback),
              ],
            ),
          ),
        );
      },
    );
  }
}
