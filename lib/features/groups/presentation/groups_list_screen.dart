import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../expenses/data/expenses_repository.dart';
import '../../expenses/domain/expense_model.dart';
import '../data/groups_repository.dart';
import '../domain/group_model.dart';
import '../presentation/create_group_sheet.dart';
import '../presentation/group_detail_screen.dart';

class GroupsListScreen extends ConsumerWidget {
  const GroupsListScreen({super.key});

  String _relativeDays(DateTime value) {
    final days = DateTime.now().difference(value).inDays;
    if (days <= 0) return 'today';
    if (days == 1) return '1 day ago';
    return '$days days ago';
  }

  double _liveBalance(GroupModel group, List<ExpenseModel> allExpenses) {
    final liveExpenses = expensesForGroup(allExpenses, group.id);
    if (liveExpenses.isEmpty) return group.netBalance;
    double delta = 0;
    for (final e in liveExpenses) {
      delta += e.paidBy == 'You'
          ? e.amount - e.shareFor('You')
          : -e.shareFor('You');
    }
    return group.netBalance + delta;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groups = ref.watch(groupsProvider);
    final allExpenses = ref.watch(expensesProvider);
    final balances = {
      for (final g in groups) g.id: _liveBalance(g, allExpenses),
    };
    final total = balances.values.fold<double>(0, (s, b) => s + b);
    final theme = Theme.of(context);

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          // ── Header ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Groups',
                      style: theme.textTheme.headlineLarge),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        total >= 0 ? "overall you're owed" : 'overall you owe',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: kTextSecondary),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formatInr(total.abs()),
                        style: amountStyle(size: 20).copyWith(
                          color: total >= 0 ? kPositive : kNegative,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${groups.length} group${groups.length == 1 ? '' : 's'}',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: kTextMuted)),
                      GestureDetector(
                        onTap: () => _openCreate(context, ref),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: kMint.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: kMint.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add_rounded,
                                  size: 16, color: kMint),
                              const SizedBox(width: 4),
                              const Text('New group',
                                  style: TextStyle(
                                      color: kMint,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // ── Group list ──────────────────────────────────────────
          if (groups.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: kBgSurface,
                        shape: BoxShape.circle,
                        border: Border.all(color: kDivider),
                      ),
                      alignment: Alignment.center,
                      child: const Text('💸',
                          style: TextStyle(fontSize: 32)),
                    ),
                    const SizedBox(height: 16),
                    Text('No groups yet',
                        style: theme.textTheme.titleLarge),
                    const SizedBox(height: 6),
                    Text('Create one to start splitting expenses',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: kTextMuted)),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: () => _openCreate(context, ref),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: kMint,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text('Create a group',
                            style: TextStyle(
                                color: kBgBase,
                                fontWeight: FontWeight.w700,
                                fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(0, 4, 0, 120),
              sliver: SliverList.separated(
                separatorBuilder: (_, _) => Divider(
                  height: 1,
                  indent: 72,
                  color: kDivider,
                ),
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  final g = groups[index];
                  final balance = balances[g.id] ?? g.netBalance;
                  return _GroupRow(
                    group: g,
                    balance: balance,
                    subtitle: _relativeDays(g.lastActivity),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => GroupDetailScreen(group: g),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  void _openCreate(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreateGroupSheet(
        onCreated: (group) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => GroupDetailScreen(group: group),
            ),
          );
        },
      ),
    );
  }
}

class _GroupRow extends StatelessWidget {
  const _GroupRow({
    required this.group,
    required this.balance,
    required this.subtitle,
    required this.onTap,
  });

  final GroupModel group;
  final double balance;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOwed = balance > 0.01;
    final isOwe = balance < -0.01;
    final balanceColor =
        isOwed ? kPositive : isOwe ? kNegative : kNeutral;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            // Emoji avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: kBgElevated,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kDivider),
              ),
              alignment: Alignment.center,
              child: Text(group.emoji,
                  style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 14),

            // Name + meta
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(group.name,
                      style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    '${group.memberCount} members · $subtitle',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: kTextMuted),
                  ),
                ],
              ),
            ),

            // Balance
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatInr(balance.abs(), compact: true),
                  style: amountStyle(size: 16).copyWith(color: balanceColor),
                ),
                const SizedBox(height: 2),
                Text(
                  isOwed
                      ? 'owed to you'
                      : isOwe
                          ? 'you owe'
                          : 'settled',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: balanceColor.withValues(alpha: 0.7),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
