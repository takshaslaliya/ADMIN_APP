import 'package:flutter/material.dart';
import 'package:splitease_test/core/models/dummy_data.dart';
import 'package:splitease_test/core/theme/app_theme.dart';

class GroupsTab extends StatelessWidget {
  const GroupsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final activeGroups = DummyData.groups
        .where((g) => g.paidAmount < g.totalAmount || g.totalAmount == 0)
        .toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        title: Text(
          'Your Groups',
          style: TextStyle(
            color: isDark ? AppColors.darkText : AppColors.lightText,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: activeGroups.isEmpty
          ? Center(
              child: Text(
                'No active groups',
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkSubtext
                      : AppColors.lightSubtext,
                  fontSize: 16,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              itemCount: activeGroups.length,
              itemBuilder: (context, index) {
                final group = activeGroups[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: InkWell(
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/details',
                      arguments: group,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurface
                            : AppColors.lightSurface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkSurfaceVariant
                              : AppColors.lightSurfaceVariant,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkBg
                                  : AppColors.lightBg,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Text(
                                _categoryEmoji(group.category),
                                style: const TextStyle(fontSize: 24),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  group.name,
                                  style: TextStyle(
                                    color: isDark
                                        ? AppColors.darkText
                                        : AppColors.lightText,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.group_rounded,
                                      size: 14,
                                      color: isDark
                                          ? AppColors.darkSubtext
                                          : AppColors.lightSubtext,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${group.members.length} members',
                                      style: TextStyle(
                                        color: isDark
                                            ? AppColors.darkSubtext
                                            : AppColors.lightSubtext,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₹${group.totalAmount.toStringAsFixed(0)}',
                                style: TextStyle(
                                  color: isDark
                                      ? AppColors.darkText
                                      : AppColors.lightText,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.pendingBg,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Pending',
                                  style: TextStyle(
                                    color: AppColors.pending,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  String _categoryEmoji(String cat) {
    switch (cat.toLowerCase()) {
      case 'travel':
        return '✈️';
      case 'food':
        return '🍽️';
      case 'bills':
        return '🏠';
      case 'entertainment':
        return '📺';
      default:
        return '💰';
    }
  }
}
