import 'package:splitease_test/core/models/member_model.dart';
import 'package:splitease_test/core/models/group_model.dart';
import 'package:splitease_test/core/models/expense_model.dart';
import 'package:splitease_test/core/models/user_model.dart';
import 'package:splitease_test/core/models/message_model.dart';

class DummyData {
  // ─── Users ───────────────────────────────────────────────────────────────
  static final List<UserModel> users = [
    UserModel(
      id: 'u0',
      fullName: 'Admin',
      username: 'admin',
      email: 'admin@splitease.app',
      mobileNumber: '+91 00000 00000',
      role: 'admin',
      emailVerified: true,
      createdAt: DateTime(2024, 1, 1),
      totalSplits: 42,
    ),
    UserModel(
      id: 'u1',
      fullName: 'Dharmik Patel',
      username: 'dharmik',
      email: 'dharmik@example.com',
      mobileNumber: '+91 98765 43210',
      role: 'user',
      emailVerified: true,
      createdAt: DateTime(2024, 3, 15),
      totalSplits: 12,
    ),
    UserModel(
      id: 'u2',
      fullName: 'Riya Shah',
      username: 'riya',
      email: 'riya@example.com',
      mobileNumber: '+91 88888 77777',
      role: 'user',
      emailVerified: true,
      createdAt: DateTime(2024, 4, 20),
      totalSplits: 8,
    ),
    UserModel(
      id: 'u3',
      fullName: 'Arjun Mehta',
      username: 'arjun',
      email: 'arjun@example.com',
      mobileNumber: '+91 77777 66666',
      role: 'user',
      emailVerified: true,
      createdAt: DateTime(2024, 5, 10),
      totalSplits: 15,
    ),
    UserModel(
      id: 'u4',
      fullName: 'Priya Nair',
      username: 'priya',
      email: 'priya@example.com',
      mobileNumber: '+91 66666 55555',
      role: 'user',
      emailVerified: true,
      createdAt: DateTime(2024, 6, 5),
      totalSplits: 6,
      isActive: true,
      isUsingWhatsApp: false,
    ),
  ];

  static UserModel get currentUser => users[1];

  // ─── Groups ──────────────────────────────────────────────────────────────
  static final List<GroupModel> groups = [
    GroupModel(
      id: 'g1',
      name: 'Goa Trip 🏖️',
      creatorId: 'u1',
      createdDate: DateTime(2026, 2, 20),
      members: [
        const MemberModel(
          id: 'm1',
          name: 'Dharmik Patel',
          avatarInitials: 'DP',
          amountOwed: 3125,
          isPaid: true,
        ),
        const MemberModel(
          id: 'm2',
          name: 'Riya Shah',
          avatarInitials: 'RS',
          amountOwed: 3125,
          isPaid: false,
        ),
        const MemberModel(
          id: 'm3',
          name: 'Arjun Mehta',
          avatarInitials: 'AM',
          amountOwed: 3125,
          isPaid: false,
        ),
        const MemberModel(
          id: 'm4',
          name: 'Priya Nair',
          avatarInitials: 'PN',
          amountOwed: 3125,
          isPaid: true,
        ),
      ],
      expenses: [
        ExpenseModel(
          id: 'e1',
          title: 'Hotel Booking',
          amount: 10000,
          paidById: 'u1',
          date: DateTime(2026, 2, 20),
          splits: [
            MemberSplit(id: 'm1', name: 'Dharmik P.', amount: 2500),
            MemberSplit(id: 'm2', name: 'Taksh L.', amount: 2500),
            MemberSplit(id: 'm3', name: 'Rahul S.', amount: 2500),
            MemberSplit(id: 'm4', name: 'Priya N.', amount: 2500),
          ],
        ),
        ExpenseModel(
          id: 'e2',
          title: 'Cab to Airport',
          amount: 2500,
          paidById: 'u1',
          date: DateTime(2026, 2, 20),
          splits: [
            MemberSplit(id: 'm1', name: 'Dharmik P.', amount: 625),
            MemberSplit(id: 'm2', name: 'Taksh L.', amount: 625),
            MemberSplit(id: 'm3', name: 'Rahul S.', amount: 625),
            MemberSplit(id: 'm4', name: 'Priya N.', amount: 625),
          ],
        ),
      ],
      messages: [
        MessageModel(
          id: 'msg1',
          senderId: 'u1',
          text: 'Hey everyone, I have added the Goa trip expenses!',
          time: DateTime(2026, 2, 20, 10, 0),
        ),
        MessageModel(
          id: 'msg2',
          senderId: 'system',
          text: 'Dharmik Patel marked ₹3,125 as paid.',
          time: DateTime(2026, 2, 20, 10, 30),
          isSystem: true,
        ),
      ],
    ),
    GroupModel(
      id: 'g2',
      name: 'Flatmates 🏠',
      creatorId: 'u2',
      createdDate: DateTime(2026, 2, 1),
      members: [
        const MemberModel(
          id: 'm8',
          name: 'Dharmik Patel',
          avatarInitials: 'DP',
          amountOwed: 6000,
          isPaid: false,
        ),
        const MemberModel(
          id: 'm9',
          name: 'Riya Shah',
          avatarInitials: 'RS',
          amountOwed: 6000,
          isPaid: true,
        ),
        const MemberModel(
          id: 'm10',
          name: 'Priya Nair',
          avatarInitials: 'PN',
          amountOwed: 6000,
          isPaid: false,
        ),
      ],
      expenses: [
        ExpenseModel(
          id: 'e3',
          title: 'Monthly Rent',
          amount: 18000,
          paidById: 'u2',
          date: DateTime(2026, 2, 1),
          splits: [
            MemberSplit(id: 'm5', name: 'Amit G.', amount: 1000),
            MemberSplit(id: 'm6', name: 'Sagar V.', amount: 1000),
            MemberSplit(id: 'm7', name: 'Ravi K.', amount: 1000),
          ],
        ),
      ],
    ),
  ];

  static List<ExpenseModel> get allExpenses =>
      groups.expand((g) => g.expenses).toList();

  static const List<String> participantSuggestions = [
    'Riya Shah',
    'Arjun Mehta',
    'Priya Nair',
    'Karan Desai',
    'Sneha Joshi',
    'Vivek Rao',
    'Meera Pillai',
  ];

  static double get totalBalance => 24350;
  static double get youOwe => 12000;
  static double get youGet => 6250;

  static int get totalUsers => users.length;
  static int get activeUsersCount => users.where((u) => u.isActive).length;
  static int get inactiveUsersCount => users.where((u) => !u.isActive).length;
  static int get whatsappUsersCount =>
      users.where((u) => u.isUsingWhatsApp).length;

  static int get activeSplits => groups.length;
  static double get totalSettled =>
      groups.fold(0, (sum, g) => sum + g.paidAmount);
  static double get totalPending =>
      groups.fold(0, (sum, g) => sum + (g.totalAmount - g.paidAmount));

  static const List<Map<String, dynamic>> monthlyData = [
    {'month': 'Sep', 'amount': 15200.0},
    {'month': 'Oct', 'amount': 22800.0},
    {'month': 'Nov', 'amount': 18400.0},
    {'month': 'Dec', 'amount': 35600.0},
    {'month': 'Jan', 'amount': 28900.0},
    {'month': 'Feb', 'amount': 41200.0},
  ];

  static const List<Map<String, String>> recentActivity = [
    {
      'user': 'Dharmik Patel',
      'action': 'Created group "Goa Trip"',
      'time': '2h ago',
      'icon': '✈️',
    },
    {
      'user': 'Riya Shah',
      'action': 'Paid "Hotel Booking"',
      'time': '4h ago',
      'icon': '✅',
    },
    {
      'user': 'Arjun Mehta',
      'action': 'Joined "Flatmates"',
      'time': '6h ago',
      'icon': '📺',
    },
  ];
}
