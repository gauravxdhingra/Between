import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../expenses/data/expenses_repository.dart';
import '../../expenses/domain/expense_model.dart';
import '../../expenses/presentation/add_expense_sheet.dart';
import '../../expenses/presentation/expense_detail_sheet.dart';
import '../../settlements/data/settlements_repository.dart';
import '../../settlements/presentation/settle_up_sheet.dart';
import '../domain/group_model.dart';

class GroupDetailScreen extends ConsumerStatefulWidget {
  const GroupDetailScreen({super.key, required this.group});

  final GroupModel group;

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen> {
  GroupModel get group => widget.group;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  Future<void> _fetch() async {
    await Future.wait([
      ref.read(expensesProvider.notifier).fetchForGroup(group.id),
      ref.read(settlementsProvider.notifier).fetchForGroup(group.id),
    ]);
  }

  String _ago(DateTime value) {
    final diff = DateTime.now().difference(value);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return '1 day ago';
    return '${diff.inDays}d ago';
  }

  double _computeNetBalance(
    List<ExpenseModel> expenses,
    List<SettlementRecord> settlements,
  ) {
    double net = 0;
    for (final e in expenses) {
      net += e.paidBy == 'You'
          ? e.amount - e.shareFor('You')
          : -e.shareFor('You');
    }
    for (final s in settlements) {
      if (s.from == 'You') net += s.amount;
      if (s.to == 'You') net -= s.amount;
    }
    return net;
  }

  @override
  Widget build(BuildContext context) {
    final allExpenses = ref.watch(expensesProvider);
    final allSettlements = ref.watch(settlementsProvider);

    final expenses = expensesForGroup(allExpenses, group.id);
    final settlements =
        allSettlements.where((s) => s.groupId == group.id).toList();
    final netBalance = _computeNetBalance(expenses, settlements);

    final isOwed = netBalance > 0.01;
    final isOwe = netBalance < -0.01;
    final balanceColor =
        isOwed ? kPositive : isOwe ? kNegative : kNeutral;

    final allDisplay = [...expenses]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: kBgBase,
      extendBody: true,
      body: RefreshIndicator(
        color: kMint,
        backgroundColor: kBgSurface,
        onRefresh: _fetch,
        child: CustomScrollView(
          slivers: [
          // ── App bar ─────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: kBgBase,
            foregroundColor: kTextPrimary,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            title: Row(
              children: [
                Text(group.emoji,
                    style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Text(group.name,
                    style: theme.textTheme.titleLarge),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
                tooltip: 'Copy invite link',
                onPressed: () async {
                  final url =
                      'https://settle.app/join/${group.id}?token=${group.inviteToken}';
                  await Clipboard.setData(ClipboardData(text: url));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invite link copied')),
                    );
                  }
                },
              ),
            ],
          ),

          // ── Balance card ────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: kBgSurface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: kDivider),
                  boxShadow: [
                    BoxShadow(
                      color: balanceColor.withValues(
                          alpha: isOwed || isOwe ? 0.10 : 0.03),
                      blurRadius: 28,
                      spreadRadius: -4,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isOwed
                                    ? 'You are owed'
                                    : isOwe
                                        ? 'You owe'
                                        : 'All settled',
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(color: kTextSecondary),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                isOwed || isOwe
                                    ? formatInr(netBalance.abs())
                                    : '₹0',
                                style: amountStyle(size: 28,
                                    color: balanceColor),
                              ),
                            ],
                          ),
                        ),
                        if (isOwed || isOwe)
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.mediumImpact();
                              showModalBottomSheet<void>(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => SettleUpSheet(
                                  groupId: group.id,
                                  groupName: group.name,
                                  members: group.members,
                                  memberObjects: group.memberObjects,
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 10),
                              decoration: BoxDecoration(
                                color: balanceColor,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                'Settle up',
                                style: TextStyle(
                                  color: kBgBase,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: kDivider, height: 1),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: group.members
                          .map((m) => _MemberChip(name: m))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Section label ───────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 4),
              child: Row(
                children: [
                  Text(
                    '${allDisplay.length} expense${allDisplay.length == 1 ? '' : 's'}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: kTextMuted),
                  ),
                ],
              ),
            ),
          ),

          // ── Expense feed ────────────────────────────────────────
          if (allDisplay.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🧾',
                        style: TextStyle(fontSize: 40)),
                    const SizedBox(height: 10),
                    Text('No expenses yet',
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text('Tap Add to record the first one',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: kTextMuted)),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 120),
              sliver: SliverList.separated(
                separatorBuilder: (_, _) => Divider(
                  height: 1,
                  indent: 72,
                  color: kDivider,
                ),
                itemCount: allDisplay.length,
                itemBuilder: (context, i) {
                  final e = allDisplay[i];
                  return _ExpenseRow(
                    expense: e,
                    ago: _ago(e.createdAt),
                    onTap: () {
                      showModalBottomSheet<void>(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => ExpenseDetailSheet(
                          expense: e,
                          currentUser: 'You',
                          groupId: group.id,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // ── Sticky add button ──────────────────────────────────────
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        child: SafeArea(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => AddExpenseSheet(
                  groupId: group.id,
                  members: group.members,
                  memberObjects: group.memberObjects,
                  onAdded: (expense) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('"${expense.title}" added'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              );
            },
            child: Container(
              height: 54,
              decoration: BoxDecoration(
                color: kMint,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: kMint.withValues(alpha: 0.30),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add_rounded, color: kBgBase, size: 20),
                  const SizedBox(width: 6),
                  const Text(
                    'Add expense',
                    style: TextStyle(
                      color: kBgBase,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExpenseRow extends StatelessWidget {
  const _ExpenseRow({
    required this.expense,
    required this.ago,
    required this.onTap,
  });

  final ExpenseModel expense;
  final String ago;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final paidByYou = expense.paidBy == 'You';
    final initial =
        expense.paidBy.isNotEmpty ? expense.paidBy[0].toUpperCase() : '?';

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: paidByYou
                    ? kPositive.withValues(alpha: 0.12)
                    : kBgElevated,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                initial,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: paidByYou ? kPositive : kTextSecondary,
                ),
              ),
            ),
            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(expense.title,
                      style: theme.textTheme.bodyLarge
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    paidByYou
                        ? 'You paid · ${formatInr(expense.shareFor('You'))} your share'
                        : '${expense.paidBy} paid · ${formatInr(expense.shareFor('You'))} your share',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: kTextMuted),
                  ),
                ],
              ),
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatInr(expense.amount, compact: true),
                  style: amountStyle(size: 15).copyWith(
                    color: paidByYou ? kPositive : kTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(ago,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: kTextMuted, fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberChip extends StatelessWidget {
  const _MemberChip({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: kBgElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kDivider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: kMint.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(initial,
                style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: kMint)),
          ),
          const SizedBox(width: 5),
          Text(name,
              style: const TextStyle(
                  fontSize: 12, color: kTextSecondary)),
        ],
      ),
    );
  }
}
