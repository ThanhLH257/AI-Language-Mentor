/// Một bài nhật ký đã được AI chấm điểm.
class DiaryEntry {
  final String id;
  final String content; // Bài viết gốc
  final int score; // Điểm 1 - 10
  final String correctedText; // Bản AI viết lại
  final String feedback; // Nhận xét
  final DateTime createdAt;

  DiaryEntry({
    required this.id,
    required this.content,
    required this.score,
    required this.correctedText,
    required this.feedback,
    required this.createdAt,
  });

  factory DiaryEntry.fromJson(Map<String, dynamic> json) {
    return DiaryEntry(
      id: json['id'] as String,
      content: json['content'] as String,
      score: json['score'] as int,
      correctedText: json['correctedText'] as String,
      feedback: json['feedback'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'score': score,
        'correctedText': correctedText,
        'feedback': feedback,
        'createdAt': createdAt.toIso8601String(),
      };
}

