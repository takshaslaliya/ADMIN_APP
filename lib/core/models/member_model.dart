class MemberModel {
  final String id;
  final String name;
  final String avatarInitials;
  final double amountOwed;
  final bool isPaid;
  final String? phoneNumber;
  final bool isRegistered;
  final String? userId; // For registered members
  final double expenseAmount;
  final DateTime? joinedAt;

  const MemberModel({
    required this.id,
    required this.name,
    required this.avatarInitials,
    required this.amountOwed,
    required this.isPaid,
    this.phoneNumber,
    this.isRegistered = false,
    this.userId,
    this.expenseAmount = 0.0,
    this.joinedAt,
  });

  factory MemberModel.fromJson(Map<String, dynamic> json) {
    String name = json['name'] ?? 'Unknown';
    String initials = '?';
    if (name.trim().isNotEmpty) {
      initials = name.trim().substring(0, 1).toUpperCase();
    }
    return MemberModel(
      id: json['id'] as String,
      name: name,
      avatarInitials: initials,
      amountOwed: 0.0, // Should be computed dynamically per expense
      isPaid: true, // Default value until expense logic is applied
      phoneNumber: json['phone_number'] as String?,
      isRegistered: json['is_registered'] == true,
      userId: json['user_id'] as String?,
      expenseAmount: (json['expense_amount'] ?? 0.0) is int
          ? (json['expense_amount'] as int).toDouble()
          : (json['expense_amount'] ?? 0.0).toDouble(),
      joinedAt: json['joined_at'] != null
          ? DateTime.tryParse(json['joined_at'])
          : null,
    );
  }
}
