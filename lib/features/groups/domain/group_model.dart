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

class GroupMember {
  const GroupMember({required this.id, required this.name, this.avatarUrl});

  final String id;
  final String name;
  final String? avatarUrl;

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      id: json['id'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }
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
    this.memberObjects = const [],
    this.expenses = const [],
  });

  final String id;
  final String name;
  final String emoji;
  final int memberCount;
  final double netBalance;
  final DateTime lastActivity;
  final String inviteToken;
  // Legacy: list of display names used throughout UI
  final List<String> members;
  // Rich member objects from API
  final List<GroupMember> memberObjects;
  final List<GroupExpensePreview> expenses;

  factory GroupModel.fromJson(Map<String, dynamic> json, String currentUserId) {
    final memberObjects = (json['members'] as List<dynamic>? ?? [])
        .map((m) => GroupMember.fromJson(
            (m['user'] ?? m) as Map<String, dynamic>))
        .toList();

    final members = memberObjects.map((m) {
      return m.id == currentUserId ? 'You' : m.name;
    }).toList();

    final token = json['inviteToken'] != null
        ? (json['inviteToken']['token'] as String? ?? '')
        : '';

    return GroupModel(
      id: json['id'] as String,
      name: json['name'] as String,
      emoji: json['emoji'] as String? ?? '🏠',
      memberCount: memberObjects.length,
      netBalance: 0, // computed client-side from expenses + settlements
      lastActivity: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      inviteToken: token,
      members: members,
      memberObjects: memberObjects,
      expenses: const [],
    );
  }

  GroupModel copyWith({
    String? id,
    String? name,
    String? emoji,
    int? memberCount,
    double? netBalance,
    DateTime? lastActivity,
    String? inviteToken,
    List<String>? members,
    List<GroupMember>? memberObjects,
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
      memberObjects: memberObjects ?? this.memberObjects,
      expenses: expenses ?? this.expenses,
    );
  }
}
