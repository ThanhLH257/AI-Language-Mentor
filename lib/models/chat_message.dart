import 'vocabulary.dart';

/// Một tin nhắn trong đoạn chat.
/// - Tin nhắn của user: có thể được AI chấm sao (rating) + gợi ý sửa + từ vựng.
/// - Tin nhắn của AI: chỉ có nội dung.
class ChatMessage {
  final String role; // 'user' hoặc 'ai'
  final String text; // Nội dung tin nhắn
  final int? rating; // Số sao 1 - 5 (null nếu chưa chấm)
  final String? suggestion; // Câu viết lại tự nhiên hơn
  final String? explanation; // Giải thích ngắn gọn
  final bool? onTopic; // false nếu user trả lời lạc đề (null nếu chưa chấm)
  final String? offTopicNote; // Nhắc nhở khi lạc đề
  final List<Vocabulary> recommendedVocab; // Từ vựng AI gợi ý (1 - 2 từ)
  final DateTime time;

  ChatMessage({
    required this.role,
    required this.text,
    this.rating,
    this.suggestion,
    this.explanation,
    this.onTopic,
    this.offTopicNote,
    this.recommendedVocab = const [],
    required this.time,
  });

  bool get isUser => role == 'user';

  /// Tạo bản sao, dùng để cập nhật kết quả chấm điểm cho tin nhắn user.
  ChatMessage copyWith({
    int? rating,
    String? suggestion,
    String? explanation,
    bool? onTopic,
    String? offTopicNote,
    List<Vocabulary>? recommendedVocab,
  }) {
    return ChatMessage(
      role: role,
      text: text,
      rating: rating ?? this.rating,
      suggestion: suggestion ?? this.suggestion,
      explanation: explanation ?? this.explanation,
      onTopic: onTopic ?? this.onTopic,
      offTopicNote: offTopicNote ?? this.offTopicNote,
      recommendedVocab: recommendedVocab ?? this.recommendedVocab,
      time: time,
    );
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      role: json['role'] as String,
      text: json['text'] as String,
      rating: json['rating'] as int?,
      suggestion: json['suggestion'] as String?,
      explanation: json['explanation'] as String?,
      onTopic: json['onTopic'] as bool?,
      offTopicNote: json['offTopicNote'] as String?,
      // Dữ liệu cũ chưa có trường này thì mặc định rỗng
      recommendedVocab: ((json['recommendedVocab'] as List?) ?? [])
          .map((e) => Vocabulary.fromJson(e as Map<String, dynamic>))
          .toList(),
      time: DateTime.parse(json['time'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'role': role,
        'text': text,
        'rating': rating,
        'suggestion': suggestion,
        'explanation': explanation,
        'onTopic': onTopic,
        'offTopicNote': offTopicNote,
        'recommendedVocab': recommendedVocab.map((v) => v.toJson()).toList(),
        'time': time.toIso8601String(),
      };
}
