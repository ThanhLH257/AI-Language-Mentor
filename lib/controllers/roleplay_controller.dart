import 'package:get/get.dart';

import '../models/chat_message.dart';
import '../models/chat_session.dart';
import '../models/scenario.dart';
import '../services/ai_service.dart';
import '../services/storage_service.dart';

/// Quản lý logic phòng chat Roleplay.
class RoleplayController extends GetxController {
  final AiService _ai = AiService();
  final StorageService _storage = StorageService();

  final Scenario scenario;
  final ChatSession? resumeSession; // Khác null nếu chat tiếp đoạn cũ

  RoleplayController({required this.scenario, this.resumeSession});

  // Trạng thái reactive
  final messages = <ChatMessage>[].obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final activeTasks = <String>[].obs; // 3 nhiệm vụ của phiên này
  final completedTasks = <String>[].obs; // Nhiệm vụ đã được AI xác nhận xong

  late final String _sessionId;

  @override
  void onInit() {
    super.onInit();
    if (resumeSession != null) {
      // Resume: nạp lại lịch sử và nhiệm vụ cũ
      _sessionId = resumeSession!.id;
      messages.assignAll(resumeSession!.messages);
      if (resumeSession!.tasks.isNotEmpty) {
        activeTasks.assignAll(resumeSession!.tasks);
        completedTasks.assignAll(resumeSession!.completedTasks);
      } else {
        // Phiên cũ chưa có nhiệm vụ riêng: lấy 3 nhiệm vụ đầu của kho
        activeTasks.assignAll(scenario.tasks.take(Scenario.tasksPerSession));
      }
    } else {
      _sessionId = DateTime.now().millisecondsSinceEpoch.toString();
      // Phiên mới: chọn ngẫu nhiên 3 nhiệm vụ từ kho
      final pool = List<String>.from(scenario.tasks)..shuffle();
      activeTasks.assignAll(pool.take(Scenario.tasksPerSession));

      // Nếu kịch bản có lời chào mở đầu sẵn từ AI, hiển thị ngay
      if (scenario.initialGreeting != null &&
          scenario.initialGreeting!.trim().isNotEmpty) {
        messages.add(
          ChatMessage(
            role: 'assistant',
            text: scenario.initialGreeting!.trim(),
            time: DateTime.now(),
          ),
        );
      }
    }
  }

  /// Số nhiệm vụ đã hoàn thành.
  int get doneCount => completedTasks.length;

  /// Gửi tin nhắn của user, nhận đánh giá + câu trả lời của AI.
  Future<void> sendMessage(String text) async {
    final content = text.trim();
    if (content.isEmpty || isLoading.value) return;

    errorMessage.value = '';

    // 1. Hiện ngay tin nhắn user (chưa có sao)
    messages.add(ChatMessage(role: 'user', text: content, time: DateTime.now()));
    await _requestReply();
  }

  /// Thử lại khi lần trước lỗi (tin nhắn cuối là của user, chưa có phản hồi).
  Future<void> retry() async {
    if (isLoading.value || messages.isEmpty || !messages.last.isUser) return;
    errorMessage.value = '';
    await _requestReply();
  }

  /// Gọi AI cho tin nhắn user cuối cùng, rồi cập nhật sao + thêm câu trả lời.
  Future<void> _requestReply() async {
    final userIndex = messages.length - 1;
    isLoading.value = true;

    try {
      // 2. Gọi AI kèm lịch sử và danh sách nhiệm vụ
      final result = await _ai.sendRoleplay(
        scenario: scenario,
        history: messages.toList(),
        tasks: activeTasks.toList(),
        completedTasks: completedTasks.toList(),
      );

      // 3. Cập nhật tin nhắn user với sao + gợi ý + cảnh báo lạc đề
      messages[userIndex] = messages[userIndex].copyWith(
        rating: result.rating,
        suggestion: result.suggestion,
        explanation: result.explanation,
        onTopic: result.onTopic,
        offTopicNote: result.offTopicNote,
        recommendedVocab: result.recommendedVocab,
      );

      // 4. Đánh dấu nhiệm vụ vừa hoàn thành (số thứ tự 1 - 3)
      for (final n in result.completedTaskNumbers) {
        if (n >= 1 && n <= activeTasks.length) {
          final task = activeTasks[n - 1];
          if (!completedTasks.contains(task)) completedTasks.add(task);
        }
      }

      // 5. Thêm câu trả lời của AI
      messages.add(
        ChatMessage(role: 'ai', text: result.aiReply, time: DateTime.now()),
      );

      // 6. Lưu lịch sử
      await _saveSession();
    } catch (e) {
      errorMessage.value = 'Không gửi được tin nhắn: $e';
    } finally {
      isLoading.value = false;
    }
  }

  /// Lưu phiên chat hiện tại vào SharedPreferences.
  Future<void> _saveSession() async {
    final session = ChatSession(
      id: _sessionId,
      scenarioId: scenario.id,
      scenarioTitle: scenario.title,
      aiRole: scenario.aiRole,
      emoji: scenario.emoji,
      description: scenario.description,
      messages: messages.toList(),
      tasks: activeTasks.toList(),
      completedTasks: completedTasks.toList(),
      updatedAt: DateTime.now(),
    );
    await _storage.saveSession(session);
  }
}
