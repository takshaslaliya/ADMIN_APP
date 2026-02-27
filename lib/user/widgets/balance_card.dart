import 'package:flutter/material.dart';
import 'package:splitease_test/core/theme/app_theme.dart';

class BalanceCard extends StatelessWidget {
  final double totalBalance;
  final double youOwe;
  final double youGet;

  const BalanceCard({
    super.key,
    required this.totalBalance,
    required this.youOwe,
    required this.youGet,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1D4ED8), Color(0xFF2563EB), Color(0xFF3B82F6)],
        ),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Balance',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '₹${_format(totalBalance)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _statColumn(
                  label: 'You Owe',
                  amount: youOwe,
                  color: const Color(0xFFFF8A8A),
                  icon: Icons.arrow_upward_rounded,
                ),
              ),
              Container(width: 1, height: 40, color: Colors.white24),
              Expanded(
                child: _statColumn(
                  label: 'You Get',
                  amount: youGet,
                  color: const Color(0xFF86EFAC),
                  icon: Icons.arrow_downward_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  (youGet - youOwe) >= 0
                      ? Icons.check_circle_outline_rounded
                      : Icons.info_outline_rounded,
                  color: Colors.white,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  (youGet - youOwe) >= 0
                      ? 'You are in credit by ₹${_format(youGet - youOwe)}'
                      : 'You owe overall ₹${_format(youOwe - youGet)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statColumn({
    required String label,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '₹${_format(amount)}',
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  String _format(double val) {
    if (val >= 1000) {
      return '${(val / 1000).toStringAsFixed(val % 1000 == 0 ? 0 : 1)}K';
    }
    return val.toStringAsFixed(0);
  }
}
