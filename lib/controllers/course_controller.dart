import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../models/course_model.dart';
import '../models/course_progress.dart';
import '../services/storage_service.dart';

/// Quản lý trạng thái khóa học nhỏ, tiến độ học và đánh giá của người dùng.
class CourseController extends GetxController {
  final StorageService _storage = StorageService();

  // Danh sách các khóa học mẫu theo từng đề tài
  final List<CourseModel> courses = kTopicCourses;

  // Map lưu tiến độ theo courseId
  final progressMap = <String, CourseProgress>{}.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  /// Lấy ID hoặc email của người dùng hiện tại
  String get _currentUserId {
    try {
      final auth = Get.find<AuthController>();
      return auth.currentUser.value?.email ?? 'guest_user';
    } catch (_) {
      return 'guest_user';
    }
  }

  /// Tải lại tiến độ của người dùng hiện tại
  Future<void> load() async {
    final uid = _currentUserId;
    final map = await _storage.loadAllCourseProgress(uid);
    progressMap.assignAll(map);
  }

  /// Khóa học này đã hoàn thành chưa?
  bool isCompleted(String courseId) {
    return progressMap[courseId]?.isCompleted ?? false;
  }

  /// Khóa học này có đang được chọn "Không hiển thị lại trong 1 ngày" không?
  bool isSnoozed(String courseId) {
    return progressMap[courseId]?.isSnoozed ?? false;
  }

  /// Lấy thông tin tiến độ của một khóa học
  CourseProgress? getProgress(String courseId) {
    return progressMap[courseId];
  }

  /// Tìm khóa học theo scenarioId
  CourseModel? findCourseByScenario(String scenarioId) {
    return courses.firstWhereOrNull((c) => c.scenarioId == scenarioId);
  }

  /// Số lượng khóa học đã hoàn thành
  int get completedCount =>
      progressMap.values.where((p) => p.isCompleted).length;

  /// Tổng số khóa học
  int get totalCount => courses.length;

  /// Hoàn thành hoặc học lại khóa học và lưu đánh giá (sao, nhận xét)
  Future<void> completeCourse({
    required String courseId,
    required double rating,
    required String review,
  }) async {
    final uid = _currentUserId;
    final existing = progressMap[courseId];

    final updated = CourseProgress(
      courseId: courseId,
      userId: uid,
      isCompleted: true,
      completedAt: DateTime.now(),
      rating: rating,
      review: review.trim(),
      skipUntil: existing?.skipUntil,
    );

    progressMap[courseId] = updated;
    await _storage.saveCourseProgress(updated);
  }

  /// Đặt cờ bỏ qua khóa học trong 1 ngày (24 giờ)
  Future<void> snoozeCourse(String courseId) async {
    final uid = _currentUserId;
    await _storage.snoozeCourse(uid, courseId);
    await load();
  }
}
