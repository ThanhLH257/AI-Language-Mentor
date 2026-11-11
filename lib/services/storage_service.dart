import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/chat_session.dart';
import '../models/course_progress.dart';
import '../models/diary_entry.dart';
import '../models/practice_sentence.dart';
import '../models/user_account.dart';
import '../models/vocabulary.dart';
import 'supabase_service.dart';

/// Lưu / đọc dữ liệu cục bộ bằng SharedPreferences.
class StorageService {
  static const String _sessionsKey = 'chat_sessions';
  static const String _diaryKey = 'diary_entries';
  static const String _vocabKey = 'vocabulary';
  static const String _practiceKey = 'practice_sentences';
  static const String _usersKey = 'users';
  static const String _currentUserKey = 'current_user_email';
  static const String _darkModeKey = 'dark_mode';
  static const String _paletteKey = 'palette_index';
  static const String _courseProgressKey = 'course_progress';

  // ---------- Khóa học & Tiến độ ----------

  /// Đọc tất cả tiến độ khóa học của một người dùng.
  Future<Map<String, CourseProgress>> loadAllCourseProgress(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('${_courseProgressKey}_$userId');
    if (raw == null) return {};
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map.map(
        (key, value) => MapEntry(
          key,
          CourseProgress.fromJson(value as Map<String, dynamic>),
        ),
      );
    } catch (_) {
      return {};
    }
  }

  /// Lưu tiến độ và đánh giá một khóa học cho người dùng.
  Future<void> saveCourseProgress(CourseProgress progress) async {
    final prefs = await SharedPreferences.getInstance();
    final currentMap = await loadAllCourseProgress(progress.userId);
    currentMap[progress.courseId] = progress;

    final encoded = jsonEncode(
      currentMap.map((key, value) => MapEntry(key, value.toJson())),
    );
    await prefs.setString('${_courseProgressKey}_${progress.userId}', encoded);
  }

  /// Đặt trạng thái không hiển thị khóa học trong 1 ngày (24 giờ).
  Future<void> snoozeCourse(String userId, String courseId) async {
    final currentMap = await loadAllCourseProgress(userId);
    final existing = currentMap[courseId] ??
        CourseProgress(courseId: courseId, userId: userId);
    final updated = existing.copyWith(
      skipUntil: DateTime.now().add(const Duration(hours: 24)),
    );
    await saveCourseProgress(updated);
  }

  // ---------- Phiên chat ----------

  /// Đọc danh sách phiên chat (mới nhất trước).
  Future<List<ChatSession>> loadSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sessionsKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    final sessions = list
        .map((e) => ChatSession.fromJson(e as Map<String, dynamic>))
        .toList();
    sessions.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return sessions;
  }

  /// Thêm mới hoặc cập nhật 1 phiên chat theo id.
  Future<void> saveSession(ChatSession session) async {
    final prefs = await SharedPreferences.getInstance();
    final sessions = await loadSessions();
    final index = sessions.indexWhere((s) => s.id == session.id);
    if (index >= 0) {
      sessions[index] = session;
    } else {
      sessions.add(session);
    }
    await prefs.setString(
      _sessionsKey,
      jsonEncode(sessions.map((s) => s.toJson()).toList()),
    );
    _syncSessionToSupabase(session);
  }

  // ---------- Nhật ký ----------

  /// Đọc danh sách bài nhật ký (mới nhất trước).
  Future<List<DiaryEntry>> loadDiaries() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_diaryKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    final entries = list
        .map((e) => DiaryEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }

  /// Ghi đè toàn bộ danh sách nhật ký.
  Future<void> saveDiaries(List<DiaryEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _diaryKey,
      jsonEncode(entries.map((e) => e.toJson()).toList()),
    );
    _syncDiariesToSupabase(entries);
  }

  // ---------- Từ vựng ----------

  /// Đọc danh sách từ vựng đã lưu (mới nhất trước).
  Future<List<Vocabulary>> loadVocab() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_vocabKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    final items = list
        .map((e) => Vocabulary.fromJson(e as Map<String, dynamic>))
        .toList();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  /// Ghi đè toàn bộ danh sách từ vựng.
  Future<void> saveVocab(List<Vocabulary> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _vocabKey,
      jsonEncode(items.map((v) => v.toJson()).toList()),
    );
    _syncVocabToSupabase(items);
  }

  // ---------- Câu luyện viết ----------

  /// Đọc danh sách câu đã luyện (mới nhất trước).
  Future<List<PracticeSentence>> loadPracticeSentences() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_practiceKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    final items = list
        .map((e) => PracticeSentence.fromJson(e as Map<String, dynamic>))
        .toList();
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  /// Ghi đè toàn bộ danh sách câu luyện viết.
  Future<void> savePracticeSentences(List<PracticeSentence> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _practiceKey,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
    _syncPracticeSentencesToSupabase(items);
  }

  // ---------- Đồng bộ với Supabase PostgreSQL ----------

  Future<void> _syncSessionToSupabase(ChatSession s) async {
    if (!SupabaseService.isInitialized) return;
    try {
      final email = await getCurrentUserEmail() ?? 'guest@example.com';
      await SupabaseService.client.from('chat_sessions').upsert({
        'id': s.id,
        'user_email': email,
        'scenario_id': s.scenarioId,
        'scenario_title': s.scenarioTitle,
        'ai_role': s.aiRole,
        'emoji': s.emoji,
        'description': s.description,
        'messages': s.messages.map((m) => m.toJson()).toList(),
        'tasks': s.tasks,
        'completed_tasks': s.completedTasks,
        'updated_at': s.updatedAt.toIso8601String(),
      });
    } catch (e) {
      debugPrint('Supabase saveSession sync notice: $e');
    }
  }

  Future<void> _syncDiariesToSupabase(List<DiaryEntry> entries) async {
    if (!SupabaseService.isInitialized || entries.isEmpty) return;
    try {
      final email = await getCurrentUserEmail() ?? 'guest@example.com';
      final payload = entries
          .map((d) => {
                'id': d.id,
                'user_email': email,
                'content': d.content,
                'score': d.score,
                'corrected_text': d.correctedText,
                'feedback': d.feedback,
                'created_at': d.createdAt.toIso8601String(),
              })
          .toList();
      await SupabaseService.client.from('diary_entries').upsert(payload);
    } catch (e) {
      debugPrint('Supabase saveDiaries sync notice: $e');
    }
  }

  Future<void> _syncVocabToSupabase(List<Vocabulary> items) async {
    if (!SupabaseService.isInitialized || items.isEmpty) return;
    try {
      final email = await getCurrentUserEmail() ?? 'guest@example.com';
      final payload = items
          .map((v) => {
                'id': v.id,
                'user_email': email,
                'word': v.word,
                'phonetic': v.phonetic,
                'meaning': v.meaning,
                'example': v.example,
                'usage': v.usage,
                'average_rating': v.averageRating,
                'practice_count': v.practiceCount,
                'created_at': v.createdAt.toIso8601String(),
              })
          .toList();
      await SupabaseService.client.from('vocabulary').upsert(payload);
    } catch (e) {
      debugPrint('Supabase saveVocab sync notice: $e');
    }
  }

  Future<void> _syncPracticeSentencesToSupabase(List<PracticeSentence> items) async {
    if (!SupabaseService.isInitialized || items.isEmpty) return;
    try {
      final email = await getCurrentUserEmail() ?? 'guest@example.com';
      final payload = items
          .map((s) => {
                'id': s.id,
                'user_email': email,
                'vocab_word': s.vocabWord,
                'original_sentence': s.originalSentence,
                'corrected_sentence': s.correctedSentence,
                'rating': s.rating,
                'is_correct': s.isCorrect,
                'feedback': s.feedback,
                'sentence_usage': s.sentenceUsage,
                'created_at': s.createdAt.toIso8601String(),
              })
          .toList();
      await SupabaseService.client.from('practice_sentences').upsert(payload);
    } catch (e) {
      debugPrint('Supabase savePracticeSentences sync notice: $e');
    }
  }

  /// Đẩy toàn bộ dữ liệu đang có trên máy lên Supabase để xem được trên Table Editor.
  Future<void> syncAllLocalDataToSupabase() async {
    if (!SupabaseService.isInitialized) return;
    try {
      final sessions = await loadSessions();
      for (final s in sessions) {
        await _syncSessionToSupabase(s);
      }
      final diaries = await loadDiaries();
      await _syncDiariesToSupabase(diaries);
      final vocabs = await loadVocab();
      await _syncVocabToSupabase(vocabs);
      final sentences = await loadPracticeSentences();
      await _syncPracticeSentencesToSupabase(sentences);
    } catch (e) {
      debugPrint('Supabase syncAllLocalData notice: $e');
    }
  }

  // ---------- Tài khoản ----------

  Future<List<UserAccount>> loadUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_usersKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => UserAccount.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveUsers(List<UserAccount> users) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _usersKey,
      jsonEncode(users.map((u) => u.toJson()).toList()),
    );
  }

  /// Email của người dùng đang đăng nhập (null nếu chưa đăng nhập).
  Future<String?> getCurrentUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentUserKey);
  }

  Future<void> setCurrentUserEmail(String? email) async {
    final prefs = await SharedPreferences.getInstance();
    if (email == null) {
      await prefs.remove(_currentUserKey);
    } else {
      await prefs.setString(_currentUserKey, email);
    }
  }

  // ---------- Cấu hình ----------

  Future<bool> getDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_darkModeKey) ?? false;
  }

  Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, value);
  }

  /// Vị trí màu chủ đạo đã chọn trong danh sách kPalettes.
  Future<int> getPaletteIndex() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_paletteKey) ?? 0;
  }

  Future<void> setPaletteIndex(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_paletteKey, index);
  }
}
