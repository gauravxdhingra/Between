import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../groups/domain/group_model.dart';
import '../data/expenses_repository.dart';
import '../domain/expense_model.dart';

class AddExpenseSheet extends ConsumerStatefulWidget {
  const AddExpenseSheet({
    super.key,
    required this.groupId,
    required this.members,
    required this.memberObjects,
    required this.onAdded,
  });

  final String groupId;
  final List<String> members;       // display names — used in UI
  final List<GroupMember> memberObjects; // id + name — used for API
  final void Function(ExpenseModel expense) onAdded;

  @override
  ConsumerState<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends ConsumerState<AddExpenseSheet> {
  String _amountBuffer = '';
  final _titleController = TextEditingController();
  String _paidBy = 'You';
  String _splitType = 'equal';
  final Map<String, TextEditingController> _customControllers = {};
  String? _error;

  static const _quickAmounts = [100, 500, 1000, 2000];

  @override
  void initState() {
    super.initState();
    for (final m in widget.members) {
      _customControllers[m] = TextEditingController();
    }
    if (!widget.members.contains('You') && widget.members.isNotEmpty) {
      _paidBy = widget.members.first;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    for (final c in _customControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  double get _parsedAmount => double.tryParse(_amountBuffer) ?? 0;
  double get _equalShare =>
      widget.members.isEmpty ? 0 : _parsedAmount / widget.members.length;
  double get _customTotal => _customControllers.values
      .map((c) => double.tryParse(c.text) ?? 0)
      .fold(0, (a, b) => a + b);
  double get _customRemaining => _parsedAmount - _customTotal;

  void _numpadTap(String key) {
    setState(() {
      _error = null;
      if (key == '⌫') {
        if (_amountBuffer.isNotEmpty) {
          _amountBuffer = _amountBuffer.substring(0, _amountBuffer.length - 1);
        }
        return;
      }
      if (key == '.') {
        if (!_amountBuffer.contains('.')) {
          _amountBuffer = _amountBuffer.isEmpty ? '0.' : '$_amountBuffer.';
        }
        return;
      }
      final parts = _amountBuffer.split('.');
      if (!_amountBuffer.contains('.') && parts[0].length >= 6) return;
      if (_amountBuffer.contains('.') && parts.length > 1 && parts[1].length >= 2) return;
      _amountBuffer = '$_amountBuffer$key';
    });
  }

  void _addQuick(int amount) {
    HapticFeedback.selectionClick();
    setState(() {
      _error = null;
      final current = double.tryParse(_amountBuffer) ?? 0;
      final next = (current + amount).toStringAsFixed(0);
      _amountBuffer = next.length <= 6 ? next : _amountBuffer;
    });
  }

  // Resolve display name → user ID using memberObjects (parallel lists)
  String _idFor(String displayName) {
    final idx = widget.members.indexOf(displayName);
    if (idx != -1 && idx < widget.memberObjects.length) {
      return widget.memberObjects[idx].id;
    }
    return displayName; // fallback: local mode
  }

  Future<bool> _submit() async {
    final amount = _parsedAmount;
    if (amount <= 0) { setState(() => _error = 'Enter an amount'); return false; }
    if (amount > 999999) { setState(() => _error = 'Max ₹9,99,999'); return false; }
    final title = _titleController.text.trim();
    if (title.isEmpty) { setState(() => _error = 'Enter a title'); return false; }
    if (title.length > 60) { setState(() => _error = 'Title max 60 chars'); return false; }

    List<SplitEntry> splits;
    if (_splitType == 'equal') {
      splits = widget.members
          .map((m) => SplitEntry(member: _idFor(m), amount: _equalShare))
          .toList();
    } else {
      if (_customRemaining.abs() > 0.01) {
        setState(() => _error = _customRemaining > 0
            ? '${formatInr(_customRemaining)} unassigned'
            : '${formatInr(_customRemaining.abs())} over-assigned');
        return false;
      }
      splits = widget.members.map((m) {
        final v = double.tryParse(_customControllers[m]?.text ?? '') ?? 0;
        return SplitEntry(member: _idFor(m), amount: v);
      }).toList();
    }

    try {
      final expense = await ref.read(expensesProvider.notifier).addExpense(
        groupId: widget.groupId,
        title: title,
        amount: amount,
        paidById: _idFor(_paidBy),
        splitType: _splitType,
        splits: splits,
      );

      showExpenseAdded(
        addedBy: _paidBy,
        title: title,
        yourShare: expense.shareFor('You'),
        groupName: widget.groupId,
      );

      HapticFeedback.mediumImpact();
      widget.onAdded(expense);
      return true;
    } catch (e) {
      setState(() => _error = friendlyError(e));
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final display = _amountBuffer.isEmpty ? '0' : _amountBuffer;
    final hasAmount = _parsedAmount > 0;

    return DraggableScrollableSheet(
      initialChildSize: 0.93,
      minChildSize: 0.6,
      maxChildSize: 0.97,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: kBgSurface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // drag handle
              const SizedBox(height: 10),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: kDivider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // ── Header ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Add expense',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(color: kTextSecondary)),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: kBgElevated,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Icon(Icons.close_rounded,
                            size: 16, color: kTextMuted),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ── Amount hero ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('₹',
                        style: theme.textTheme.headlineMedium
                            ?.copyWith(color: kTextMuted, fontSize: 28)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        display,
                        style: amountStyle(size: 52).copyWith(
                          color: hasAmount ? kTextPrimary : kTextMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // error
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(_error!,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: kNegative)),
                  ),
                ),

              const SizedBox(height: 10),

              // ── Quick-add buttons ───────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: _quickAmounts.map((amt) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => _addQuick(amt),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: kBgElevated,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: kDivider),
                          ),
                          child: Text(
                            '+${amt >= 1000 ? '${(amt / 1000).toStringAsFixed(amt % 1000 == 0 ? 0 : 1)}k' : amt}',
                            style: const TextStyle(
                              color: kTextSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 12),

              // ── Numpad ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _NumPad(onTap: _numpadTap),
              ),

              const SizedBox(height: 4),
              const Divider(height: 1, indent: 24, endIndent: 24, color: kDivider),
              const SizedBox(height: 4),

              // ── Details ─────────────────────────────────────────
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                  children: [
                    // Title
                    TextField(
                      controller: _titleController,
                      maxLength: 60,
                      style: theme.textTheme.bodyLarge,
                      decoration: InputDecoration(
                        hintText: 'What was it for?',
                        hintStyle: theme.textTheme.bodyLarge
                            ?.copyWith(color: kTextMuted),
                        counterText: '',
                        border: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      onChanged: (_) => setState(() => _error = null),
                    ),
                    Divider(height: 24, color: kDivider),

                    // Paid by
                    Row(
                      children: [
                        SizedBox(
                          width: 72,
                          child: Text('Paid by',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: kTextSecondary)),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: widget.members.map((m) {
                                final sel = _paidBy == m;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: GestureDetector(
                                    onTap: () =>
                                        setState(() => _paidBy = m),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 140),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 7),
                                      decoration: BoxDecoration(
                                        color: sel
                                            ? kMint
                                            : kBgElevated,
                                        borderRadius:
                                            BorderRadius.circular(20),
                                        border: Border.all(
                                          color: sel
                                              ? kMint
                                              : kDivider,
                                        ),
                                      ),
                                      child: Text(
                                        m,
                                        style: TextStyle(
                                          color: sel ? kBgBase : kTextPrimary,
                                          fontWeight: sel
                                              ? FontWeight.w700
                                              : FontWeight.normal,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Split toggle
                    Row(
                      children: [
                        SizedBox(
                          width: 72,
                          child: Text('Split',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: kTextSecondary)),
                        ),
                        _SplitToggle(
                          value: _splitType,
                          onChanged: (v) =>
                              setState(() => _splitType = v),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Split preview / editor
                    if (_splitType == 'equal')
                      _EqualPreview(
                        members: widget.members,
                        perPerson: hasAmount ? _equalShare : null,
                      )
                    else
                      _CustomEditor(
                        members: widget.members,
                        controllers: _customControllers,
                        remaining: _customRemaining,
                        total: _parsedAmount,
                        onChanged: () => setState(() => _error = null),
                      ),

                    const SizedBox(height: 24),

                    // CTA
                    GestureDetector(
                      onTap: () async {
                        final nav = Navigator.of(context);
                        final ok = await _submit();
                        if (ok) nav.pop();
                      },
                      child: Container(
                        height: 54,
                        decoration: BoxDecoration(
                          color: hasAmount ? kMint : kBgElevated,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: hasAmount
                              ? [
                                  BoxShadow(
                                    color: kMint.withValues(alpha: 0.25),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  )
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          hasAmount
                              ? 'Add ${formatInr(_parsedAmount)}'
                              : 'Add expense',
                          style: TextStyle(
                            color: hasAmount ? kBgBase : kTextMuted,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Numpad ─────────────────────────────────────────────────────────────────────

class _NumPad extends StatelessWidget {
  const _NumPad({required this.onTap});
  final void Function(String) onTap;

  static const _rows = [
    ['1', '2', '3'],
    ['4', '5', '6'],
    ['7', '8', '9'],
    ['.', '0', '⌫'],
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: _rows.map((row) {
        return Row(
          children: row.map((key) {
            return Expanded(
              child: _NumKey(label: key, onTap: () => onTap(key)),
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}

class _NumKey extends StatelessWidget {
  const _NumKey({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: SizedBox(
          height: 46,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: label == '⌫' ? kTextMuted : kTextPrimary,
                fontSize: label == '⌫' ? 20 : 22,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Split toggle ───────────────────────────────────────────────────────────────

class _SplitToggle extends StatelessWidget {
  const _SplitToggle({required this.value, required this.onChanged});
  final String value;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: ['equal', 'custom'].map((v) {
        final sel = value == v;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: GestureDetector(
            onTap: () => onChanged(v),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: sel ? kMint.withValues(alpha: 0.12) : kBgElevated,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: sel ? kMint : kDivider,
                  width: 1.5,
                ),
              ),
              child: Text(
                v[0].toUpperCase() + v.substring(1),
                style: TextStyle(
                  color: sel ? kMint : kTextSecondary,
                  fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Equal split preview ────────────────────────────────────────────────────────

class _EqualPreview extends StatelessWidget {
  const _EqualPreview({required this.members, required this.perPerson});
  final List<String> members;
  final double? perPerson;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: members.map((m) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              _MemberDot(name: m),
              const SizedBox(width: 10),
              Expanded(child: Text(m, style: theme.textTheme.bodyMedium)),
              Text(
                perPerson != null ? formatInr(perPerson!) : '—',
                style: amountStyle(size: 14, color: kTextPrimary),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Custom split editor ────────────────────────────────────────────────────────

class _CustomEditor extends StatelessWidget {
  const _CustomEditor({
    required this.members,
    required this.controllers,
    required this.remaining,
    required this.total,
    required this.onChanged,
  });
  final List<String> members;
  final Map<String, TextEditingController> controllers;
  final double remaining;
  final double total;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settled = remaining.abs() < 0.01 && total > 0;
    final remainingColor =
        settled ? kPositive : remaining < 0 ? kNegative : kTextSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...members.map((m) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                _MemberDot(name: m),
                const SizedBox(width: 10),
                Expanded(child: Text(m, style: theme.textTheme.bodyMedium)),
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: controllers[m],
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.right,
                    style: amountStyle(size: 14, color: kTextPrimary),
                    decoration: InputDecoration(
                      prefixText: '₹ ',
                      isDense: true,
                      filled: true,
                      fillColor: kBgBase,
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: kDivider),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide:
                            const BorderSide(color: kMint, width: 1.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                    ),
                    onChanged: (_) => onChanged(),
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 4),
        Text(
          settled
              ? '✓ Fully assigned'
              : remaining > 0
                  ? '${formatInr(remaining)} unassigned'
                  : '${formatInr(remaining.abs())} over-assigned',
          textAlign: TextAlign.right,
          style: TextStyle(
            fontSize: 12,
            color: remainingColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ── Shared ─────────────────────────────────────────────────────────────────────

class _MemberDot extends StatelessWidget {
  const _MemberDot({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: kMint.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: kMint,
        ),
      ),
    );
  }
}
