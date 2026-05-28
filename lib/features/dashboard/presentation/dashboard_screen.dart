import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/notification_service.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../features/expenses/data/expenses_repository.dart';
import '../../../features/expenses/domain/expense_model.dart';
import '../../../features/expenses/presentation/add_expense_sheet.dart';
import '../../../features/groups/data/groups_repository.dart';
import '../../../features/groups/domain/group_model.dart';
import '../../../features/groups/presentation/group_detail_screen.dart';
import '../../../features/groups/presentation/groups_list_screen.dart';
import '../../../features/settlements/data/settlements_repository.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/widgets/floating_nav.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with WidgetsBindingObserver {
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(groupsProvider.notifier).fetch();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkIdleNudges();
  }

  void _checkIdleNudges() {
    final groups = ref.read(groupsListProvider);
    final allExpenses = ref.read(expensesProvider);
    final allSettlements = ref.read(settlementsProvider);
    final now = DateTime.now();

    for (final group in groups) {
      final expenses = expensesForGroup(allExpenses, group.id);
      if (expenses.isEmpty) continue;
      if (now.difference(expenses.first.createdAt).inDays < 5) continue;

      double balance = group.netBalance;
      for (final e in expenses) {
        balance += e.paidBy == 'You' ? e.amount - e.shareFor('You') : -e.shareFor('You');
      }
      for (final s in allSettlements.where((s) => s.groupId == group.id)) {
        if (s.from == 'You') balance += s.amount;
        if (s.to == 'You') balance -= s.amount;
      }

      if (balance.abs() > 0.01) {
        showIdleGroupNudge(groupName: group.name, unsettledAmount: balance.abs());
      }
    }
  }

  void _openAddExpense() {
    final groups = ref.read(groupsListProvider);
    if (groups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Create a group first to add an expense')),
      );
      return;
    }
    // Use first group as default for the global FAB — user can pick group in sheet
    final group = groups.first;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddExpenseSheet(
        groupId: group.id,
        members: group.members,
        memberObjects: group.memberObjects,
        onAdded: (_) {},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final body = switch (_tabIndex) {
      0 => const HomeTab(),
      1 => const GroupsListScreen(),
      3 => const _ActivityTab(),
      4 => const _ProfileTab(),
      _ => const HomeTab(),
    };

    return Scaffold(
      backgroundColor: kBgBase,
      extendBody: true,
      body: body,
      bottomNavigationBar: FloatingNav(
        currentIndex: _tabIndex,
        onTap: (i) => setState(() => _tabIndex = i),
        onAddTap: _openAddExpense,
      ),
    );
  }
}

// ── Home Tab ──────────────────────────────────────────────────────────────────

class HomeTab extends ConsumerStatefulWidget {
  const HomeTab({super.key});

  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab> {
  double _groupBalance(GroupModel g, List<ExpenseModel> expenses, List<SettlementRecord> settlements) {
    final exp = expensesForGroup(expenses, g.id);
    final sett = settlements.where((s) => s.groupId == g.id).toList();
    double net = g.netBalance;
    for (final e in exp) {
      net += e.paidBy == 'You' ? e.amount - e.shareFor('You') : -e.shareFor('You');
    }
    for (final s in sett) {
      if (s.from == 'You') net += s.amount;
      if (s.to == 'You') net -= s.amount;
    }
    return net;
  }

  @override
  Widget build(BuildContext context) {
    final groups = ref.watch(groupsListProvider);
    final allExpenses = ref.watch(expensesProvider);
    final allSettlements = ref.watch(settlementsProvider);

    final balances = {for (final g in groups) g.id: _groupBalance(g, allExpenses, allSettlements)};
    final owed = balances.values.where((b) => b > 0.01).fold<double>(0, (s, b) => s + b);
    final owe  = balances.values.where((b) => b < -0.01).fold<double>(0, (s, b) => s + b.abs());
    final net  = owed - owe;

    // Monthly stats
    final now = DateTime.now();
    final monthExp = allExpenses.where((e) =>
        !e.isDeleted && e.createdAt.year == now.year && e.createdAt.month == now.month).toList();
    final monthTotal = monthExp.fold<double>(0, (s, e) => s + e.amount);
    final pendingCount = balances.values.where((b) => b.abs() > 0.01).length;

    // Recent activity
    final recent = [...allExpenses.where((e) => !e.isDeleted)]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Schedule weekly digest
    scheduleWeeklyDigest(totalOwed: owed, totalOwe: owe, groupCount: groups.length);

    final theme = Theme.of(context);
    final hour = now.hour;
    final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';

    return CustomScrollView(
      slivers: [
        // ── Header ────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(greeting,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: kTextSecondary)),
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: kMint.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text('G',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(color: kMint, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Hero balance card ─────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: _HeroCard(net: net, owed: owed, owe: owe),
          ),
        ),

        // ── Quick insights ────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 0, 0),
            child: SizedBox(
              height: 88,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(right: 24),
                children: [
                  _InsightChip(
                    label: 'This month',
                    value: formatInr(monthTotal, compact: true),
                    icon: Icons.calendar_today_rounded,
                  ),
                  const SizedBox(width: 10),
                  _InsightChip(
                    label: 'Groups',
                    value: '${groups.length}',
                    icon: Icons.group_rounded,
                  ),
                  const SizedBox(width: 10),
                  _InsightChip(
                    label: 'Pending',
                    value: '$pendingCount',
                    icon: Icons.pending_actions_rounded,
                  ),
                ],
              ),
            ),
          ),
        ),

        // ── Active groups ─────────────────────────────────────────
        if (groups.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
              child: Text('Active groups',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: kTextSecondary, fontSize: 13)),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 116,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: groups.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  final g = groups[i];
                  return _GroupCard(
                    group: g,
                    balance: balances[g.id] ?? 0,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => GroupDetailScreen(group: g)),
                    ),
                  );
                },
              ),
            ),
          ),
        ],

        // ── Recent activity ───────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
            child: Text('Recent activity',
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: kTextSecondary, fontSize: 13)),
          ),
        ),

        if (recent.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
              child: Text('No expenses yet.',
                  style: theme.textTheme.bodySmall),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
            sliver: SliverList.separated(
              itemCount: recent.take(8).length,
              separatorBuilder: (_, _) => const Divider(
                  color: kDivider, height: 1, indent: 52),
              itemBuilder: (context, i) {
                final e = recent[i];
                final groupName = groups
                    .where((g) => g.id == e.groupId)
                    .map((g) => g.name)
                    .firstOrNull ?? 'Unknown';
                return _ActivityTile(expense: e, groupName: groupName);
              },
            ),
          ),
      ],
    );
  }
}

// ── Hero balance card ─────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.net, required this.owed, required this.owe});

  final double net;
  final double owed;
  final double owe;

  @override
  Widget build(BuildContext context) {
    final isOwed = net > 0.01;
    final isOwe  = net < -0.01;
    final color  = isOwed ? kPositive : isOwe ? kNegative : kNeutral;
    final label  = isOwed ? 'you are owed' : isOwe ? 'you owe' : 'all settled up';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kBgSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kDivider),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: isOwed || isOwe ? 0.12 : 0.04),
            blurRadius: 32,
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: kTextSecondary, fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text(
            isOwed || isOwe ? formatInr(net.abs()) : '₹0',
            style: amountStyle(size: 40, color: color),
          ),
          if (isOwed || isOwe) ...[
            const SizedBox(height: 20),
            const Divider(color: kDivider, height: 1),
            const SizedBox(height: 16),
            Row(
              children: [
                _BalancePill(label: 'owed to you', amount: owed, color: kPositive),
                const SizedBox(width: 10),
                _BalancePill(label: 'you owe', amount: owe, color: kNegative),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _BalancePill extends StatelessWidget {
  const _BalancePill({required this.label, required this.amount, required this.color});

  final String label;
  final double amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 11)),
            const SizedBox(height: 4),
            Text(formatInr(amount, compact: true),
                style: amountStyle(size: 16, color: color)),
          ],
        ),
      ),
    );
  }
}

// ── Quick insight chip ────────────────────────────────────────────────────────

class _InsightChip extends StatelessWidget {
  const _InsightChip({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kBgSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: kDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, size: 18, color: kTextMuted),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: amountStyle(size: 17, color: kTextPrimary)),
              Text(label,
                  style: const TextStyle(color: kTextMuted, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Group card (horizontal scroll) ───────────────────────────────────────────

class _GroupCard extends StatelessWidget {
  const _GroupCard({required this.group, required this.balance, required this.onTap});

  final GroupModel group;
  final double balance;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isOwed = balance > 0.01;
    final isOwe  = balance < -0.01;
    final color  = isOwed ? kPositive : isOwe ? kNegative : kNeutral;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 148,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kBgSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kDivider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(group.emoji, style: const TextStyle(fontSize: 22)),
                const Spacer(),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(group.name,
                    style: const TextStyle(
                        color: kTextPrimary, fontWeight: FontWeight.w600, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(
                  isOwed ? '+${formatInr(balance, compact: true)}'
                      : isOwe ? '-${formatInr(balance.abs(), compact: true)}'
                      : 'settled',
                  style: amountStyle(size: 14, color: color),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Activity tile ─────────────────────────────────────────────────────────────

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.expense, required this.groupName});

  final ExpenseModel expense;
  final String groupName;

  String _ago(DateTime dt) {
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 1) return 'now';
    if (d.inHours < 1) return '${d.inMinutes}m';
    if (d.inHours < 24) return '${d.inHours}h';
    if (d.inDays == 1) return '1d';
    return '${d.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    final paidByYou = expense.paidBy == 'You';
    final initial = expense.paidBy.isNotEmpty ? expense.paidBy[0].toUpperCase() : '?';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: paidByYou
                  ? kPositive.withValues(alpha: 0.12)
                  : kBgElevated,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(initial,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: paidByYou ? kPositive : kTextSecondary)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${expense.paidBy} added "${expense.title}"',
                  style: const TextStyle(
                      color: kTextPrimary, fontSize: 14, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(groupName,
                    style: const TextStyle(color: kTextMuted, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(formatInr(expense.amount, compact: true),
                  style: amountStyle(size: 14, color: kTextPrimary)),
              Text(_ago(expense.createdAt),
                  style: const TextStyle(color: kTextMuted, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Stub tabs ─────────────────────────────────────────────────────────────────

class _ActivityTab extends ConsumerWidget {
  const _ActivityTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(expensesProvider);
    final groups = ref.watch(groupsListProvider);
    final recent = [...all.where((e) => !e.isDeleted)]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Text('Activity',
                  style: Theme.of(context).textTheme.headlineLarge),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
            sliver: SliverList.separated(
              itemCount: recent.length,
              separatorBuilder: (_, _) =>
                  const Divider(color: kDivider, height: 1, indent: 52),
              itemBuilder: (context, i) {
                final e = recent[i];
                final groupName = groups
                        .where((g) => g.id == e.groupId)
                        .map((g) => g.name)
                        .firstOrNull ??
                    'Unknown';
                return _ActivityTile(expense: e, groupName: groupName);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileTab extends ConsumerWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Profile', style: Theme.of(context).textTheme.headlineLarge),
            const Spacer(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.logout_rounded, color: kNegative),
              title: const Text('Sign out',
                  style: TextStyle(color: kNegative, fontWeight: FontWeight.w500)),
              onTap: () async {
                ref.read(localTestModeProvider.notifier).state = false;
                await ref.read(authActionsProvider).signOut();
              },
            ),
          ],
        ),
      ),
    );
  }
}
