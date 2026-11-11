/// Một câu người dùng đã luyện viết với từ vựng và được AI đánh giá.
class PracticeSentence {
  final String id;
  final String vocabWord; // Từ mục tiêu
  final String originalSentence; // Câu gốc người dùng viết
  final String correctedSentence; // Câu sửa lại tự nhiên hơn của AI
  final int rating; // Đánh giá sao của AI (1 đến 5 sao)
  final bool isCorrect; // AI đánh giá đúng hay cần sửa
  final String feedback; // Lời nhận xét
  final String sentenceUsage; // Câu này dùng ở đâu, khi nào
  final DateTime createdAt;

  PracticeSentence({
    required this.id,
    required this.vocabWord,
    required this.originalSentence,
    required this.correctedSentence,
    this.rating = 5,
    required this.isCorrect,
    required this.feedback,
    required this.sentenceUsage,
    required this.createdAt,
  });

  /// Định dạng ngữ cảnh sử dụng gọn gàng, tránh lặp từ "Dùng khi: Dùng khi..."
  String get displayUsage {
    final clean = sentenceUsage.trim();
    if (clean.isEmpty) return '';
    final stripped = clean.replaceFirst(
      RegExp(
        r'^(dùng\s+khi|ngữ\s+cảnh\s+khi|ngữ\s+cảnh|khi|trong\s+trường\s+hợp)\s*[:：\-]?\s*(khi\s*)?',
        caseSensitive: false,
      ),
      '',
    );
    return 'Dùng khi: ${stripped.trim()}';
  }

  factory PracticeSentence.fromJson(Map<String, dynamic> json) {
    return PracticeSentence(
      id: json['id'] as String,
      vocabWord: (json['vocabWord'] ?? '') as String,
      originalSentence: (json['originalSentence'] ?? '') as String,
      correctedSentence: (json['correctedSentence'] ?? '') as String,
      rating: ((json['rating'] as num?) ?? 5).toInt().clamp(1, 5),
      isCorrect: (json['isCorrect'] ?? false) as bool,
      feedback: (json['feedback'] ?? '') as String,
      sentenceUsage: (json['sentenceUsage'] ?? '') as String,
      createdAt: json['createdAt'] == null
          ? DateTime.now()
          : DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'vocabWord': vocabWord,
        'originalSentence': originalSentence,
        'correctedSentence': correctedSentence,
        'rating': rating,
        'isCorrect': isCorrect,
        'feedback': feedback,
        'sentenceUsage': sentenceUsage,
        'createdAt': createdAt.toIso8601String(),
      };
}
