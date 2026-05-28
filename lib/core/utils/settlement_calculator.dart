class Transfer {
  const Transfer({
    required this.from,
    required this.to,
    required this.amount,
  });

  final String from;
  final String to;
  final double amount;
}

/// Greedy debt simplification.
/// Input: map of memberId → netAmount (positive = owed, negative = owes).
/// Output: minimum list of transfers that settles all debts.
List<Transfer> simplifyDebts(Map<String, double> netBalances) {
  final creditors = <MapEntry<String, double>>[];
  final debtors = <MapEntry<String, double>>[];

  for (final entry in netBalances.entries) {
    if (entry.value > 0.01) {
      creditors.add(entry);
    } else if (entry.value < -0.01) {
      debtors.add(MapEntry(entry.key, -entry.value)); // store as positive
    }
  }

  // Sort descending so we match largest first
  creditors.sort((a, b) => b.value.compareTo(a.value));
  debtors.sort((a, b) => b.value.compareTo(a.value));

  final transfers = <Transfer>[];
  var ci = 0;
  var di = 0;
  var creditLeft = ci < creditors.length ? creditors[ci].value : 0.0;
  var debtLeft = di < debtors.length ? debtors[di].value : 0.0;

  while (ci < creditors.length && di < debtors.length) {
    final settle = creditLeft < debtLeft ? creditLeft : debtLeft;

    if (settle > 0.01) {
      transfers.add(Transfer(
        from: debtors[di].key,
        to: creditors[ci].key,
        amount: double.parse(settle.toStringAsFixed(2)),
      ));
    }

    creditLeft -= settle;
    debtLeft -= settle;

    if (creditLeft < 0.01) {
      ci++;
      creditLeft = ci < creditors.length ? creditors[ci].value : 0.0;
    }
    if (debtLeft < 0.01) {
      di++;
      debtLeft = di < debtors.length ? debtors[di].value : 0.0;
    }
  }

  return transfers;
}
