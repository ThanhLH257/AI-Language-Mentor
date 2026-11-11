import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../widgets/infinite_chat_modal.dart';
import 'diary_home_tab.dart';
import 'profile_tab.dart';
import 'roleplay_home_tab.dart';
import 'vocab_review_screen.dart';

/// Khung chính với thanh điều hướng 4 tab và nút Vô hạn (số 8 nằm ngang) ở chính giữa.
class MainLayoutScreen extends StatefulWidget {
  const MainLayoutScreen({super.key});

  @override
  State<MainLayoutScreen> createState() => _MainLayoutScreenState();
}

class _MainLayoutScreenState extends State<MainLayoutScreen> {
  // Chỉ số tab đang chọn (reactive)
  final _tabIndex = 0.obs;

  final List<Widget> _tabs = const [
    RoleplayHomeTab(),
    DiaryHomeTab(),
    VocabReviewScreen(),
    ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Obx(
      () => Scaffold(
        // AnimatedSwitcher làm mờ chuyển giữa các tab
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: KeyedSubtree(
            key: ValueKey(_tabIndex.value),
            child: _tabs[_tabIndex.value],
          ),
        ),
        // Nút Vô hạn (số 8 nằm ngang) nổi bật ở giữa thanh điều hướng
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: Container(
          width: 58,
          height: 58,
          margin: const EdgeInsets.only(top: 8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                scheme.primary,
                scheme.secondary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.4),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: IconButton(
            tooltip: 'Hội thoại Vô hạn (Tự chọn chủ đề)',
            icon: const Icon(
              Icons.all_inclusive_rounded, // Biểu tượng số 8 nằm ngang (vô hạn)
              color: Colors.white,
              size: 32,
            ),
            onPressed: () => InfiniteChatModal.show(context),
          ),
        ),
        bottomNavigationBar: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8,
          elevation: 8,
          height: 64,
          padding: EdgeInsets.zero,
          color: scheme.surface,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                icon: Icons.forum_outlined,
                selectedIcon: Icons.forum_rounded,
                label: 'Roleplay',
                scheme: scheme,
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.edit_note_outlined,
                selectedIcon: Icons.edit_note_rounded,
                label: 'Nhật ký',
                scheme: scheme,
              ),
              const SizedBox(width: 52), // Khoảng trống cân đối cho nút Vô hạn ở giữa
              _buildNavItem(
                index: 2,
                icon: Icons.bookmarks_outlined,
                selectedIcon: Icons.bookmarks_rounded,
                label: 'Từ vựng',
                scheme: scheme,
              ),
              _buildNavItem(
                index: 3,
                icon: Icons.person_outline_rounded,
                selectedIcon: Icons.person_rounded,
                label: 'Hồ sơ',
                scheme: scheme,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required ColorScheme scheme,
  }) {
    final isSelected = _tabIndex.value == index;
    final color = isSelected ? scheme.primary : scheme.onSurfaceVariant;

    return Expanded(
      child: InkWell(
        onTap: () => _tabIndex.value = index,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? selectedIcon : icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
