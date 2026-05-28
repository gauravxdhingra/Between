import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

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
}

final settlementsProvider =
    StateNotifierProvider<SettlementsNotifier, List<SettlementRecord>>((ref) {
  return SettlementsNotifier();
});

class SettlementsNotifier extends StateNotifier<List<SettlementRecord>> {
  SettlementsNotifier() : super([]);

  final _uuid = const Uuid();

  SettlementRecord record({
    required String groupId,
    required String from,
    required String to,
    required double amount,
    String? note,
  }) {
    final settlement = SettlementRecord(
      id: _uuid.v4(),
      groupId: groupId,
      from: from,
      to: to,
      amount: amount,
      settledAt: DateTime.now(),
      note: note,
    );
    state = [settlement, ...state];
    return settlement;
  }

  List<SettlementRecord> forGroup(String groupId) {
    return state.where((s) => s.groupId == groupId).toList();
  }
}
