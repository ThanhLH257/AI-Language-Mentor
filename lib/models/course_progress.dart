/// Model lưu tiến độ và đánh giá khóa học của người dùng.
class CourseProgress {
  final String courseId;
  final String userId;
  final bool isCompleted;
  final DateTime? completedAt;
  final double rating; // Đánh giá sao từ 1.0 đến 5.0
  final String review; // Nhận xét hoặc cảm nhận
  final DateTime? skipUntil; // Mốc thời gian bỏ qua màn hình học trong 1 ngày

  const CourseProgress({
    required this.courseId,
    required this.userId,
    this.isCompleted = false,
    this.completedAt,
    this.rating = 5.0,
    this.review = '',
    this.skipUntil,
  });

  /// Kiểm tra xem còn trong thời hạn bỏ qua 1 ngày hay không
  bool get isSnoozed {
    if (skipUntil == null) return false;
    return skipUntil!.isAfter(DateTime.now());
  }

  CourseProgress copyWith({
    String? courseId,
    String? userId,
    bool? isCompleted,
    DateTime? completedAt,
    double? rating,
    String? review,
    DateTime? skipUntil,
  }) {
    return CourseProgress(
      courseId: courseId ?? this.courseId,
      userId: userId ?? this.userId,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      rating: rating ?? this.rating,
      review: review ?? this.review,
      skipUntil: skipUntil ?? this.skipUntil,
    );
  }

  factory CourseProgress.fromJson(Map<String, dynamic> json) {
    return CourseProgress(
      courseId: json['courseId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      isCompleted: json['isCompleted'] as bool? ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'] as String)
          : null,
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      review: json['review'] as String? ?? '',
      skipUntil: json['skipUntil'] != null
          ? DateTime.tryParse(json['skipUntil'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'courseId': courseId,
        'userId': userId,
        'isCompleted': isCompleted,
        'completedAt': completedAt?.toIso8601String(),
        'rating': rating,
        'review': review,
        'skipUntil': skipUntil?.toIso8601String(),
      };
}
