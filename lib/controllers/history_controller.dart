import 'package:get/get.dart';

import '../models/chat_session.dart';
import '../services/storage_service.dart';

/// Danh sách các cuộc hội thoại đã lưu.
class HistoryController extends GetxController {
  final StorageService _storage = StorageService();

  final sessions = <ChatSession>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    sessions.assignAll(await _storage.loadSessions());
    isLoading.value = false;
  }
}

