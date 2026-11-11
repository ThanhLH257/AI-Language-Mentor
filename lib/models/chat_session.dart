import 'chat_message.dart';

/// Một phiên hội thoại đã lưu (dùng cho Resume Chat).
class ChatSession {
  final String id;
  final String scenarioId;
  final String scenarioTitle;
  final String? aiRole;
  final String? emoji;
  final String? description;
  final List<ChatMessage> messages;
  final List<String> tasks; // 3 nhiệm vụ được chọn cho phiên này
  final List<String> completedTasks; // Nhiệm vụ đã hoàn thành
  final DateTime updatedAt;

  ChatSession({
    required this.id,
    required this.scenarioId,
    required this.scenarioTitle,
    this.aiRole,
    this.emoji,
    this.description,
    required this.messages,
    this.tasks = const [],
    this.completedTasks = const [],
    required this.updatedAt,
  });

  /// Tạo bản sao với danh sách tin nhắn / thời gian mới.
  ChatSession copyWith({List<ChatMessage>? messages, DateTime? updatedAt}) {
    return ChatSession(
      id: id,
      scenarioId: scenarioId,
      scenarioTitle: scenarioTitle,
      aiRole: aiRole,
      emoji: emoji,
      description: description,
      messages: messages ?? this.messages,
      tasks: tasks,
      completedTasks: completedTasks,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'] as String,
      scenarioId: json['scenarioId'] as String,
      scenarioTitle: json['scenarioTitle'] as String,
      aiRole: json['aiRole'] as String?,
      emoji: json['emoji'] as String?,
      description: json['description'] as String?,
      messages: (json['messages'] as List)
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
      // Phiên cũ chưa có nhiệm vụ riêng thì để rỗng
      tasks: List<String>.from((json['tasks'] as List?) ?? []),
      completedTasks: List<String>.from((json['completedTasks'] as List?) ?? []),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'scenarioId': scenarioId,
        'scenarioTitle': scenarioTitle,
        'aiRole': aiRole,
        'emoji': emoji,
        'description': description,
        'messages': messages.map((m) => m.toJson()).toList(),
        'tasks': tasks,
        'completedTasks': completedTasks,
        'updatedAt': updatedAt.toIso8601String(),
      };
}
