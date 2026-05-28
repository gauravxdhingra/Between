class SplitEntry {
  const SplitEntry({
    required this.member,
    required this.amount,
    this.isSettled = false,
  });

  final String member;
  final double amount;
  final bool isSettled;

  SplitEntry copyWith({String? member, double? amount, bool? isSettled}) {
    return SplitEntry(
      member: member ?? this.member,
      amount: amount ?? this.amount,
      isSettled: isSettled ?? this.isSettled,
    );
  }
}

class ExpenseModel {
  const ExpenseModel({
    required this.id,
    required this.groupId,
    required this.title,
    required this.amount,
    required this.paidBy,
    required this.splitType,
    required this.splits,
    required this.createdBy,
    required this.createdAt,
    this.note,
    this.deletedAt,
  });

  final String id;
  final String groupId;
  final String title;
  final double amount;
  final String paidBy;
  final String splitType;
  final List<SplitEntry> splits;
  final String createdBy;
  final DateTime createdAt;
  final String? note;
  final DateTime? deletedAt;

  bool get isDeleted => deletedAt != null;

  double shareFor(String member) {
    final split = splits.where((s) => s.member == member).firstOrNull;
    return split?.amount ?? 0;
  }

  factory ExpenseModel.fromJson(
      Map<String, dynamic> json, String currentUserId) {
    final paidByUser = json['paidBy'] as Map<String, dynamic>?;
    final paidByName = paidByUser != null
        ? (paidByUser['id'] == currentUserId ? 'You' : paidByUser['name'] as String)
        : 'Unknown';

    final createdByRaw = json['createdById'] as String? ?? '';
    final createdByName = createdByRaw == currentUserId ? 'You' : createdByRaw;

    final splits = (json['splits'] as List<dynamic>? ?? []).map((s) {
      final map = s as Map<String, dynamic>;
      return SplitEntry(
        member: map['userId'] == currentUserId ? 'You' : map['userId'] as String,
        amount: (map['amount'] as num).toDouble(),
        isSettled: map['settled'] as bool? ?? false,
      );
    }).toList();

    return ExpenseModel(
      id: json['id'] as String,
      groupId: json['groupId'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      paidBy: paidByName,
      splitType: json['splitType'] as String? ?? 'equal',
      splits: splits,
      createdBy: createdByName,
      createdAt: DateTime.parse(json['createdAt'] as String),
      note: json['note'] as String?,
      deletedAt: json['deletedAt'] != null
          ? DateTime.tryParse(json['deletedAt'] as String)
          : null,
    );
  }

  ExpenseModel copyWith({
    String? id,
    String? groupId,
    String? title,
    double? amount,
    String? paidBy,
    String? splitType,
    List<SplitEntry>? splits,
    String? createdBy,
    DateTime? createdAt,
    String? note,
    DateTime? deletedAt,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      paidBy: paidBy ?? this.paidBy,
      splitType: splitType ?? this.splitType,
      splits: splits ?? this.splits,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      note: note ?? this.note,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }
}
