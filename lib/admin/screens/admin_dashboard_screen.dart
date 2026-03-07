import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitease_test/core/services/admin_service.dart';
import 'package:splitease_test/core/services/auth_service.dart';
import 'package:splitease_test/core/theme/app_theme.dart';
import 'package:http/http.dart' as http;
import 'package:splitease_test/core/config/app_config.dart';
import 'package:splitease_test/admin/widgets/admin_stat_card.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _currentIndex = 2; // Default to Dashboard (center)
  int _whatsappUsersCount = 0;
  int _totalUsersCount = 0;
  int _activeUsersCount = 0;
  int _inactiveUsersCount = 0;
  int _totalGroupsCount = 0;
  int _totalSplitsCount = 0;
  double _totalMoneyTracked = 0.0;
  List<Map<String, dynamic>> _topUsers = [];
  List<Map<String, dynamic>> _recentActivities = [];

  @override
  void initState() {
    super.initState();
    _fetchDashboardStats();
  }

  Future<void> _fetchDashboardStats() async {
    try {
      final res = await AdminService.fetchUsers(page: 1, limit: 1000);
      final waRes = await AdminService.fetchWhatsappSessions();

      if (!mounted) return;

      if (!res.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching users: ${res.message}'),
            backgroundColor: AppColors.error,
          ),
        );
      }

      setState(() {
        if (res.data is Map) {
          _totalUsersCount = res.data['total'] ?? 0;
          final usersData = res.data['users'] ?? res.data['data'] ?? [];
          if (usersData is List) {
            _processUsersData(usersData);
          }
        } else if (res.data is List) {
          final usersData = res.data as List;
          _totalUsersCount = usersData.length;
          _processUsersData(usersData);
        }

        if (waRes.success) {
          if (waRes.data is Map) {
            _whatsappUsersCount =
                waRes.data['total'] ??
                (waRes.data['data'] as List?)?.length ??
                0;
          } else if (waRes.data is List) {
            _whatsappUsersCount = (waRes.data as List).length;
          }
        }
      });
    } catch (e) {
      debugPrint('Dashboard stats error: $e');
    }
  }

  void _processUsersData(List<dynamic> users) {
    _activeUsersCount = 0;
    _inactiveUsersCount = 0;
    _totalGroupsCount = 0;
    _totalSplitsCount = 0;
    _totalMoneyTracked = 0.0;
    _topUsers = [];

    final List<Map<String, dynamic>> tempUsers = [];

    for (final u in users) {
      // Activity status
      final status = u['status']?.toString().toLowerCase() ?? 'active';
      final isActive = u['is_active'] != false;
      if (status == 'inactive' || !isActive) {
        _inactiveUsersCount++;
      } else {
        _activeUsersCount++;
      }

      // Financials/Activity
      final splits = int.tryParse(u['total_splits']?.toString() ?? '0') ?? 0;
      final groups = int.tryParse(u['total_groups']?.toString() ?? '0') ?? 0;
      final moneyOwned =
          double.tryParse(u['total_owned']?.toString() ?? '0') ?? 0.0;
      final moneyOwed =
          double.tryParse(u['total_owed']?.toString() ?? '0') ?? 0.0;

      _totalSplitsCount += splits;
      _totalGroupsCount += groups;
      _totalMoneyTracked += (moneyOwned + moneyOwed);

      tempUsers.add({
        'name': u['full_name']?.toString() ?? 'Unknown',
        'splits': splits,
        'id': u['id'].toString(),
        'created_at': u['created_at']?.toString() ?? '',
      });
    }

    // Sort for top users
    tempUsers.sort(
      (a, b) => (b['splits'] as int).compareTo(a['splits'] as int),
    );
    _topUsers = tempUsers.take(5).toList();

    // Scale proportionally if only partial page fetched
    if (_activeUsersCount + _inactiveUsersCount < _totalUsersCount &&
        users.isNotEmpty) {
      final ratio = _totalUsersCount / users.length;
      _activeUsersCount = (_activeUsersCount * ratio).round();
      _inactiveUsersCount = _totalUsersCount - _activeUsersCount;
      _totalSplitsCount = (_totalSplitsCount * ratio).round();
      _totalGroupsCount = (_totalGroupsCount * ratio).round();
      _totalMoneyTracked = _totalMoneyTracked * ratio;
    }

    // Recent Activities (simulated from user joins)
    _recentActivities = users
        .take(8)
        .map(
          (u) => {
            'type': 'join',
            'title': 'New User Joined',
            'subtitle': '${u['full_name']} joined the app',
            'time': u['created_at']?.toString() ?? 'Just now',
            'icon': Icons.person_add_rounded,
            'color': Colors.blue,
          },
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDark;
    final bgColor = isDark ? AppColors.adminBgDark : AppColors.adminBgLight;

    // List of screens for the navigation (5 items now)
    final screens = [
      _AdminUsersList(),
      _AdminWhatsAppList(),
      _buildMainDashboard(context, isDark), // Center item: Dashboard
      _AdminAlertsScreen(),
      _AdminSettingsScreen(),
    ];

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(color: bgColor),
            child: SafeArea(
              bottom: false,
              child: IndexedStack(index: _currentIndex, children: screens),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 24,
            child: _buildFloatingBottomNav(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityFeed(bool isDark, Color textColor) {
    if (_recentActivities.isEmpty) return const SizedBox();

    return Column(
      children: _recentActivities.map((act) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.adminSurfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (act['color'] as Color).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  act['icon'] as IconData,
                  color: act['color'] as Color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      act['title'],
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      act['subtitle'],
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Just now',
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.3),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTopUsersList(bool isDark, Color textColor) {
    if (_topUsers.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.adminSurfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: _topUsers.asMap().entries.map((entry) {
          final idx = entry.key;
          final user = entry.value;
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: Text(
                '${idx + 1}',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              user['name'],
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
            ),
            subtitle: Text('${user['splits']} splits created'),
            trailing: Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppColors.primary,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFloatingBottomNav(bool isDark) {
    final surfaceColor = isDark
        ? AppColors.adminSurfaceDark
        : AppColors.adminSurfaceLight;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
              blurRadius: 30,
              spreadRadius: 4,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.people_rounded, "Users"),
            _buildNavItem(1, Icons.message_rounded, "WhatsApp"),
            _buildNavItem(2, Icons.dashboard_rounded, "Home"),
            _buildNavItem(3, Icons.notifications_rounded, "Alerts"),
            _buildNavItem(4, Icons.settings_rounded, "Settings"),
          ],
        ),
      ),
    );
  }

  void _showUsageGraphSheet(
    String title,
    Color color,
    num value, {
    bool isCurrency = false,
  }) {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDark;
    final textColor = isDark ? Colors.white : AppColors.adminTextDark;
    final subColor = isDark ? Colors.white54 : AppColors.adminSubtextDark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (modalContext) => Container(
        height: MediaQuery.of(modalContext).size.height * 0.5,
        decoration: BoxDecoration(
          color: isDark ? AppColors.adminBgDark : AppColors.adminBgLight,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          border: Border.all(
            color: isDark
                ? AppColors.adminSurfaceVariantDark
                : AppColors.adminSurfaceVariantLight,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: Offset(0, -5),
            ),
          ],
        ),
        padding: EdgeInsets.fromLTRB(28, 32, 28, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$title Activity',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Live app interaction overview',
                      style: TextStyle(color: subColor, fontSize: 13),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'TOTAL NOW',
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: value.toDouble()),
                      duration: const Duration(seconds: 2),
                      builder: (context, animValue, child) => Text(
                        isCurrency
                            ? '₹${animValue.toStringAsFixed(0)}'
                            : '${animValue.toInt()}',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 40),
            Expanded(
              child: SizedBox(
                width: double.infinity,
                child: CustomPaint(painter: _AdminUsagePainter(color: color)),
              ),
            ),
            SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _usageSmallStat('Mon', '+12%', color),
                _usageSmallStat('Wed', '+24%', color),
                _usageSmallStat('Fri', '+18%', color),
                _usageSmallStat('Sun', '+32%', color),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _usageSmallStat(String day, String val, Color color) {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDark;
    return Column(
      children: [
        Text(
          day,
          style: TextStyle(
            color: isDark ? Colors.white38 : AppColors.adminSubtextDark,
            fontSize: 12,
          ),
        ),
        SizedBox(height: 4),
        Text(
          val,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final bool isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() => _currentIndex = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? AppColors.primary : AppColors.lightSubtext,
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMainDashboard(BuildContext context, bool isDark) {
    final textColor = isDark ? Colors.white : AppColors.adminTextDark;

    final totalUsers = _totalUsersCount.toDouble();
    final activeUsers = '$_activeUsersCount';
    final inactiveUsers = '$_inactiveUsersCount';

    // Premium gradient for the user card
    List<Color> cardGradient;
    if (_inactiveUsersCount > _activeUsersCount) {
      cardGradient = const [
        Color(0xFFEF4444),
        Color(0xFFDC2626),
        Color(0xFFB91C1C),
      ];
    } else {
      cardGradient = const [
        Color(0xFF3A6FF7),
        Color(0xFF5B5FFA),
        Color(0xFF7B61FF),
      ];
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top App Bar ──────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Image.asset(
                      'assets/images/app_logo.png',
                      width: 40,
                      height: 40,
                      fit: BoxFit.contain,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Admin Panel',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: Provider.of<ThemeProvider>(
                    context,
                    listen: false,
                  ).toggle,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.adminSurfaceDark
                          : AppColors.adminSurfaceLight,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.2 : 0.05,
                          ),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      isDark
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_rounded,
                      color: textColor,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 20),

          // ── Balance Card ─────────────────────────────
          GestureDetector(
            onTap: () {
              setState(() => _currentIndex = 0);
            },
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 28),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: cardGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Users',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        // Mini sparkline decoration
                        SizedBox(
                          width: 80,
                          height: 50,
                          child: CustomPaint(painter: _AdminSparklinePainter()),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween<double>(begin: 0, end: totalUsers),
                          duration: const Duration(milliseconds: 1500),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) {
                            final formattedValue = value
                                .toInt()
                                .toString()
                                .replaceAllMapped(
                                  RegExp(r'\B(?=(\d{3})+(?!\d))'),
                                  (Match m) => ',',
                                );
                            return Text(
                              formattedValue,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 40,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    Row(
                      children: [
                        _adminStat(
                          Icons.arrow_upward_rounded,
                          'Active',
                          activeUsers,
                          const Color(0xFF34D39A),
                          context,
                          isDark,
                        ),
                        SizedBox(width: 32),
                        // Divider
                        Container(width: 1, height: 30, color: Colors.white24),
                        SizedBox(width: 32),
                        _adminStat(
                          Icons.arrow_downward_rounded,
                          'Inactive',
                          inactiveUsers,
                          const Color(0xFFFB7185),
                          context,
                          isDark,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          SizedBox(height: 24),
          // ── Quick Actions ─────────────────────────────
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() => _currentIndex = 4);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [
                                Color.alphaBlend(
                                  AppColors.primary.withValues(alpha: 0.55),
                                  const Color(0xFF141722),
                                ),
                                Color.alphaBlend(
                                  AppColors.secondary.withValues(alpha: 0.25),
                                  const Color(0xFF0F1117),
                                ),
                              ]
                            : AppColors.primaryGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.security_rounded,
                            color: Colors.yellowAccent,
                            size: 24,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'System Integrity',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'All services operational',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24),

                // ── Dashboard Metrics Row ─────────────────
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showUsageGraphSheet(
                          'Groups',
                          Colors.orange,
                          _totalGroupsCount,
                        ),
                        behavior: HitTestBehavior.opaque,
                        child: AdminStatCard(
                          label: 'Groups',
                          value: _totalGroupsCount.toString(),
                          icon: Icons.group_work_rounded,
                          iconColor: Colors.orange,
                          iconBgColor: Colors.orange.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showUsageGraphSheet(
                          'Splits',
                          Colors.green,
                          _totalSplitsCount,
                        ),
                        behavior: HitTestBehavior.opaque,
                        child: AdminStatCard(
                          label: 'Splits',
                          value: _totalSplitsCount.toString(),
                          icon: Icons.receipt_long_rounded,
                          iconColor: Colors.green,
                          iconBgColor: Colors.green.withValues(alpha: 0.1),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                GestureDetector(
                  onTap: () => _showUsageGraphSheet(
                    'Total Money',
                    Colors.purple,
                    _totalMoneyTracked,
                    isCurrency: true,
                  ),
                  behavior: HitTestBehavior.opaque,
                  child: AdminStatCard(
                    label: 'Total Money Tracked Across Ecosystem',
                    value: '₹${_totalMoneyTracked.toStringAsFixed(0)}',
                    icon: Icons.account_balance_wallet_rounded,
                    iconColor: Colors.purple,
                    iconBgColor: Colors.purple.withValues(alpha: 0.1),
                  ),
                ),

                SizedBox(height: 32),

                // ── Charts Section ────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'User Growth',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Last 7 Days',
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.5),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Container(
                  height: 180,
                  width: double.infinity,
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.adminSurfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.2 : 0.05,
                        ),
                        blurRadius: 15,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: CustomPaint(
                    painter: _AdminUsagePainter(color: AppColors.primary),
                  ),
                ),

                SizedBox(height: 32),

                // ── Top Users ─────────────────────────────
                Text(
                  'Top Active Users',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 16),
                _buildTopUsersList(isDark, textColor),

                SizedBox(height: 32),

                // ── Recent Activity ───────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Activity Feed',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    TextButton(onPressed: () {}, child: Text('View All')),
                  ],
                ),
                SizedBox(height: 12),
                _buildActivityFeed(isDark, textColor),

                SizedBox(height: 120), // Bottom padding for nav bar
              ],
            ),
          ),

          SizedBox(height: 32),

          // ── Search Bar ────────────────────────────────
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 28),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.adminSurfaceDark
                    : AppColors.adminSurfaceLight,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: TextField(
                style: TextStyle(color: textColor, fontSize: 14),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  icon: Icon(
                    Icons.search,
                    color: AppColors.adminPrimary,
                    size: 20,
                  ),
                  hintText: 'Search Users or Reports',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white70 : AppColors.adminSubtextDark,
                    fontSize: 14,
                  ),
                  isDense: true,
                ),
              ),
            ),
          ),

          SizedBox(height: 24),

          // ── Activity Header ──────────────────────
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Activity',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() => _currentIndex = 0);
                  },
                  child: Text(
                    'See All',
                    style: TextStyle(
                      color: AppColors.adminPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16),
          // Stats Grid
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                GestureDetector(
                  onTap: () => _showUsageGraphSheet(
                    'Total Users',
                    AppColors.adminAccent,
                    _totalUsersCount,
                  ),
                  behavior: HitTestBehavior.opaque,
                  child: AdminStatCard(
                    label: 'Total Users',
                    value: '$_totalUsersCount',
                    icon: Icons.people_outline_rounded,
                    iconColor: AppColors.adminAccent,
                    iconBgColor: AppColors.adminAccent.withValues(alpha: 0.1),
                  ),
                ),
                GestureDetector(
                  onTap: () => _showUsageGraphSheet(
                    'Active Users',
                    AppColors.paid,
                    _activeUsersCount,
                  ),
                  behavior: HitTestBehavior.opaque,
                  child: AdminStatCard(
                    label: 'Active Users',
                    value: '$_activeUsersCount',
                    icon: Icons.person_add_alt_1_outlined,
                    iconColor: AppColors.paid,
                    iconBgColor: AppColors.paidBg,
                  ),
                ),
                GestureDetector(
                  onTap: () => _showUsageGraphSheet(
                    'Inactive Users',
                    AppColors.error,
                    _inactiveUsersCount,
                  ),
                  behavior: HitTestBehavior.opaque,
                  child: AdminStatCard(
                    label: 'Inactive Users',
                    value: '$_inactiveUsersCount',
                    icon: Icons.person_off_outlined,
                    iconColor: AppColors.error,
                    iconBgColor: AppColors.error.withValues(alpha: 0.1),
                  ),
                ),
                GestureDetector(
                  onTap: () => _showUsageGraphSheet(
                    'WhatsApp',
                    Color(0xFF25D366),
                    _whatsappUsersCount,
                  ),
                  behavior: HitTestBehavior.opaque,
                  child: AdminStatCard(
                    label: 'WhatsApp Users',
                    value: '$_whatsappUsersCount',
                    icon: Icons.message_outlined,
                    iconColor: Color(0xFF25D366),
                    iconBgColor: Color(0xFF25D366).withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 140),
        ],
      ),
    );
  }

  static Widget _adminStat(
    IconData icon,
    String label,
    String value,
    Color color,
    BuildContext context,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 14),
            SizedBox(width: 4),
            Text(label, style: TextStyle(color: Colors.white70, fontSize: 13)),
          ],
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _AdminWhatsAppList extends StatefulWidget {
  @override
  State<_AdminWhatsAppList> createState() => _AdminWhatsAppListState();
}

class _AdminWhatsAppListState extends State<_AdminWhatsAppList> {
  List<dynamic> _sessions = [];
  bool _isLoading = true;
  int _totalUsers = 0;

  @override
  void initState() {
    super.initState();
    _fetchSessions();
  }

  Future<void> _fetchSessions() async {
    setState(() => _isLoading = true);
    final res = await AdminService.fetchWhatsappSessions();
    final userRes = await AdminService.fetchUsers(limit: 1);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (res.success && res.data != null) {
          _sessions = res.data is List ? res.data : [];
        }
        if (userRes.success && userRes.data is Map) {
          _totalUsers = userRes.data['total'] ?? 0;
        }
      });
    }
  }

  void _sendReminder(String type) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Text('Preparing $type reminders...'),
        backgroundColor: const Color(0xFF25D366),
      ),
    );

    // Fetch users (limit 1000 for bulk action)
    final res = await AdminService.fetchUsers(page: 1, limit: 1000);
    if (!mounted || !res.success || res.data == null) return;

    final allUsers = (res.data is Map ? res.data['users'] : res.data) ?? [];
    List<String> userIds = [];
    String message = '';
    String title = '';

    if (type == 'Connection') {
      title = 'WhatsApp Connection';
      message =
          'Hi {name}, welcome to SplitEase! Your registered number is {mobile}. Why not connect WhatsApp for better tracking?';

      // Target users WITHOUT a session
      final connectedIds = _sessions
          .where((s) => s?['id'] != null)
          .map((s) => s['id'].toString())
          .toSet();
      userIds = allUsers
          .where(
            (u) =>
                u?['id'] != null && !connectedIds.contains(u['id'].toString()),
          )
          .map((u) => u['id'].toString())
          .toList();
    } else {
      title = 'Payment Reminder';
      message = 'Hey {name}, please check your pending splits on SplitEase.';

      // Target users who HAVE splits
      userIds = allUsers
          .where(
            (u) =>
                u?['id'] != null &&
                (int.tryParse(u['total_splits']?.toString() ?? '0') ?? 0) > 0,
          )
          .map((u) => u['id'].toString())
          .toList();
    }

    if (userIds.isEmpty) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('No matching users to notify.')),
      );
      return;
    }

    final notifyRes = await AdminService.sendBulkNotifications(
      userIds: userIds,
      title: title,
      message: message,
    );

    if (mounted) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(notifyRes.message),
          backgroundColor: notifyRes.success
              ? const Color(0xFF25D366)
              : AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final isDark = theme.isDark;
    final textColor = isDark ? Colors.white : AppColors.adminTextDark;
    final surfaceColor = isDark
        ? AppColors.adminSurfaceDark
        : AppColors.adminSurfaceLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'WhatsApp Hub',
                style: TextStyle(
                  color: textColor,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              IconButton(
                onPressed: _fetchSessions,
                icon: Icon(
                  Icons.refresh_rounded,
                  color: AppColors.adminPrimary,
                ),
              ),
            ],
          ),
        ),

        // --- WhatsApp Metrics ---
        if (!_isLoading)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                _whatsappStatCard(
                  'Total Users',
                  _totalUsers.toString(),
                  Colors.blue,
                  isDark,
                ),
                const SizedBox(width: 12),
                _whatsappStatCard(
                  'Connected',
                  _sessions.length.toString(),
                  const Color(0xFF25D366),
                  isDark,
                ),
                const SizedBox(width: 12),
                _whatsappStatCard(
                  'Rate %',
                  '${_totalUsers > 0 ? ((_sessions.length / _totalUsers) * 100).toInt() : 0}%',
                  Colors.orange,
                  isDark,
                ),
              ],
            ),
          ),

        // --- Quick Reminder Tools ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF25D366), Color(0xFF128C7E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF25D366).withValues(alpha: 0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Broadcast System',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _reminderAction(
                        'Connect WA',
                        Icons.chat_bubble_outline_rounded,
                        () => _sendReminder('Connection'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _reminderAction(
                        'Pay Reminders',
                        Icons.payment_rounded,
                        () => _sendReminder('Payment'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        Padding(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 12),
          child: Text(
            'Active Sessions',
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: AppColors.adminPrimary,
                  ),
                )
              : _sessions.isEmpty
              ? Center(
                  child: Text(
                    'No active sessions found',
                    style: TextStyle(color: textColor.withValues(alpha: 0.5)),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _sessions.length,
                  itemBuilder: (context, index) {
                    final dynamic user = _sessions[index];
                    final String name =
                        user['full_name']?.toString() ??
                        user['username']?.toString() ??
                        'Unknown User';
                    final String phone =
                        user['whatsapp_number']?.toString() ??
                        user['mobile_number']?.toString() ??
                        'No Number';
                    final String initials = name.isNotEmpty
                        ? name.substring(0, 1).toUpperCase()
                        : '?';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.15 : 0.05,
                            ),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: const Color(
                              0xFF25D366,
                            ).withValues(alpha: 0.1),
                            child: Text(
                              initials,
                              style: const TextStyle(
                                color: Color(0xFF25D366),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  phone,
                                  style: TextStyle(
                                    color: textColor.withValues(alpha: 0.6),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF25D366,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              user['role']?.toString().toUpperCase() ?? 'USER',
                              style: const TextStyle(
                                color: Color(0xFF25D366),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _whatsappStatCard(
    String label,
    String value,
    Color color,
    bool isDark,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.adminSurfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.1)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.white54 : AppColors.adminSubtextDark,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _reminderAction(String label, IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminAlertsScreen extends StatefulWidget {
  @override
  State<_AdminAlertsScreen> createState() => _AdminAlertsScreenState();
}

class _AdminAlertsScreenState extends State<_AdminAlertsScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  int _charCount = 0;
  bool _isSending = false;
  bool _isLoadingHistory = true;
  List<dynamic> _notifications = [];
  List<dynamic> _allUsers = [];
  List<String> _selectedUserIds = [];
  bool _isAllSelected = true;
  bool _isScheduled = false;
  DateTime? _scheduledTime;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(() {
      if (mounted) {
        setState(() {
          _charCount = _messageController.text.length;
        });
      }
    });
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoadingHistory = true);
    await Future.wait([_fetchNotifications(), _fetchUsers()]);
    if (mounted) setState(() => _isLoadingHistory = false);
  }

  Future<void> _fetchNotifications() async {
    final res = await AdminService.fetchAllNotifications();
    if (mounted && res.success && res.data != null) {
      setState(() {
        _notifications = res.data is List ? res.data : (res.data['data'] ?? []);
      });
    }
  }

  Future<void> _fetchUsers() async {
    final res = await AdminService.fetchUsers(page: 1, limit: 1000);
    if (mounted && res.success && res.data != null) {
      setState(() {
        _allUsers = res.data is List ? res.data : (res.data['users'] ?? []);
      });
    }
  }

  Future<void> _sendNotification() async {
    if (_titleController.text.isEmpty || _messageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both title and message')),
      );
      return;
    }

    if (!_isAllSelected && _selectedUserIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one user')),
      );
      return;
    }

    setState(() => _isSending = true);

    final List<String> targetUserIds = _isAllSelected
        ? _allUsers.map((u) => u['id'].toString()).toList()
        : _selectedUserIds;

    final res = await AdminService.sendBulkNotifications(
      userIds: targetUserIds,
      title: _titleController.text,
      message: _messageController.text,
      scheduledAt: _isScheduled ? _scheduledTime : null,
    );

    if (mounted) {
      setState(() => _isSending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isScheduled && res.success
                ? 'Message scheduled for ${_scheduledTime?.hour.toString().padLeft(2, '0')}:${_scheduledTime?.minute.toString().padLeft(2, '0')}'
                : res.message,
          ),
          backgroundColor: res.success
              ? AppColors.adminPrimary
              : AppColors.error,
        ),
      );
      if (res.success) {
        _titleController.clear();
        _messageController.clear();
        setState(() {
          _isScheduled = false;
          _scheduledTime = null;
        });
        _fetchNotifications();
      }
    }
  }

  void _addTag(String tag) {
    final text = _messageController.text;
    final selection = _messageController.selection;

    // If no focus/selection, just append to the end
    if (selection.start < 0) {
      _messageController.text = text + tag;
      return;
    }

    final newText = text.replaceRange(selection.start, selection.end, tag);
    _messageController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: selection.start + tag.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDark;
    final textColor = isDark ? Colors.white : AppColors.adminTextDark;
    final surfaceColor = isDark
        ? AppColors.adminSurfaceDark
        : AppColors.adminSurfaceLight;
    final accentColor = AppColors.adminAccent;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: AppColors.adminGradient),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              '⚡ System Alerts',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Push Communications',
            style: TextStyle(
              color: textColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // --- Composer Card ---
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title Field
                TextField(
                  controller: _titleController,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Notification Title',
                    hintStyle: TextStyle(
                      color: textColor.withValues(alpha: 0.3),
                      fontSize: 18,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
                const Divider(height: 32),

                // Target Selection
                Row(
                  children: [
                    Text(
                      'Target:',
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.6),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ChoiceChip(
                      label: const Text('All Users'),
                      selected: _isAllSelected,
                      onSelected: (v) => setState(() => _isAllSelected = v),
                      selectedColor: accentColor.withValues(alpha: 0.2),
                      labelStyle: TextStyle(
                        color: _isAllSelected
                            ? accentColor
                            : textColor.withValues(alpha: 0.6),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: Text(
                        _isAllSelected
                            ? 'Selective'
                            : '${_selectedUserIds.length} Selected',
                      ),
                      selected: !_isAllSelected,
                      onSelected: (v) {
                        setState(() => _isAllSelected = !v);
                        if (v) _showUserSelection();
                      },
                      selectedColor: accentColor.withValues(alpha: 0.2),
                      labelStyle: TextStyle(
                        color: !_isAllSelected
                            ? accentColor
                            : textColor.withValues(alpha: 0.6),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    _tagButton('{name}', () => _addTag('{name}')),
                    _tagButton('{mobile}', () => _addTag('{mobile}')),
                  ],
                ),
                const SizedBox(height: 16),

                // Message Field
                Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.03)
                        : AppColors.lightBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Stack(
                    children: [
                      TextField(
                        controller: _messageController,
                        maxLines: null,
                        expands: true,
                        style: TextStyle(color: textColor, fontSize: 15),
                        decoration: const InputDecoration(
                          hintText: 'Notification message body...',
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                          contentPadding: EdgeInsets.all(16),
                          border: InputBorder.none,
                        ),
                      ),
                      Positioned(
                        bottom: 12,
                        right: 16,
                        child: Text(
                          '$_charCount chars',
                          style: TextStyle(
                            color: Colors.grey.withValues(alpha: 0.5),
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Scheduling Toggle
                Row(
                  children: [
                    Switch(
                      value: _isScheduled,
                      activeThumbColor: accentColor,
                      onChanged: (v) {
                        setState(() => _isScheduled = v);
                        if (v) _selectScheduleTime();
                      },
                    ),
                    Text(
                      'Schedule for later',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_isScheduled && _scheduledTime != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '(${_scheduledTime!.hour.toString().padLeft(2, '0')}:${_scheduledTime!.minute.toString().padLeft(2, '0')})',
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),

                // Send Button
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: AppColors.adminGradient,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isSending ? null : _sendNotification,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shadowColor: Colors.transparent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _isScheduled
                                    ? Icons.calendar_today_rounded
                                    : Icons.send_rounded,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isScheduled
                                    ? 'Schedule Message'
                                    : 'Broadcast Message',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // --- History Header ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sent History',
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              IconButton(
                onPressed: _fetchNotifications,
                icon: Icon(Icons.refresh_rounded, color: accentColor, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // --- History List ---
          if (_isLoadingHistory)
            const Center(child: CircularProgressIndicator())
          else if (_notifications.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Text(
                  'No broadcast history',
                  style: TextStyle(color: textColor.withValues(alpha: 0.3)),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final n = _notifications[index];
                return _buildNotificationItem(
                  n,
                  isDark,
                  textColor,
                  surfaceColor,
                );
              },
            ),
        ],
      ),
    );
  }

  void _selectScheduleTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) {
      setState(() {
        final now = DateTime.now();
        var schedule = DateTime(
          now.year,
          now.month,
          now.day,
          time.hour,
          time.minute,
        );

        // If selected time has already passed today, assume it's for tomorrow
        if (schedule.isBefore(now)) {
          schedule = schedule.add(const Duration(days: 1));
        }

        _scheduledTime = schedule;
      });
    } else {
      setState(() => _isScheduled = false);
    }
  }

  void _showUserSelection() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _UserSelectionSheet(
        allUsers: _allUsers,
        initialSelected: _selectedUserIds,
        onDone: (selected) {
          setState(() {
            _selectedUserIds = selected;
            if (_selectedUserIds.isEmpty) _isAllSelected = true;
          });
        },
      ),
    );
  }

  Widget _buildNotificationItem(
    dynamic n,
    bool isDark,
    Color textColor,
    Color surfaceColor,
  ) {
    final title = n['title']?.toString() ?? 'No Title';
    final msg = n['message']?.toString() ?? 'No Message';
    final dateRaw = (n['scheduled_at'] ?? n['created_at'])?.toString() ?? '';
    final isRead = n['is_read'] == true;
    final userName = n['user_name']?.toString() ?? 'Multiple Users';

    bool isFuture = false;
    String dateStr = 'Recently';
    if (dateRaw.isNotEmpty) {
      try {
        final dt = DateTime.parse(dateRaw);
        isFuture = dt.isAfter(DateTime.now());
        dateStr =
            '${dt.day}/${dt.month} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isFuture ? Colors.orange : Colors.green).withValues(
                    alpha: 0.1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isFuture ? 'SCHEDULED' : 'SENT',
                  style: TextStyle(
                    color: isFuture ? Colors.orange : Colors.green,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                dateStr,
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.4),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              color: textColor,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            msg,
            style: TextStyle(
              color: textColor.withValues(alpha: 0.7),
              fontSize: 13,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.person_rounded,
                size: 12,
                color: AppColors.adminAccent,
              ),
              const SizedBox(width: 4),
              Text(
                userName,
                style: TextStyle(
                  color: AppColors.adminAccent,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (isRead)
                const Icon(Icons.done_all_rounded, size: 16, color: Colors.blue)
              else
                Icon(
                  Icons.done_rounded,
                  size: 16,
                  color: textColor.withValues(alpha: 0.3),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tagButton(String label, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.adminAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.adminAccent.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.adminAccent,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UserSelectionSheet extends StatefulWidget {
  final List<dynamic> allUsers;
  final List<String> initialSelected;
  final Function(List<String>) onDone;

  const _UserSelectionSheet({
    required this.allUsers,
    required this.initialSelected,
    required this.onDone,
  });

  @override
  State<_UserSelectionSheet> createState() => _UserSelectionSheetState();
}

class _UserSelectionSheetState extends State<_UserSelectionSheet> {
  late List<String> _selectedIds;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedIds = List.from(widget.initialSelected);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDark;
    final bgColor = isDark ? AppColors.adminBgDark : AppColors.adminBgLight;
    final surfaceColor = isDark
        ? AppColors.adminSurfaceDark
        : AppColors.adminSurfaceLight;
    final textColor = isDark ? Colors.white : AppColors.adminTextDark;

    final filteredUsers = widget.allUsers.where((u) {
      final name = u['full_name']?.toString().toLowerCase() ?? '';
      final email = u['email']?.toString().toLowerCase() ?? '';
      final mobile = u['mobile_number']?.toString().toLowerCase() ?? '';
      final q = _searchQuery.toLowerCase();
      return name.contains(q) || email.contains(q) || mobile.contains(q);
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Select Recipients',
                style: TextStyle(
                  color: textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              TextButton(
                onPressed: () {
                  widget.onDone(_selectedIds);
                  Navigator.pop(context);
                },
                child: const Text(
                  'Done',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            style: TextStyle(color: textColor),
            decoration: InputDecoration(
              hintText: 'Search by name or mobile...',
              prefixIcon: Icon(
                Icons.search_rounded,
                color: textColor.withValues(alpha: 0.3),
              ),
              filled: true,
              fillColor: surfaceColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: filteredUsers.length,
              itemBuilder: (context, index) {
                final u = filteredUsers[index];
                final id = u['id'].toString();
                final isSelected = _selectedIds.contains(id);
                final name = u['full_name']?.toString() ?? 'Unknown';
                final n = name.isNotEmpty
                    ? name.substring(0, 1).toUpperCase()
                    : '?';

                return ListTile(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedIds.remove(id);
                      } else {
                        _selectedIds.add(id);
                      }
                    });
                  },
                  leading: CircleAvatar(
                    backgroundColor: AppColors.adminAccent.withValues(
                      alpha: 0.1,
                    ),
                    child: Text(
                      n,
                      style: TextStyle(
                        color: AppColors.adminAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    name,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    u['mobile_number']?.toString() ?? 'No Mobile',
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                  trailing: Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_off_rounded,
                    color: isSelected
                        ? AppColors.adminAccent
                        : textColor.withValues(alpha: 0.2),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminSettingsScreen extends StatefulWidget {
  @override
  State<_AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<_AdminSettingsScreen> {
  bool _isChecking = false;
  final List<Map<String, dynamic>> _apiStats = [
    {
      'name': 'Authentication API',
      'url': AppConfig.authUrl,
      'status': 'Checking...',
      'latency': '--',
      'icon': Icons.lock_outline_rounded,
    },
    {
      'name': 'Admin Services',
      'url': AppConfig.adminUrl,
      'status': 'Checking...',
      'latency': '--',
      'icon': Icons.admin_panel_settings_outlined,
    },
    {
      'name': 'User Profiles',
      'url': AppConfig.userUrl,
      'status': 'Checking...',
      'latency': '--',
      'icon': Icons.person_outline_rounded,
    },
    {
      'name': 'Groups Engine',
      'url': AppConfig.groupsUrl,
      'status': 'Checking...',
      'latency': '--',
      'icon': Icons.group_outlined,
    },
    {
      'name': 'WhatsApp Service',
      'url': AppConfig.whatsappUrl,
      'status': 'Checking...',
      'latency': '--',
      'icon': Icons.message_rounded,
    },
    {
      'name': 'Achievements System',
      'url': AppConfig.achievementsUrl,
      'status': 'Checking...',
      'latency': '--',
      'icon': Icons.emoji_events_outlined,
    },
    {
      'name': 'Broadcast Engine',
      'url': '${AppConfig.adminUrl}/notifications',
      'status': 'Checking...',
      'latency': '--',
      'icon': Icons.campaign_outlined,
    },
  ];

  @override
  void initState() {
    super.initState();
    _checkAllApis();
  }

  Future<void> _checkAllApis() async {
    if (_isChecking) return;
    setState(() => _isChecking = true);

    for (int i = 0; i < _apiStats.length; i++) {
      final stopwatch = Stopwatch()..start();
      try {
        final response = await http
            .get(Uri.parse(_apiStats[i]['url']))
            .timeout(const Duration(seconds: 5));
        stopwatch.stop();

        if (mounted) {
          setState(() {
            _apiStats[i]['status'] = response.statusCode < 500
                ? 'Healthy'
                : 'Error';
            _apiStats[i]['latency'] = '${stopwatch.elapsedMilliseconds}ms';
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _apiStats[i]['status'] = 'Offline';
            _apiStats[i]['latency'] = '--';
          });
        }
      }
    }

    if (mounted) setState(() => _isChecking = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDark;
    final textColor = isDark ? Colors.white : AppColors.adminTextDark;
    final surfaceColor = isDark
        ? AppColors.adminSurfaceDark
        : AppColors.adminSurfaceLight;

    final apis = _apiStats;

    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'System Settings',
                style: TextStyle(
                  color: textColor,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Color(0xFF22C55E).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF22C55E),
                      size: 14,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'All Systems Live',
                      style: TextStyle(
                        color: Color(0xFF22C55E),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          Text(
            'API HEALTH MONITOR',
            style: TextStyle(
              color: textColor.withValues(alpha: 0.5),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: apis.length,
            itemBuilder: (context, index) {
              final api = apis[index];
              return Container(
                margin: EdgeInsets.only(bottom: 12),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.15 : 0.05,
                      ),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color:
                            (api['icon'] as IconData == Icons.message_rounded
                                    ? Color(0xFF25D366)
                                    : AppColors.adminAccent)
                                .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        api['icon'] as IconData,
                        size: 20,
                        color: api['icon'] as IconData == Icons.message_rounded
                            ? Color(0xFF25D366)
                            : AppColors.adminAccent,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            api['name'] as String,
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Latency: ${api['latency']}',
                            style: TextStyle(
                              color: textColor.withValues(alpha: 0.5),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          api['status'] as String,
                          style: TextStyle(
                            color: api['status'] == 'Healthy'
                                ? const Color(0xFF22C55E)
                                : api['status'] == 'Offline'
                                ? AppColors.error
                                : AppColors.secondary,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color:
                                (api['status'] == 'Healthy'
                                        ? const Color(0xFF22C55E)
                                        : AppColors.error)
                                    .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              width: api['status'] == 'Healthy' ? 32 : 8,
                              height: 4,
                              decoration: BoxDecoration(
                                color: api['status'] == 'Healthy'
                                    ? const Color(0xFF22C55E)
                                    : AppColors.error,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          SizedBox(height: 30),
          // Additional Settings placeholder
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, color: AppColors.adminAccent),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'More administrative controls and configuration options will be available here soon.',
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.7),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 32),

          GestureDetector(
            onTap: () async {
              await AuthService.logout();
              if (!context.mounted) return;
              Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false);
            },
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF6B6B), Color(0xFFEF4444)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFFEF4444).withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout_rounded, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Logout',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 100),
        ],
      ),
    );
  }
}

class _AdminSparklinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final points = [
      Offset(0, size.height * 0.8),
      Offset(size.width * 0.2, size.height * 0.6),
      Offset(size.width * 0.4, size.height * 0.7),
      Offset(size.width * 0.6, size.height * 0.3),
      Offset(size.width * 0.8, size.height * 0.2),
      Offset(size.width, size.height * 0.1),
    ];

    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AdminUsagePainter extends CustomPainter {
  final Color color;
  _AdminUsagePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final points = [
      Offset(0, size.height * 0.7),
      Offset(size.width * 0.15, size.height * 0.65),
      Offset(size.width * 0.3, size.height * 0.8),
      Offset(size.width * 0.45, size.height * 0.4),
      Offset(size.width * 0.6, size.height * 0.55),
      Offset(size.width * 0.8, size.height * 0.2),
      Offset(size.width, size.height * 0.35),
    ];

    final path = Path()..moveTo(points[0].dx, points[0].dy);
    final fillPath = Path()..moveTo(points[0].dx, points[0].dy);

    for (int i = 1; i < points.length; i++) {
      final xc = (points[i - 1].dx + points[i].dx) / 2;
      final yc = (points[i - 1].dy + points[i].dy) / 2;
      path.quadraticBezierTo(points[i - 1].dx, points[i - 1].dy, xc, yc);
      fillPath.quadraticBezierTo(points[i - 1].dx, points[i - 1].dy, xc, yc);
    }
    path.lineTo(points.last.dx, points.last.dy);
    fillPath.lineTo(points.last.dx, points.last.dy);

    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    final dotPaint = Paint()..color = color;
    canvas.drawCircle(points.last, 4, dotPaint);
    canvas.drawCircle(
      points.last,
      8,
      Paint()..color = color.withValues(alpha: 0.2),
    );
  }

  @override
  bool shouldRepaint(covariant _AdminUsagePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _AdminUsersList extends StatefulWidget {
  @override
  State<_AdminUsersList> createState() => _AdminUsersListState();
}

class _AdminUsersListState extends State<_AdminUsersList> {
  String _searchQuery = '';
  List<dynamic> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoading = true);
    final res = await AdminService.fetchUsers();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (res.success && res.data != null) {
          _users = (res.data is Map ? res.data['users'] : res.data) ?? [];
        } else {
          _users = [];
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDark;
    final textColor = isDark ? Colors.white : AppColors.adminTextDark;
    final subColor = isDark ? Colors.white70 : AppColors.adminSubtextDark;
    final surfaceColor = isDark
        ? AppColors.adminSurfaceDark
        : AppColors.adminSurfaceLight;
    final accentColor = AppColors.adminAccent;

    List<dynamic> filteredUsers = [];
    try {
      filteredUsers = _users.where((user) {
        if (user == null) return false;
        final name =
            (user['full_name']?.toString() ??
                    user['username']?.toString() ??
                    '')
                .toLowerCase();
        final email =
            (user['email']?.toString() ??
                    user['email_or_mobile']?.toString() ??
                    user['mobile_number']?.toString() ??
                    '')
                .toLowerCase();
        final query = _searchQuery.toLowerCase();
        return name.contains(query) || email.contains(query);
      }).toList();
    } catch (_) {
      filteredUsers = [];
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: AppColors.adminGradient),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '⚡ App Users',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'User Management',
            style: TextStyle(
              color: textColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          // Search Bar
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              style: TextStyle(color: textColor, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
                hintStyle: TextStyle(color: subColor, fontSize: 14),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                icon: Icon(Icons.search_rounded, color: accentColor, size: 20),
              ),
            ),
          ),
          SizedBox(height: 24),
          // User List
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(color: AppColors.adminPrimary),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredUsers.length,
              itemBuilder: (context, index) {
                if (index >= filteredUsers.length) return SizedBox();

                final dynamic user = filteredUsers[index];
                if (user == null) return SizedBox();

                String name = 'User';
                String email = 'No Email';
                String initials = '??';
                String totalSplits = '0';
                bool isAdmin = false;

                try {
                  name = user['full_name']?.toString() ?? 'User';
                  if (name.isEmpty) {
                    name = user['username']?.toString() ?? 'User';
                  }
                  email = user['email']?.toString() ?? 'No Email';

                  final n = name.trim();
                  initials = n.isNotEmpty
                      ? n.substring(0, 1).toUpperCase()
                      : '?';

                  totalSplits = user['total_splits']?.toString() ?? '0';
                  isAdmin = user['role']?.toString() == 'admin';
                } catch (_) {}

                return Container(
                  margin: EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.15 : 0.05,
                        ),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(12),
                    onTap: () => _showEditUserSheet(context, user),
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isAdmin
                              ? AppColors.adminGradient
                              : AppColors.adminGradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      name,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Text(
                      email,
                      style: TextStyle(color: subColor, fontSize: 12),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          totalSplits,
                          style: TextStyle(
                            color: accentColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'Splits',
                          style: TextStyle(color: subColor, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          SizedBox(height: 100),
        ],
      ),
    );
  }

  void _showUserNotificationHistory(BuildContext context, dynamic user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _UserNotificationHistorySheet(user: user),
    );
  }

  void _showEditUserSheet(BuildContext context, dynamic user) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDark;

    final surfaceColor = isDark
        ? AppColors.adminSurfaceDark
        : AppColors.adminSurfaceLight;
    final textColor = isDark ? Colors.white : AppColors.adminTextDark;
    final subColor = isDark ? Colors.white70 : AppColors.adminSubtextDark;
    final accentColor = AppColors.adminAccent;

    final nameCtrl = TextEditingController(
      text: user['full_name']?.toString() ?? '',
    );
    final emailCtrl = TextEditingController(
      text: user['email']?.toString() ?? '',
    );
    final phoneCtrl = TextEditingController(
      text: user['mobile_number']?.toString() ?? '',
    );
    final passCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: subColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Edit Profile',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () =>
                          _showUserNotificationHistory(context, user),
                      icon: Icon(Icons.history_rounded, color: accentColor),
                      tooltip: 'View History',
                    ),
                    IconButton(
                      onPressed: () async {
                        final res = await AdminService.updateUserRole(
                          user['id'],
                          'admin',
                        );
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(res.message),
                            backgroundColor: res.success
                                ? AppColors.adminPrimary
                                : AppColors.error,
                          ),
                        );
                        if (res.success) {
                          Navigator.pop(context);
                          _fetchUsers();
                        }
                      },
                      icon: Icon(
                        Icons.admin_panel_settings,
                        color: AppColors.adminPrimary,
                      ),
                      tooltip: 'Make Admin',
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 20),
            _buildEditField('Full Name', nameCtrl, Icons.person_outline),
            SizedBox(height: 16),
            _buildEditField('Email Address', emailCtrl, Icons.email_outlined),
            SizedBox(height: 16),
            _buildEditField('Phone Number', phoneCtrl, Icons.phone_outlined),
            SizedBox(height: 16),
            _buildEditField(
              'New Password',
              passCtrl,
              Icons.lock_outline_rounded,
              isPassword: true,
            ),
            SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: AppColors.adminGradient),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ElevatedButton(
                      onPressed: () async {
                        final res = await AdminService.updateUser(user['id'], {
                          'full_name': nameCtrl.text.trim(),
                          'mobile_number': phoneCtrl.text.trim(),
                        });

                        if (passCtrl.text.isNotEmpty) {
                          await AdminService.resetUserPassword(
                            user['id'],
                            passCtrl.text,
                          );
                        }

                        if (!context.mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(res.message),
                            backgroundColor: res.success
                                ? accentColor
                                : AppColors.error,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        if (res.success) _fetchUsers();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Save Changes',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Container(
                  height: 54,
                  width: 54,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.5),
                    ),
                  ),
                  child: IconButton(
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete User?'),
                          content: const Text(
                            'Are you sure you want to delete this user?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.error,
                              ),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        final res = await AdminService.deleteUser(user['id']);
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(res.message),
                            backgroundColor: res.success
                                ? AppColors.adminPrimary
                                : AppColors.error,
                          ),
                        );
                        if (res.success) _fetchUsers();
                      }
                    },
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool isPassword = false,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDark;

    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subColor = isDark ? Colors.white70 : const Color(0xFF64748B);
    final fillColor = isDark ? AppColors.darkSurfaceVariant : Colors.white;
    final borderColor = isDark
        ? AppColors.darkSurfaceVariant
        : const Color(0xFFE2E8F0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: subColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          style: TextStyle(color: textColor, fontSize: 15),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: subColor, size: 20),
            filled: true,
            fillColor: fillColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class _UserNotificationHistorySheet extends StatefulWidget {
  final dynamic user;
  const _UserNotificationHistorySheet({required this.user});

  @override
  State<_UserNotificationHistorySheet> createState() =>
      _UserNotificationHistorySheetState();
}

class _UserNotificationHistorySheetState
    extends State<_UserNotificationHistorySheet> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    final res = await AdminService.fetchUserNotifications(
      widget.user['id'].toString(),
    );
    if (mounted) {
      setState(() {
        _notifications = res.data is List ? res.data : (res.data['data'] ?? []);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDark;
    final bgColor = isDark ? AppColors.adminBgDark : AppColors.adminBgLight;
    final textColor = isDark ? Colors.white : AppColors.adminTextDark;
    final surfaceColor = isDark
        ? AppColors.adminSurfaceDark
        : AppColors.adminSurfaceLight;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: textColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.adminAccent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.history_rounded,
                    color: AppColors.adminAccent,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Alert History',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Sent to ${widget.user['full_name'] ?? 'User'}',
                        style: TextStyle(
                          color: textColor.withValues(alpha: 0.5),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close_rounded,
                    color: textColor.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppColors.adminAccent,
                    ),
                  )
                : _notifications.isEmpty
                ? Center(
                    child: Text(
                      'No history available',
                      style: TextStyle(color: textColor.withValues(alpha: 0.4)),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final n = _notifications[index];
                      final isRead = n['is_read'] == true;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: surfaceColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    n['title'] ?? 'Title',
                                    style: TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (isRead)
                                  Icon(
                                    Icons.done_all_rounded,
                                    color: Colors.blue,
                                    size: 16,
                                  )
                                else
                                  Icon(
                                    Icons.done_rounded,
                                    color: textColor.withValues(alpha: 0.3),
                                    size: 16,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              n['message'] ?? '',
                              style: TextStyle(
                                color: textColor.withValues(alpha: 0.7),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _formatDate(n['created_at']),
                              style: TextStyle(
                                color: textColor.withValues(alpha: 0.4),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    try {
      final dt = DateTime.parse(date.toString());
      return '${dt.day}/${dt.month} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}
