import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../domain/expense_model.dart';

final expensesProvider =
    StateNotifierProvider<ExpensesNotifier, List<ExpenseModel>>((ref) {
  return ExpensesNotifier();
});

List<ExpenseModel> expensesForGroup(List<ExpenseModel> all, String groupId) {
  return all
      .where((e) => e.groupId == groupId && !e.isDeleted)
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
}

class ExpensesNotifier extends StateNotifier<List<ExpenseModel>> {
  ExpensesNotifier() : super([]);

  final _uuid = const Uuid();

  ExpenseModel addExpense({
    required String groupId,
    required String title,
    required double amount,
    required String paidBy,
    required String splitType,
    required List<SplitEntry> splits,
    String createdBy = 'You',
    String? note,
  }) {
    final expense = ExpenseModel(
      id: _uuid.v4(),
      groupId: groupId,
      title: title,
      amount: amount,
      paidBy: paidBy,
      splitType: splitType,
      splits: splits,
      createdBy: createdBy,
      createdAt: DateTime.now(),
      note: note,
    );
    state = [expense, ...state];
    return expense;
  }

  void softDelete(String expenseId) {
    state = [
      for (final e in state)
        if (e.id == expenseId) e.copyWith(deletedAt: DateTime.now()) else e,
    ];
  }
}
