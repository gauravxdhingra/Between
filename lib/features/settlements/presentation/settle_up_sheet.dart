import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/settlement_calculator.dart';
import '../../expenses/data/expenses_repository.dart';
import '../../expenses/domain/expense_model.dart';
import '../../groups/domain/group_model.dart';
import '../data/settlements_repository.dart';

class SettleUpSheet extends ConsumerStatefulWidget {
  const SettleUpSheet({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.members,
    required this.memberObjects,
  });

  final String groupId;
  final String groupName;
  final List<String> members;
  final List<GroupMember> memberObjects;

  @override
  ConsumerState<SettleUpSheet> createState() => _SettleUpSheetState();
}

class _SettleUpSheetState extends ConsumerState<SettleUpSheet> {
  final Set<String> _recorded = {};

  Map<String, double> _computeNetBalances(
    List<ExpenseModel> expenses,
    List<SettlementRecord> settlements,
  ) {
    final net = <String, double>{for (final m in widget.members) m: 0.0};

    for (final e in expenses) {
      if (net.containsKey(e.paidBy)) {
        net[e.paidBy] = net[e.paidBy]! + e.amount;
      }
      for (final split in e.splits) {
        if (net.containsKey(split.member)) {
          net[split.member] = net[split.member]! - split.amount;
        }
      }
    }

    for (final s in settlements) {
      if (net.containsKey(s.from)) net[s.from] = net[s.from]! + s.amount;
      if (net.containsKey(s.to)) net[s.to] = net[s.to]! - s.amount;
    }

    return net;
  }

  @override
  Widget build(BuildContext context) {
    final allExpenses = ref.watch(expensesProvider);
    final allSettlements = ref.watch(settlementsProvider);

    final expenses = expensesForGroup(allExpenses, widget.groupId);
    final settlements =
        allSettlements.where((s) => s.groupId == widget.groupId).toList();

    final netBalances = _computeNetBalances(expenses, settlements);
    final transfers = simplifyDebts(netBalances);
    final allSettled = transfers.isEmpty ||
        transfers.every((t) => _recorded.contains(_transferKey(t)));

    final theme = Theme.of(context);

    return Container(
      decoration: const BoxDecoration(
        color: kBgSurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
          24, 16, 24, MediaQuery.of(context).viewPadding.bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: kDivider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          Text(
            allSettled ? 'All settled ✓' : 'How to settle up',
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            allSettled
                ? 'No outstanding balances in ${widget.groupName}'
                : '${transfers.length} transfer${transfers.length == 1 ? '' : 's'} needed',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: kTextSecondary),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          if (allSettled)
            _AllSettledWidget()
          else ...[
            ...transfers.map((t) {
              final key = _transferKey(t);
              final done = _recorded.contains(key);
              return _TransferRow(
                transfer: t,
                isRecorded: done,
                onRecord: done ? null : () => _confirmRecord(context, t),
              );
            }),
            const SizedBox(height: 8),
            Text(
              'Tap "Record" once the transfer is done.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: kTextMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  String _transferKey(Transfer t) => '${t.from}→${t.to}@${t.amount}';

  void _confirmRecord(BuildContext context, Transfer transfer) {
    final noteController = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: kBgSurface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
              24, 20, 24, MediaQuery.of(ctx).viewPadding.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Record payment',
                  style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 16),

              _ConfirmRow(label: 'From', value: transfer.from),
              _ConfirmRow(label: 'To', value: transfer.to),
              _ConfirmRow(
                  label: 'Amount', value: formatInr(transfer.amount)),

              const SizedBox(height: 14),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  hintText: 'Note (optional) — e.g. via GPay',
                ),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () async {
                  final nav = Navigator.of(ctx);
                  final note = noteController.text.trim();
                  String idFor(String displayName) {
                    for (final m in widget.memberObjects) {
                      if (m.name == displayName || displayName == 'You') {
                        return m.id;
                      }
                    }
                    return displayName;
                  }
                  await ref.read(settlementsProvider.notifier).record(
                    groupId: widget.groupId,
                    fromId: idFor(transfer.from),
                    toId: idFor(transfer.to),
                    amount: transfer.amount,
                    note: note.isEmpty ? null : note,
                  );
                  setState(() => _recorded.add(_transferKey(transfer)));
                  HapticFeedback.mediumImpact();
                  nav.pop();
                },
                child: Container(
                  height: 52,
                  decoration: BoxDecoration(
                    color: kMint,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: const Text('Confirm settlement',
                      style: TextStyle(
                          color: kBgBase,
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransferRow extends StatelessWidget {
  const _TransferRow({
    required this.transfer,
    required this.isRecorded,
    required this.onRecord,
  });

  final Transfer transfer;
  final bool isRecorded;
  final VoidCallback? onRecord;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 16, 12, 16),
      decoration: BoxDecoration(
        color: isRecorded
            ? kPositive.withValues(alpha: 0.06)
            : kBgElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isRecorded
              ? kPositive.withValues(alpha: 0.25)
              : kDivider,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(transfer.from,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isRecorded ? kTextMuted : kTextPrimary,
                        )),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(Icons.arrow_forward_rounded,
                          size: 14,
                          color:
                              isRecorded ? kTextMuted : kTextSecondary),
                    ),
                    Text(transfer.to,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isRecorded ? kTextMuted : kTextPrimary,
                        )),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  formatInr(transfer.amount),
                  style: amountStyle(size: 18,
                      color: isRecorded ? kTextMuted : kMint),
                ),
              ],
            ),
          ),
          if (isRecorded)
            const Icon(Icons.check_circle_rounded,
                color: kPositive, size: 22)
          else
            GestureDetector(
              onTap: onRecord,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: kMint.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: kMint.withValues(alpha: 0.3)),
                ),
                child: const Text('Record',
                    style: TextStyle(
                        color: kMint,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ),
            ),
        ],
      ),
    );
  }
}

class _AllSettledWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      alignment: Alignment.center,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: kPositive.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.check_rounded,
                size: 32, color: kPositive),
          ),
          const SizedBox(height: 16),
          Text(
            'Everyone is square.',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: kPositive),
          ),
        ],
      ),
    );
  }
}

class _ConfirmRow extends StatelessWidget {
  const _ConfirmRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            child: Text(label,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: kTextSecondary)),
          ),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
