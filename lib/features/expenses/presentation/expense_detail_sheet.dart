import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../data/expenses_repository.dart';
import '../domain/expense_model.dart';

class ExpenseDetailSheet extends ConsumerWidget {
  const ExpenseDetailSheet({
    super.key,
    required this.expense,
    required this.currentUser,
  });

  final ExpenseModel expense;
  final String currentUser;

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isCreator = expense.createdBy == currentUser;
    final myShare = expense.shareFor(currentUser);
    final paidByYou = expense.paidBy == currentUser;

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

          // Title row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(expense.title, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(expense.createdAt),
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: kTextMuted),
                    ),
                  ],
                ),
              ),
              Text(
                formatInr(expense.amount),
                style: amountStyle(size: 24, color: kTextPrimary),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Paid by
          _InfoRow(
            icon: Icons.person_outline_rounded,
            child: Row(
              children: [
                Text('Paid by ',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: kTextSecondary)),
                Text(expense.paidBy,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
                if (paidByYou) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: kPositive.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('you',
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: kPositive)),
                  ),
                ],
              ],
            ),
          ),

          if (expense.note != null && expense.note!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.notes_rounded,
              child: Text(expense.note!,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: kTextSecondary)),
            ),
          ],

          const SizedBox(height: 20),
          const Divider(color: kDivider, height: 1),
          const SizedBox(height: 16),

          Text('Split breakdown', style: theme.textTheme.labelLarge),
          const SizedBox(height: 12),

          ...expense.splits.map((split) {
            final isYou = split.member == currentUser;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isYou
                          ? kMint.withValues(alpha: 0.12)
                          : kBgElevated,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      split.member.isNotEmpty
                          ? split.member[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isYou ? kMint : kTextMuted,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      split.member,
                      style: isYou
                          ? theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600)
                          : theme.textTheme.bodyMedium,
                    ),
                  ),
                  Text(
                    formatInr(split.amount),
                    style: amountStyle(size: 14,
                        color: isYou ? kTextPrimary : kTextSecondary),
                  ),
                  if (split.isSettled) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.check_circle_rounded,
                        size: 16, color: kPositive),
                  ],
                ],
              ),
            );
          }),

          // Your share summary
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: kBgElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kDivider),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet_rounded,
                    size: 18, color: kTextMuted),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    paidByYou
                        ? 'You paid ${formatInr(expense.amount)} — your share is ${formatInr(myShare)}'
                        : 'Your share of this expense',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: kTextSecondary),
                  ),
                ),
                Text(
                  paidByYou
                      ? 'lent ${formatInr(expense.amount - myShare)}'
                      : 'owe ${formatInr(myShare)}',
                  style: amountStyle(size: 13,
                      color: paidByYou ? kPositive : kNegative),
                ),
              ],
            ),
          ),

          if (isCreator) ...[
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => _confirmDelete(context, ref),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: kNegative.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: kNegative.withValues(alpha: 0.3)),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.delete_outline_rounded,
                        size: 18, color: kNegative),
                    const SizedBox(width: 6),
                    const Text('Delete expense',
                        style: TextStyle(
                            color: kNegative, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
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
            Text(
              'Delete "${expense.title}"?',
              style: Theme.of(ctx).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'This expense will be removed from the group.',
              style: Theme.of(ctx)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: kTextSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () {
                ref.read(expensesProvider.notifier).softDelete(expense.id);
                HapticFeedback.mediumImpact();
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
              },
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: kNegative,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: const Text('Delete',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => Navigator.of(ctx).pop(),
              child: Container(
                height: 50,
                alignment: Alignment.center,
                child: const Text('Cancel',
                    style: TextStyle(color: kTextSecondary, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.child});
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: kTextMuted),
        const SizedBox(width: 8),
        Expanded(child: child),
      ],
    );
  }
}
