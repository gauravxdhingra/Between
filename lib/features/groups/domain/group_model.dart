class GroupExpensePreview {
  const GroupExpensePreview({
    required this.id,
    required this.title,
    required this.amount,
    required this.paidBy,
    required this.yourShare,
    required this.createdAt,
  });

  final String id;
  final String title;
  final double amount;
  final String paidBy;
  final double yourShare;
  final DateTime createdAt;
}

class GroupModel {
  const GroupModel({
    required this.id,
    required this.name,
    required this.emoji,
    required this.memberCount,
    required this.netBalance,
    required this.lastActivity,
    required this.inviteToken,
    this.members = const [],
    this.expenses = const [],
  });

  final String id;
  final String name;
  final String emoji;
  final int memberCount;
  final double netBalance;
  final DateTime lastActivity;
  final String inviteToken;
  final List<String> members;
  final List<GroupExpensePreview> expenses;

  GroupModel copyWith({
    String? id,
    String? name,
    String? emoji,
    int? memberCount,
    double? netBalance,
    DateTime? lastActivity,
    String? inviteToken,
    List<String>? members,
    List<GroupExpensePreview>? expenses,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      memberCount: memberCount ?? this.memberCount,
      netBalance: netBalance ?? this.netBalance,
      lastActivity: lastActivity ?? this.lastActivity,
      inviteToken: inviteToken ?? this.inviteToken,
      members: members ?? this.members,
      expenses: expenses ?? this.expenses,
    );
  }
}
