import 'package:get/get.dart';

import '../models/diary_entry.dart';
import '../services/ai_service.dart';
import '../services/storage_service.dart';

/// Quản lý nhật ký: danh sách, chấm điểm AI, lưu bài.
class DiaryController extends GetxController {
  final AiService _ai = AiService();
  final StorageService _storage = StorageService();

  final entries = <DiaryEntry>[].obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;

  // Kết quả chấm điểm của bài đang soạn (null nếu chưa chấm)
  final result = Rxn<DiaryResult>();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    entries.assignAll(await _storage.loadDiaries());
  }

  /// Xóa kết quả cũ khi mở màn hình soạn bài mới.
  void resetDraft() {
    result.value = null;
    errorMessage.value = '';
  }

  /// Gửi AI chấm điểm.
  Future<void> evaluate(String content) async {
    final text = content.trim();
    if (text.isEmpty) {
      errorMessage.value = 'Hãy viết nội dung nhật ký trước';
      return;
    }
    errorMessage.value = '';
    isLoading.value = true;
    try {
      result.value = await _ai.evaluateDiary(text);
    } catch (e) {
      errorMessage.value = 'Không chấm được bài: $e';
    } finally {
      isLoading.value = false;
    }
  }

  /// Lưu bài đã chấm. Trả về true nếu lưu thành công.
  Future<bool> save(String content) async {
    final r = result.value;
    if (r == null) return false;
    final entry = DiaryEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content.trim(),
      score: r.score,
      correctedText: r.correctedText,
      feedback: r.feedback,
      createdAt: DateTime.now(),
    );
    entries.insert(0, entry);
    await _storage.saveDiaries(entries.toList());
    return true;
  }

  /// Xóa bài nhật ký theo id và lưu lại vào SharedPreferences.
  Future<void> deleteEntry(String id) async {
    entries.removeWhere((e) => e.id == id);
    await _storage.saveDiaries(entries.toList());
  }
}

