import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/api/api_client.dart';
import '../../../core/supabase/supabase_client.dart';

class SettlementRecord {
  const SettlementRecord({
    required this.id,
    required this.groupId,
    required this.from,
    required this.to,
    required this.amount,
    required this.settledAt,
    this.note,
  });

  final String id;
  final String groupId;
  final String from;
  final String to;
  final double amount;
  final DateTime settledAt;
  final String? note;

  factory SettlementRecord.fromJson(
      Map<String, dynamic> json, String currentUserId) {
    String nameFor(Map<String, dynamic> user) =>
        user['id'] == currentUserId ? 'You' : user['name'] as String;

    return SettlementRecord(
      id: json['id'] as String,
      groupId: json['groupId'] as String,
      from: nameFor(json['from'] as Map<String, dynamic>),
      to: nameFor(json['to'] as Map<String, dynamic>),
      amount: (json['amount'] as num).toDouble(),
      settledAt: DateTime.parse(json['createdAt'] as String),
      note: json['note'] as String?,
    );
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final settlementsProvider =
    StateNotifierProvider<SettlementsNotifier, List<SettlementRecord>>((ref) {
  return SettlementsNotifier(ref.read(apiClientProvider));
});

// ── Notifier ──────────────────────────────────────────────────────────────────

class SettlementsNotifier extends StateNotifier<List<SettlementRecord>> {
  SettlementsNotifier(this._api) : super([]);

  final ApiClient _api;

  String get _currentUserId {
    if (!SupabaseConfig.isConfigured) return 'local';
    return Supabase.instance.client.auth.currentUser?.id ?? 'local';
  }

  Future<void> fetchForGroup(String groupId) async {
    final res =
        await _api.get<List<dynamic>>('/groups/$groupId/settlements');
    final fetched = (res.data ?? [])
        .map((j) => SettlementRecord.fromJson(
            j as Map<String, dynamic>, _currentUserId))
        .toList();

    state = [
      ...state.where((s) => s.groupId != groupId),
      ...fetched,
    ];
  }

  Future<SettlementRecord> record({
    required String groupId,
    required String fromId,
    required String toId,
    required double amount,
    String? note,
  }) async {
    final res = await _api
        .post<Map<String, dynamic>>('/groups/$groupId/settlements', data: {
      'fromId': fromId,
      'toId': toId,
      'amount': amount,
      'note': note,
    });

    final settlement =
        SettlementRecord.fromJson(res.data!, _currentUserId);
    state = [settlement, ...state];
    return settlement;
  }

  List<SettlementRecord> forGroup(String groupId) {
    return state.where((s) => s.groupId == groupId).toList();
  }
}
