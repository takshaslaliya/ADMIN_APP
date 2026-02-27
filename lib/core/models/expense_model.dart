class ExpenseModel {
  final String id;
  final String title;
  final double amount;
  final String paidById; // The user who paid the bill
  final DateTime date;
  final Map<String, double> splitAmong; // How it's split

  const ExpenseModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.paidById,
    required this.date,
    required this.splitAmong,
  });
}
