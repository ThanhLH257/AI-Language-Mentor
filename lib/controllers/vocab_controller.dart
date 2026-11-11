import 'package:get/get.dart';

import '../models/practice_sentence.dart';
import '../models/vocabulary.dart';
import '../services/ai_service.dart';
import '../services/storage_service.dart';

/// Quản lý sổ tay từ vựng: lưu, xóa, luyện đặt câu và lưu câu đã viết.
class VocabController extends GetxController {
  final StorageService _storage = StorageService();
  final AiService _ai = AiService();

  final vocabList = <Vocabulary>[].obs;
  final practiceSentences = <PracticeSentence>[].obs;

  // Trạng thái chế độ luyện đặt câu
  final isChecking = false.obs;
  final checkResult = Rxn<SentenceCheckResult>();
  final errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    final loaded = await _storage.loadVocab();
    // Tự động khôi phục phiên âm cho các từ đã lưu trước đó nếu bị thiếu
    bool needUpdate = false;
    final normalized = <Vocabulary>[];
    for (final v in loaded) {
      if (v.phonetic.trim().isEmpty) {
        final ipa = v.displayPhonetic;
        if (ipa.isNotEmpty) {
          normalized.add(v.copyWith(phonetic: ipa));
          needUpdate = true;
          continue;
        }
      }
      normalized.add(v);
    }
    if (needUpdate) {
      await _storage.saveVocab(normalized);
    }
    vocabList.assignAll(normalized);
    practiceSentences.assignAll(await _storage.loadPracticeSentences());
  }

  /// Từ này đã có trong sổ tay chưa (so sánh không phân biệt hoa thường).
  bool isSaved(String word) {
    final key = word.trim().toLowerCase();
    return vocabList.any((v) => v.word.trim().toLowerCase() == key);
  }

  /// Lưu từ mới vào sổ tay; bỏ qua nếu đã có. Trả về true nếu lưu mới.
  Future<bool> addVocab(Vocabulary vocab) async {
    if (isSaved(vocab.word)) return false;
    final item = Vocabulary(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      word: vocab.word.trim(),
      phonetic: vocab.displayPhonetic.isNotEmpty
          ? vocab.displayPhonetic
          : vocab.phonetic.trim(),
      meaning: vocab.meaning,
      example: vocab.example,
      usage: vocab.usage,
      createdAt: DateTime.now(),
    );
    vocabList.insert(0, item);
    await _storage.saveVocab(vocabList.toList());
    return true;
  }

  Future<void> removeVocab(String id) async {
    vocabList.removeWhere((v) => v.id == id);
    await _storage.saveVocab(vocabList.toList());
  }

  // ---------- Quản lý câu đã luyện viết ----------

  /// Kiểm tra xem câu này đã lưu vào danh sách câu luyện chưa.
  bool isSentenceSaved(String originalSentence) {
    final key = originalSentence.trim().toLowerCase();
    return practiceSentences.any(
      (s) => s.originalSentence.trim().toLowerCase() == key,
    );
  }

  /// Lưu một câu luyện viết mới.
  Future<bool> addPracticeSentence(PracticeSentence sentence) async {
    if (isSentenceSaved(sentence.originalSentence)) return false;
    practiceSentences.insert(0, sentence);
    await _storage.savePracticeSentences(practiceSentences.toList());
    return true;
  }

  /// Xóa câu đã luyện viết.
  Future<void> removePracticeSentence(String id) async {
    practiceSentences.removeWhere((s) => s.id == id);
    await _storage.savePracticeSentences(practiceSentences.toList());
  }

  /// Xóa kết quả kiểm tra cũ (khi đổi từ khác).
  void resetCheck() {
    checkResult.value = null;
    errorMessage.value = '';
  }

  /// Cập nhật điểm sao trung bình cho từ vựng sau khi AI chấm điểm câu.
  Future<void> updateVocabRating(String vocabWord, int sentenceRating) async {
    final key = vocabWord.trim().toLowerCase();
    final index = vocabList.indexWhere((v) => v.word.trim().toLowerCase() == key);
    if (index >= 0) {
      final old = vocabList[index];
      final newCount = old.practiceCount + 1;
      // Cộng dồn tính điểm trung bình
      final newRating =
          ((old.averageRating * old.practiceCount) + sentenceRating) / newCount;
      final roundedRating = double.parse(newRating.toStringAsFixed(1));

      vocabList[index] = old.copyWith(
        averageRating: roundedRating,
        practiceCount: newCount,
      );
      await _storage.saveVocab(vocabList.toList());
    }
  }

  /// Gửi AI kiểm tra câu người dùng đặt.
  Future<void> checkSentence(Vocabulary vocab, String sentence) async {
    final text = sentence.trim();
    if (text.isEmpty) {
      errorMessage.value = 'Hãy viết một câu chứa từ "${vocab.word}"';
      return;
    }
    errorMessage.value = '';
    checkResult.value = null;
    isChecking.value = true;
    try {
      final res = await _ai.checkSentence(vocab: vocab, sentence: text);
      checkResult.value = res;
      // Tự động cập nhật số sao tích lũy cho từ vựng này
      await updateVocabRating(vocab.word, res.rating);
    } catch (e) {
      errorMessage.value = 'Không kiểm tra được câu: $e';
    } finally {
      isChecking.value = false;
    }
  }
}
