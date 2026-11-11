import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../controllers/theme_controller.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';

/// Cài đặt: Chế độ tối, màu chủ đạo và đăng xuất.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Get.find<ThemeController>();
    final auth = Get.find<AuthController>();
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    Widget sectionTitle(String t) => Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Text(
            t,
            style: text.labelLarge?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Cài đặt')),
      body: ListView(
        children: [
          sectionTitle('Giao diện & Theme'),
          Obx(
            () => SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
              ),
              secondary: const Icon(Icons.dark_mode_rounded),
              title: const Text('Chế độ tối (Dark Mode)'),
              value: theme.isDark.value,
              onChanged: theme.toggle,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                const Icon(Icons.palette_rounded),
                const SizedBox(width: AppSpacing.md),
                Text('Màu chủ đạo', style: text.bodyLarge),
              ],
            ),
          ),
          // Bảng chọn màu
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Obx(
              () => Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: [
                  for (int i = 0; i < kPalettes.length; i++)
                    _Swatch(
                      palette: kPalettes[i],
                      selected: theme.paletteIndex.value == i,
                      onTap: () => theme.setPalette(i),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Divider(),
          sectionTitle('Giọng đọc AI (Text-to-Speech)'),
          Obx(() {
            if (!Get.isRegistered<TtsService>()) {
              return const SizedBox.shrink();
            }
            final tts = Get.find<TtsService>();
            final preset = tts.currentPreset;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Chọn giọng đọc
                ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  leading: const Icon(Icons.record_voice_over_rounded),
                  title: const Text('Giọng muốn nghe'),
                  subtitle: Text('${preset.flag} ${preset.name}'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showVoicePickerDialog(context, tts),
                ),

                // Tốc độ phát âm
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.speed_rounded, size: 20),
                          const SizedBox(width: AppSpacing.sm),
                          Text('Tốc độ nói', style: text.bodyMedium),
                        ],
                      ),
                      Text(
                        '${(tts.speechRate.value * 2).toStringAsFixed(1)}x (${_getSpeedLabel(tts.speechRate.value)})',
                        style: TextStyle(
                          color: scheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Slider(
                    value: tts.speechRate.value,
                    min: 0.25,
                    max: 0.75,
                    divisions: 10,
                    onChanged: (val) => tts.setSpeechRate(val),
                  ),
                ),

                // Nút nghe thử giọng
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.xs,
                  ),
                  child: Obx(
                    () => OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      icon: Icon(
                        tts.isSpeaking.value
                            ? Icons.stop_rounded
                            : Icons.volume_up_rounded,
                        color: scheme.primary,
                      ),
                      label: Text(
                        tts.isSpeaking.value
                            ? 'Dừng nghe thử'
                            : 'Nghe thử giọng này',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      onPressed: () {
                        if (tts.isSpeaking.value) {
                          tts.stop();
                        } else {
                          tts.testVoice();
                        }
                      },
                    ),
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: AppSpacing.md),
          const Divider(),
          sectionTitle('Tài khoản'),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            leading: Icon(Icons.logout_rounded, color: scheme.error),
            title: Text(
              'Đăng xuất',
              style: TextStyle(
                color: scheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: const Text('Đăng xuất khỏi thiết bị này'),
            onTap: () {
              Get.defaultDialog(
                title: 'Đăng xuất',
                middleText: 'Bạn có chắc chắn muốn đăng xuất?',
                textConfirm: 'Đăng xuất',
                textCancel: 'Hủy',
                confirmTextColor: Colors.white,
                buttonColor: scheme.error,
                onConfirm: () {
                  Get.back();
                  auth.logout();
                },
              );
            },
          ),
        ],
      ),
    );
  }

  static String _getSpeedLabel(double rate) {
    if (rate <= 0.35) return 'Chậm, dễ bắt chước';
    if (rate <= 0.52) return 'Tự nhiên, vừa phải';
    return 'Nhanh, như người bản xứ';
  }

  static void _showVoicePickerDialog(BuildContext context, TtsService tts) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        final text = Theme.of(ctx).textTheme;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chọn giọng muốn nghe',
                  style: text.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Giọng đọc sẽ được áp dụng cho toàn bộ câu thoại AI, gợi ý và từ vựng.',
                  style: text.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: kVoicePresets.length,
                    itemBuilder: (ctx, i) {
                      final p = kVoicePresets[i];
                      return Obx(() {
                        final isSelected = tts.selectedVoiceId.value == p.id;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? scheme.primaryContainer.withValues(alpha: 0.6)
                                : scheme.surfaceContainerHighest.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? scheme.primary
                                  : scheme.outlineVariant.withValues(alpha: 0.3),
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: ListTile(
                            leading: Text(
                              p.flag,
                              style: const TextStyle(fontSize: 26),
                            ),
                            title: Text(
                              p.name,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelected
                                    ? scheme.primary
                                    : scheme.onSurface,
                              ),
                            ),
                            subtitle: Text(
                              '${p.locale} • ${p.engine == "google" ? "Chuẩn Google Chrome" : (p.gender == "Male" ? "Giọng Nam trầm ấm" : "Giọng Nữ thanh lịch")}',
                            ),
                            trailing: isSelected
                                ? Icon(
                                    Icons.check_circle_rounded,
                                    color: scheme.primary,
                                  )
                                : const Icon(Icons.radio_button_unchecked_rounded),
                            onTap: () async {
                              await tts.setVoice(p.id);
                              await tts.testVoice();
                            },
                          ),
                        );
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Ô tròn chọn màu, có dấu tích khi đang chọn.
class _Swatch extends StatelessWidget {
  final AppPalette palette;
  final bool selected;
  final VoidCallback onTap;

  const _Swatch({
    required this.palette,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: 'Màu ${palette.name}',
      child: InkResponse(
        onTap: onTap,
        radius: 32,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: palette.seed,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? scheme.onSurface : Colors.transparent,
              width: 3,
            ),
          ),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: selected ? 1 : 0,
            child: const Icon(Icons.check_rounded, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
