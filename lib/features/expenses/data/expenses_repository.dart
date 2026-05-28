import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/api/api_client.dart';
import '../../../core/supabase/supabase_client.dart';
import '../domain/expense_model.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final expensesProvider =
    StateNotifierProvider<ExpensesNotifier, List<ExpenseModel>>((ref) {
  return ExpensesNotifier(ref.read(apiClientProvider));
});

List<ExpenseModel> expensesForGroup(List<ExpenseModel> all, String groupId) {
  return all
      .where((e) => e.groupId == groupId && !e.isDeleted)
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class ExpensesNotifier extends StateNotifier<List<ExpenseModel>> {
  ExpensesNotifier(this._api) : super([]);

  final ApiClient _api;

  String get _currentUserId {
    if (!SupabaseConfig.isConfigured) return 'local';
    return Supabase.instance.client.auth.currentUser?.id ?? 'local';
  }

  Future<void> fetchForGroup(String groupId) async {
    final res = await _api.get<List<dynamic>>('/groups/$groupId/expenses');
    final fetched = (res.data ?? [])
        .map((j) =>
            ExpenseModel.fromJson(j as Map<String, dynamic>, _currentUserId))
        .toList();

    // Replace expenses for this group, keep others
    state = [
      ...state.where((e) => e.groupId != groupId),
      ...fetched,
    ];
  }

  Future<ExpenseModel> addExpense({
    required String groupId,
    required String title,
    required double amount,
    required String paidById,
    required String splitType,
    required List<SplitEntry> splits,
    String? note,
  }) async {
    final res =
        await _api.post<Map<String, dynamic>>('/groups/$groupId/expenses',
            data: {
          'title': title,
          'amount': amount,
          'paidById': paidById,
          'splitType': splitType,
          'note': note,
          'splits': splits
              .map((s) => {'userId': s.member, 'amount': s.amount})
              .toList(),
        });

    final expense =
        ExpenseModel.fromJson(res.data!, _currentUserId);
    state = [expense, ...state];
    return expense;
  }

  Future<void> softDelete(String expenseId, String groupId) async {
    await _api.delete<void>('/groups/$groupId/expenses/$expenseId');
    state = [
      for (final e in state)
        if (e.id == expenseId)
          e.copyWith(deletedAt: DateTime.now())
        else
          e,
    ];
  }
}
