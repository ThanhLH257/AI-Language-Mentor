import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Cấu hình các bộ giọng tiếng Anh
class VoicePreset {
  final String id;
  final String name;
  final String flag;
  final String locale;
  final String gender; // 'Male' | 'Female' | 'Neutral'
  final String engine; // 'google' | 'device'
  final double defaultPitch;

  const VoicePreset({
    required this.id,
    required this.name,
    required this.flag,
    required this.locale,
    required this.gender,
    required this.engine,
    this.defaultPitch = 1.0,
  });
}

const List<VoicePreset> kVoicePresets = [
  // 1. Giọng Google Chrome Mỹ (Chất lượng cao, tự nhiên như trên trình duyệt)
  VoicePreset(
    id: 'google_us',
    name: 'Mỹ - Nữ',
    flag: '🇺🇸',
    locale: 'en-US',
    gender: 'Female',
    engine: 'google',
    defaultPitch: 1.0,
  ),
  // 2. Giọng Nam Mỹ (Trầm ấm bản xứ)
  VoicePreset(
    id: 'device_us_male',
    name: 'Mỹ - Nam',
    flag: '🇺🇸',
    locale: 'en-US',
    gender: 'Male',
    engine: 'device',
    defaultPitch: 0.78,
  ),
  // 3. Giọng Google Chrome Anh - Anh
  VoicePreset(
    id: 'google_gb',
    name: 'Anh - Anh - Nữ',
    flag: '🇬🇧',
    locale: 'en-GB',
    gender: 'Female',
    engine: 'google',
    defaultPitch: 1.0,
  ),
  // 4. Giọng Nam Anh - Anh
  VoicePreset(
    id: 'device_gb_male',
    name: 'Anh - Anh - Nam',
    flag: '🇬🇧',
    locale: 'en-GB',
    gender: 'Male',
    engine: 'device',
    defaultPitch: 0.78,
  ),
];

/// Service quản lý Text-to-Speech (TTS) toàn ứng dụng:
/// Hỗ trợ cả giọng Google Chrome chất lượng cao và bộ giọng Nam/Nữ hệ thống.
class TtsService extends GetxService {
  static const String _voiceKey = 'tts_voice_preset_id';
  static const String _rateKey = 'tts_speech_rate';
  static const String _pitchKey = 'tts_pitch';

  late final FlutterTts _tts;
  late final AudioPlayer _player;

  final RxBool isSpeaking = false.obs;
  final RxString currentSpeakingText = ''.obs;

  final RxString selectedVoiceId = 'google_us'.obs;
  final RxDouble speechRate = 0.5.obs; // Tốc độ chuẩn 1.0x
  final RxDouble pitch = 1.0.obs;

  List<dynamic> deviceVoices = [];

  VoicePreset get currentPreset {
    return kVoicePresets.firstWhere(
      (p) => p.id == selectedVoiceId.value,
      orElse: () => kVoicePresets.first,
    );
  }

  Future<TtsService> init() async {
    _tts = FlutterTts();
    _player = AudioPlayer();

    // Lắng nghe trạng thái AudioPlayer (Google Voice)
    _player.onPlayerStateChanged.listen((state) {
      if (state == PlayerState.playing) {
        isSpeaking.value = true;
      } else if (state == PlayerState.completed || state == PlayerState.stopped) {
        isSpeaking.value = false;
        currentSpeakingText.value = '';
      }
    });

    // Lắng nghe trạng thái FlutterTts (Device Voice)
    _tts.setStartHandler(() {
      isSpeaking.value = true;
    });

    _tts.setCompletionHandler(() {
      isSpeaking.value = false;
      currentSpeakingText.value = '';
    });

    _tts.setCancelHandler(() {
      isSpeaking.value = false;
      currentSpeakingText.value = '';
    });

    _tts.setErrorHandler((msg) {
      debugPrint('TTS Device Error: $msg');
      isSpeaking.value = false;
      currentSpeakingText.value = '';
    });

    // Nạp cấu hình đã lưu
    final prefs = await SharedPreferences.getInstance();
    final savedVoice = prefs.getString(_voiceKey);
    if (savedVoice != null && kVoicePresets.any((p) => p.id == savedVoice)) {
      selectedVoiceId.value = savedVoice;
    }
    final savedRate = prefs.getDouble(_rateKey);
    if (savedRate != null) {
      speechRate.value = savedRate.clamp(0.25, 0.75);
    }
    final savedPitch = prefs.getDouble(_pitchKey);
    if (savedPitch != null) {
      pitch.value = savedPitch.clamp(0.7, 1.4);
    }

    try {
      deviceVoices = await _tts.getVoices;
    } catch (_) {}

    return this;
  }

  /// Phát âm văn bản
  Future<void> speak(String text) async {
    final clean = text.trim();
    if (clean.isEmpty) return;

    // Bấm lại câu đang đọc thì dừng phát
    if (isSpeaking.value && currentSpeakingText.value == clean) {
      await stop();
      return;
    }

    await stop();
    currentSpeakingText.value = clean;
    isSpeaking.value = true;

    final preset = currentPreset;

    if (preset.engine == 'google') {
      final played = await _speakGoogle(clean, preset);
      if (played) return;
      // Nếu không có mạng hoặc lỗi tải Google Voice, tự động fallback sang giọng máy
      debugPrint('Google TTS fallback to device TTS');
    }

    await _speakDevice(clean, preset);
  }

  /// Phát âm thanh qua Google Chrome Neural/Translate Audio (kèm cache đĩa)
  Future<bool> _speakGoogle(String text, VoicePreset preset) async {
    try {
      final hash = md5.convert(utf8.encode('${preset.locale}:$text')).toString();
      final cacheDir = await getTemporaryDirectory();
      final cacheFile = File('${cacheDir.path}/tts_cache_$hash.mp3');

      if (!await cacheFile.exists()) {
        final url = Uri.parse(
          'https://translate.google.com/translate_tts?ie=UTF-8&client=tw-ob&tl=${preset.locale}&q=${Uri.encodeComponent(text)}',
        );
        final response = await http.get(
          url,
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36',
          },
        ).timeout(const Duration(seconds: 6));

        if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
          await cacheFile.writeAsBytes(response.bodyBytes);
        } else {
          return false;
        }
      }

      // Tốc độ phát lại (0.5 là chuẩn 1.0x)
      final rateRatio = (speechRate.value * 2.0).clamp(0.5, 1.5);
      await _player.setPlaybackRate(rateRatio);
      await _player.play(DeviceFileSource(cacheFile.path));
      return true;
    } catch (e) {
      debugPrint('Google TTS error: $e');
      return false;
    }
  }

  /// Phát âm thanh qua bộ phát TTS của thiết bị (hỗ trợ giọng Nam/Nữ thực sự)
  Future<void> _speakDevice(String text, VoicePreset preset) async {
    try {
      await _tts.setLanguage(preset.locale);
      await _tts.setSpeechRate(speechRate.value);

      // Điều chỉnh pitch theo giới tính: Giọng Nam trầm hơn (0.78), Giọng Nữ thanh (1.0)
      final effectivePitch = (preset.defaultPitch * pitch.value).clamp(0.6, 1.5);
      await _tts.setPitch(effectivePitch);
      await _tts.setVolume(1.0);

      // Tìm gói giọng phù hợp trên thiết bị
      if (deviceVoices.isNotEmpty) {
        final matches = deviceVoices.where((v) {
          if (v is! Map) return false;
          final locale = (v['locale'] ?? '').toString().toLowerCase();
          final target = preset.locale.toLowerCase().replaceAll('-', '_');
          final targetHyphen = preset.locale.toLowerCase();
          return locale.contains(target) || locale.contains(targetHyphen);
        }).toList();

        if (matches.isNotEmpty) {
          final isMale = preset.gender == 'Male';
          // Các mã giọng nam phổ biến trên Android Google TTS / Samsung / iOS
          const maleHints = ['iom', 'tpd', 'iob', 'rjs', 'fis', 'aub', 'male', 'man', 'david', 'mark', 'george'];
          const femaleHints = ['sfg', 'tpc', 'gba', 'afh', 'female', 'woman', 'zira', 'susan', 'catherine'];

          final targetHints = isMale ? maleHints : femaleHints;
          final matchedVoice = matches.firstWhere(
            (v) {
              final name = (v['name'] ?? '').toString().toLowerCase();
              return targetHints.any((h) => name.contains(h));
            },
            orElse: () => matches.first,
          );

          if (matchedVoice is Map) {
            await _tts.setVoice({
              'name': matchedVoice['name'].toString(),
              'locale': matchedVoice['locale'].toString(),
            });
          }
        }
      }

      await _tts.speak(text);
    } catch (e) {
      debugPrint('Device TTS error: $e');
      isSpeaking.value = false;
      currentSpeakingText.value = '';
    }
  }

  /// Dừng phát âm
  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {}
    try {
      await _tts.stop();
    } catch (_) {}
    isSpeaking.value = false;
    currentSpeakingText.value = '';
  }

  /// Thay đổi giọng đọc
  Future<void> setVoice(String voiceId) async {
    selectedVoiceId.value = voiceId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_voiceKey, voiceId);
  }

  /// Thay đổi tốc độ nói
  Future<void> setSpeechRate(double rate) async {
    speechRate.value = rate;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_rateKey, rate);
  }

  /// Thay đổi độ cao giọng
  Future<void> setPitch(double val) async {
    pitch.value = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_pitchKey, val);
  }

  /// Nghe thử giọng hiện tại
  Future<void> testVoice() async {
    const sample = 'Hello! I am your AI Language Mentor. How are you doing today?';
    await speak(sample);
  }

  @override
  void onClose() {
    _player.dispose();
    _tts.stop();
    super.onClose();
  }
}
