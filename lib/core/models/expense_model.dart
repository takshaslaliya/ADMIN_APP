class MemberSplit {
  final String id;
  final String name;
  final double amount;
  final bool isPaid;
  final String? toId;
  final String? toName;
  final String? phoneNumber;

  const MemberSplit({
    required this.id,
    required this.name,
    required this.amount,
    this.isPaid = false,
    this.toId,
    this.toName,
    this.phoneNumber,
  });
}

class ExpenseModel {
  final String id;
  final String title;
  final double amount;
  final String paidById;
  final DateTime date;
  final List<MemberSplit> splits;
  final String splitType; // 'solo' or 'multiple'
  final int memberCount;
  final String? mainGroupName;

  const ExpenseModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.paidById,
    required this.date,
    required this.splits,
    this.splitType = 'solo',
    this.memberCount = 0,
    this.mainGroupName,
  });

  // Helper for backward compatibility
  Map<String, double> get splitAmong => {
    for (var s in splits) s.name: s.amount,
  };
}
