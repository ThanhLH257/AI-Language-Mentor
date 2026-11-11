import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/scenario.dart';
import '../services/ai_service.dart';
import '../theme/app_theme.dart';
import '../views/roleplay_chat_screen.dart';

/// Modal Hội thoại Vô hạn (Infinite Chat): Kết hợp Nhập vai theo yêu cầu & Tám chuyện tự do
class InfiniteChatModal extends StatefulWidget {
  const InfiniteChatModal({super.key});

  /// Hiển thị modal dưới dạng BottomSheet
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const InfiniteChatModal(),
    );
  }

  @override
  State<InfiniteChatModal> createState() => _InfiniteChatModalState();
}

class _InfiniteChatModalState extends State<InfiniteChatModal>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _customTopicCtrl = TextEditingController();
  final TextEditingController _freeTopicCtrl = TextEditingController();
  final AiService _aiService = AiService();

  bool _isLoading = false;
  String _loadingMessage = '';

  // Chế độ người bạn trò chuyện Free Talk
  int _selectedPersonaIndex = 0;
  final List<Map<String, String>> _personas = const [
    {
      'name': 'Bạn bản xứ thân thiện',
      'role': 'Friendly Native Friend',
      'desc': 'Trò chuyện vui vẻ, tự nhiên, gần gũi',
      'emoji': '👋',
    },
    {
      'name': 'Gia sư chỉnh lỗi (Mentor)',
      'role': 'Strict English Tutor',
      'desc': 'Chữa lỗi chi tiết, gợi ý từ vựng học thuật',
      'emoji': '🎓',
    },
    {
      'name': 'Đồng nghiệp công sở',
      'role': 'Work Colleague',
      'desc': 'Giao tiếp công việc, phỏng vấn, thảo luận',
      'emoji': '💼',
    },
  ];

  // Gợi ý tình huống Custom Roleplay
  final List<String> _suggestedScenarios = const [
    '🦷 Đi khám răng tại phòng khám',
    '🎬 Mua vé xem phim tại rạp chiếu',
    '✈️ Thủ tục hải quan tại sân bay',
    '🍕 Đặt bàn và gọi món nhà hàng Ý',
    '💼 Đàm phán lương với nhà tuyển dụng',
    '🚗 Thuê xe tự lái khi đi du lịch',
  ];

  // Gợi ý chủ đề Free Talk
  final List<String> _suggestedFreeTopics = const [
    'Âm nhạc & Phim ảnh',
    'Kế hoạch du lịch mùa hè',
    'Công nghệ trí tuệ nhân tạo (AI)',
    'Ẩm thực đường phố Việt Nam',
    'Cuộc sống học tập & công việc',
    'Tâm sự cuối tuần',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _customTopicCtrl.dispose();
    _freeTopicCtrl.dispose();
    super.dispose();
  }

  /// Bắt đầu tạo kịch bản theo yêu cầu bằng AI
  Future<void> _startCustomRoleplay() async {
    final topic = _customTopicCtrl.text.trim();
    if (topic.isEmpty) {
      Get.snackbar(
        'Nhắc nhở',
        'Vui lòng nhập tình huống hoặc chọn một gợi ý bên dưới',
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(AppSpacing.md),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _loadingMessage = 'AI đang thiết lập nhân vật và nhiệm vụ...';
    });

    try {
      final scenario = await _aiService.generateCustomScenario(topic);
      if (!mounted) return;
      Navigator.of(context).pop(); // Đóng modal
      Get.to(() => RoleplayChatScreen(scenario: scenario));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      Get.snackbar(
        'Lỗi',
        'Không thể khởi tạo kịch bản: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
      );
    }
  }

  /// Bắt đầu Tám chuyện tự do
  void _startFreeTalk() {
    final topic = _freeTopicCtrl.text.trim().isNotEmpty
        ? _freeTopicCtrl.text.trim()
        : 'Daily Life & Thoughts';
    final persona = _personas[_selectedPersonaIndex];

    final scenario = Scenario.freeTalk(
      topic: topic,
      persona: persona['role'] ?? 'Friendly Friend',
      emoji: persona['emoji'] ?? '💬',
    );

    Navigator.of(context).pop(); // Đóng modal
    Get.to(() => RoleplayChatScreen(scenario: scenario));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Thanh gạt trên đỉnh modal
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.outlineVariant.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),

            // Header Icon Vô hạn + Tiêu đề
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.all_inclusive_rounded,
                      color: scheme.primary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hội thoại Vô hạn',
                          style: text.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          'Tự chọn kịch bản hoặc trò chuyện tự do không giới hạn',
                          style: text.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Tab bar chuyển đổi giữa 2 chế độ
            TabBar(
              controller: _tabController,
              labelColor: scheme.primary,
              unselectedLabelColor: scheme.onSurfaceVariant,
              indicatorColor: scheme.primary,
              indicatorWeight: 3,
              tabs: const [
                Tab(
                  icon: Icon(Icons.theater_comedy_rounded, size: 20),
                  text: 'Nhập vai theo yêu cầu',
                ),
                Tab(
                  icon: Icon(Icons.chat_bubble_outline_rounded, size: 20),
                  text: 'Tám chuyện tự do',
                ),
              ],
            ),

            // Nội dung tab
            Flexible(
              child: _isLoading
                  ? _buildLoadingState(scheme, text)
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildCustomRoleplayTab(scheme, text),
                        _buildFreeTalkTab(scheme, text),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Trạng thái đang tải AI sinh kịch bản
  Widget _buildLoadingState(ColorScheme scheme, TextTheme text) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: scheme.primary),
          const SizedBox(height: 18),
          Text(
            _loadingMessage,
            textAlign: TextAlign.center,
            style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'Hệ thống đang chuẩn bị nhân vật, bối cảnh và câu mở đầu...',
            textAlign: TextAlign.center,
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  /// Tab 1: Nhập vai theo yêu cầu (Custom Scenario)
  Widget _buildCustomRoleplayTab(ColorScheme scheme, TextTheme text) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bạn muốn luyện tập tình huống nào?',
            style: text.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _customTopicCtrl,
            decoration: InputDecoration(
              hintText: 'Ví dụ: Đi khám răng, Đổi vé máy bay, Phỏng vấn visa...',
              prefixIcon: const Icon(Icons.edit_note_rounded),
              suffixIcon: _customTopicCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => setState(() => _customTopicCtrl.clear()),
                    )
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              filled: true,
              fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),

          // Gợi ý nhanh 1 chạm
          Text(
            'Hoặc chọn nhanh gợi ý phổ biến:',
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestedScenarios.map((suggestion) {
              return ActionChip(
                label: Text(suggestion, style: const TextStyle(fontSize: 12)),
                backgroundColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                onPressed: () {
                  setState(() {
                    _customTopicCtrl.text = suggestion
                        .replaceFirst(RegExp(r'^[^\w\s]+\s*'), '')
                        .trim();
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Nút tạo kịch bản
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _startCustomRoleplay,
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text(
                'Khởi tạo Kịch bản & Bắt đầu Chat',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Tab 2: Tám chuyện tự do (Free Talk)
  Widget _buildFreeTalkTab(ColorScheme scheme, TextTheme text) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chọn người bạn đồng hành AI:',
            style: text.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Column(
            children: _personas.asMap().entries.map((entry) {
              final index = entry.key;
              final p = entry.value;
              final isSelected = _selectedPersonaIndex == index;

              return InkWell(
                onTap: () => setState(() => _selectedPersonaIndex = index),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? scheme.primary.withValues(alpha: 0.1)
                        : scheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? scheme.primary
                          : scheme.outlineVariant.withValues(alpha: 0.3),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(p['emoji'] ?? '💬', style: const TextStyle(fontSize: 22)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p['name'] ?? '',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isSelected ? scheme.primary : null,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              p['desc'] ?? '',
                              style: text.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Radio<int>(
                        value: index,
                        groupValue: _selectedPersonaIndex,
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedPersonaIndex = val);
                        },
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),

          Text(
            'Chủ đề muốn đàm đạo (tùy chọn):',
            style: text.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _freeTopicCtrl,
            decoration: InputDecoration(
              hintText: 'Để trống để bạn chat tự bắt chuyện...',
              prefixIcon: const Icon(Icons.topic_outlined),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              filled: true,
              fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: 8),

          // Gợi ý chủ đề nhanh
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: _suggestedFreeTopics.map((topic) {
              return ActionChip(
                label: Text(topic, style: const TextStyle(fontSize: 11)),
                backgroundColor: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                onPressed: () => setState(() => _freeTopicCtrl.text = topic),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Nút bắt đầu đàm thoại
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _startFreeTalk,
              icon: const Icon(Icons.chat_rounded),
              label: const Text(
                'Bắt đầu Tám chuyện ngay',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
