class MemberSplit {
  final String id;
  final String name;
  final double amount;
  final bool isPaid;

  const MemberSplit({
    required this.id,
    required this.name,
    required this.amount,
    this.isPaid = false,
  });
}

class ExpenseModel {
  final String id;
  final String title;
  final double amount;
  final String paidById;
  final DateTime date;
  final List<MemberSplit> splits;

  const ExpenseModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.paidById,
    required this.date,
    required this.splits,
  });

  // Helper for backward compatibility
  Map<String, double> get splitAmong => {
    for (var s in splits) s.name: s.amount,
  };
}
