import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/tts_service.dart';

/// Nút bấm phát âm thanh Text-To-Speech (TTS)
/// Tự động cập nhật trạng thái khi đang phát âm đoạn văn bản tương ứng.
class SpeakerButton extends StatelessWidget {
  final String text;
  final double iconSize;
  final Color? color;
  final Color? activeColor;
  final String? tooltip;
  final bool compact;
  final EdgeInsetsGeometry? padding;

  const SpeakerButton({
    super.key,
    required this.text,
    this.iconSize = 20,
    this.color,
    this.activeColor,
    this.tooltip = 'Nghe phát âm',
    this.compact = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    if (!Get.isRegistered<TtsService>()) {
      return const SizedBox.shrink();
    }
    final tts = Get.find<TtsService>();
    final scheme = Theme.of(context).colorScheme;

    return Obx(() {
      final isSpeakingThis =
          tts.isSpeaking.value && tts.currentSpeakingText.value == text.trim();

      final normalColor = color ?? scheme.onSurfaceVariant;
      final highlightColor = activeColor ?? scheme.primary;

      if (compact) {
        return IconButton(
          visualDensity: VisualDensity.compact,
          padding: padding ?? EdgeInsets.zero,
          constraints: const BoxConstraints(),
          iconSize: iconSize,
          tooltip: isSpeakingThis ? 'Dừng phát' : tooltip,
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              isSpeakingThis
                  ? Icons.stop_circle_rounded
                  : Icons.volume_up_rounded,
              key: ValueKey(isSpeakingThis),
              color: isSpeakingThis ? highlightColor : normalColor,
            ),
          ),
          onPressed: () {
            if (isSpeakingThis) {
              tts.stop();
            } else {
              tts.speak(text);
            }
          },
        );
      }

      return IconButton(
        iconSize: iconSize,
        padding: padding ?? const EdgeInsets.all(8),
        tooltip: isSpeakingThis ? 'Dừng phát' : tooltip,
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            isSpeakingThis
                ? Icons.stop_circle_rounded
                : Icons.volume_up_rounded,
            key: ValueKey(isSpeakingThis),
            color: isSpeakingThis ? highlightColor : normalColor,
          ),
        ),
        onPressed: () {
          if (isSpeakingThis) {
            tts.stop();
          } else {
            tts.speak(text);
          }
        },
      );
    });
  }
}

