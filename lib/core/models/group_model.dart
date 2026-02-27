import 'package:splitease_test/core/models/member_model.dart';
import 'package:splitease_test/core/models/message_model.dart';
import 'package:splitease_test/core/models/expense_model.dart';

class GroupModel {
  final String id;
  final String name;
  final String category; // Used for icon emoji
  final String creatorId;
  final DateTime createdDate;
  final List<MemberModel> members;
  final List<ExpenseModel> expenses;
  final List<MessageModel> messages;

  const GroupModel({
    required this.id,
    required this.name,
    required this.category,
    required this.creatorId,
    required this.createdDate,
    required this.members,
    this.expenses = const [],
    this.messages = const [],
  });

  double get totalAmount => expenses.fold(0, (sum, e) => sum + e.amount);

  double get paidAmount =>
      members.where((m) => m.isPaid).fold(0, (sum, m) => sum + m.amountOwed);

  double get progressPercent =>
      totalAmount > 0 ? (paidAmount / totalAmount).clamp(0, 1) : 0;

  int get paidCount => members.where((m) => m.isPaid).length;
}
