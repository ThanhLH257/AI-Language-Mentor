import '../services/phonetic_helper.dart';

/// Một từ vựng trong sổ tay, có theo dõi điểm sao và số lần luyện tập.
class Vocabulary {
  final String id;
  final String word; // Từ tiếng Anh
  final String phonetic; // Phiên âm IPA (ví dụ: /kɒfi/)
  final String meaning; // Nghĩa tiếng Việt
  final String example; // Câu ví dụ
  final String usage; // Từ này thường dùng ở đâu, khi nào (tiếng Việt)
  final double averageRating; // Điểm sao trung bình (0.0 đến 5.0, mặc định 0.0 khi chưa luyện)
  final int practiceCount; // Số lần đã viết câu luyện tập với từ này
  final DateTime createdAt;

  Vocabulary({
    required this.id,
    required this.word,
    this.phonetic = '',
    required this.meaning,
    required this.example,
    this.usage = '',
    this.averageRating = 0.0,
    this.practiceCount = 0,
    required this.createdAt,
  });

  /// Định dạng ngữ cảnh sử dụng gọn gàng, tránh lặp từ "Dùng khi: Dùng khi..."
  String get displayUsage {
    final clean = usage.trim();
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

  /// Định dạng phiên âm IPA chuẩn, tự động bổ sung dấu /.../ nếu thiếu
  String get displayPhonetic {
    var p = phonetic.trim();
    if (p.isEmpty) {
      p = PhoneticHelper.getPhonetic(word);
    }
    if (p.isEmpty) return '';
    if (p.startsWith('/') && p.endsWith('/')) return p;
    if (p.startsWith('[')) return p;
    return '/$p/';
  }

  /// Tạo bản sao có cập nhật điểm số mới sau khi luyện câu
  Vocabulary copyWith({
    String? phonetic,
    String? meaning,
    String? example,
    String? usage,
    double? averageRating,
    int? practiceCount,
  }) {
    return Vocabulary(
      id: id,
      word: word,
      phonetic: phonetic ?? this.phonetic,
      meaning: meaning ?? this.meaning,
      example: example ?? this.example,
      usage: usage ?? this.usage,
      averageRating: averageRating ?? this.averageRating,
      practiceCount: practiceCount ?? this.practiceCount,
      createdAt: createdAt,
    );
  }

  /// Dùng cho cả dữ liệu AI trả về (chưa có id/createdAt) và dữ liệu đã lưu.
  factory Vocabulary.fromJson(Map<String, dynamic> json) {
    final word = (json['word'] ?? '') as String;
    return Vocabulary(
      id: (json['id'] as String?) ?? word.trim().toLowerCase(),
      word: word,
      phonetic: (json['phonetic'] ?? '') as String,
      meaning: (json['meaning'] ?? '') as String,
      example: (json['example'] ?? '') as String,
      usage: (json['usage'] ?? '') as String,
      averageRating: ((json['averageRating'] as num?) ?? 0.0).toDouble(),
      practiceCount: ((json['practiceCount'] as num?) ?? 0).toInt(),
      createdAt: json['createdAt'] == null
          ? DateTime.now()
          : DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'word': word,
        'phonetic': phonetic,
        'meaning': meaning,
        'example': example,
        'usage': usage,
        'averageRating': averageRating,
        'practiceCount': practiceCount,
        'createdAt': createdAt.toIso8601String(),
      };
}
