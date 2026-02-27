import 'package:flutter/material.dart';
import 'package:splitease_test/core/theme/app_theme.dart';
import 'package:splitease_test/shared/widgets/app_button.dart';

class AddFriendsTab extends StatefulWidget {
  const AddFriendsTab({super.key});

  @override
  State<AddFriendsTab> createState() => _AddFriendsTabState();
}

class _AddFriendsTabState extends State<AddFriendsTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _addFriend() {
    // Basic mock implementation for adding friends
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Friend added successfully!'),
        backgroundColor: AppColors.primary,
      ),
    );
    _nameController.clear();
    _phoneController.clear();
    _emailController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBg : AppColors.lightBg;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final subColor = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;
    final surfaceColor = isDark
        ? AppColors.darkSurface
        : AppColors.lightSurface;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Add Friends',
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: subColor,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          tabs: const [
            Tab(text: 'Phone'),
            Tab(text: 'Email'),
            Tab(text: 'Name (Offline)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Phone Tab
          _buildInputTab(
            context: context,
            surfaceColor: surfaceColor,
            textColor: textColor,
            subColor: subColor,
            isDark: isDark,
            icon: Icons.phone_rounded,
            title: 'Add by Phone Number',
            controller: _phoneController,
            hintText: '+91 98765 43210',
            keyboardType: TextInputType.phone,
          ),

          // 2. Email Tab
          _buildInputTab(
            context: context,
            surfaceColor: surfaceColor,
            textColor: textColor,
            subColor: subColor,
            isDark: isDark,
            icon: Icons.email_rounded,
            title: 'Add by Email Address',
            controller: _emailController,
            hintText: 'john@example.com',
            keyboardType: TextInputType.emailAddress,
          ),

          // 3. Manual Name (Offline member) Tab
          _buildInputTab(
            context: context,
            surfaceColor: surfaceColor,
            textColor: textColor,
            subColor: subColor,
            isDark: isDark,
            icon: Icons.person_add_rounded,
            title: 'Add Offline Member',
            controller: _nameController,
            hintText: 'Full Name',
            keyboardType: TextInputType.name,
          ),
        ],
      ),
    );
  }

  Widget _buildInputTab({
    required BuildContext context,
    required Color surfaceColor,
    required Color textColor,
    required Color subColor,
    required bool isDark,
    required IconData icon,
    required String title,
    required TextEditingController controller,
    required String hintText,
    required TextInputType keyboardType,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark
                    ? AppColors.darkSurfaceVariant
                    : AppColors.lightSurfaceVariant,
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 32),
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'They will receive a notification to join SplitEase once you add them to your groups.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: subColor, fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkBg : AppColors.lightBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkSurfaceVariant
                          : AppColors.lightSurfaceVariant,
                    ),
                  ),
                  child: TextField(
                    controller: controller,
                    keyboardType: keyboardType,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: hintText,
                      hintStyle: TextStyle(color: subColor),
                      border: InputBorder.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),
          AppButton(
            label: 'Add Friend',
            icon: Icons.person_add_rounded,
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                _addFriend();
              }
            },
          ),
        ],
      ),
    );
  }
}
