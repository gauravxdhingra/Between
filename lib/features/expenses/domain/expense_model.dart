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
  final String splitType; // 'equal' | 'custom'
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
