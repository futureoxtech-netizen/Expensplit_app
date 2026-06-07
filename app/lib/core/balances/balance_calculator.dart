/// Pure offline port of the backend balance math (group balances, debt
/// simplification, and pairwise friend nets). Operates on plain structures the
/// [LocalStore] assembles from Drift rows, so balances work with no network.

class PayerAmt {
  PayerAmt(this.userId, this.amount);
  final String userId;
  final double amount;
}

class ExpenseCalc {
  ExpenseCalc({required this.payers, required this.shares});

  /// Effective payers: the multi-payer breakdown, or a single `[paidBy:amount]`.
  final List<PayerAmt> payers;
  final List<PayerAmt> shares;
}

class SettlementCalc {
  SettlementCalc({required this.from, required this.to, required this.amount});
  final String from;
  final String to;
  final double amount;
}

class Transfer {
  Transfer(this.from, this.to, this.amount);
  final String from;
  final String to;
  final double amount;
}

double _r2(double n) => (n * 100).round() / 100;

/// Net per user inside a group. >0 owed money, <0 owes money.
Map<String, double> groupNets(
  Iterable<String> memberIds,
  List<ExpenseCalc> expenses,
  List<SettlementCalc> settlements,
) {
  final nets = <String, double>{for (final id in memberIds) id: 0};
  void add(String id, double v) => nets[id] = (nets[id] ?? 0) + v;
  for (final e in expenses) {
    for (final p in e.payers) {
      add(p.userId, p.amount);
    }
    for (final s in e.shares) {
      add(s.userId, -s.amount);
    }
  }
  for (final st in settlements) {
    add(st.from, st.amount);
    add(st.to, -st.amount);
  }
  return {for (final entry in nets.entries) entry.key: _r2(entry.value)};
}

/// Greedy debt simplification — same algorithm as the backend.
List<Transfer> simplifyDebts(Map<String, double> nets) {
  final debtors = <PayerAmt>[];
  final creditors = <PayerAmt>[];
  nets.forEach((id, raw) {
    final net = _r2(raw);
    if (net < -0.009) debtors.add(PayerAmt(id, -net));
    else if (net > 0.009) creditors.add(PayerAmt(id, net));
  });
  debtors.sort((a, b) => b.amount.compareTo(a.amount));
  creditors.sort((a, b) => b.amount.compareTo(a.amount));

  final transfers = <Transfer>[];
  var i = 0, j = 0;
  var dRem = debtors.map((d) => d.amount).toList();
  var cRem = creditors.map((c) => c.amount).toList();
  while (i < debtors.length && j < creditors.length) {
    final pay = dRem[i] < cRem[j] ? dRem[i] : cRem[j];
    final amount = _r2(pay);
    if (amount > 0) transfers.add(Transfer(debtors[i].userId, creditors[j].userId, amount));
    dRem[i] -= pay;
    cRem[j] -= pay;
    if (dRem[i] < 0.01) i += 1;
    if (cRem[j] < 0.01) j += 1;
  }
  return transfers;
}

/// Net between two users from one expense. >0 friend owes me, <0 I owe friend.
double pairwiseNet(ExpenseCalc e, String meId, String friendId) {
  final totalPaid = e.payers.fold<double>(0, (a, p) => a + p.amount);
  if (totalPaid <= 0) return 0;
  var net = 0.0;
  for (final s in e.shares) {
    final debtor = s.userId;
    if (debtor != meId && debtor != friendId) continue;
    for (final p in e.payers) {
      if (p.userId == debtor) continue;
      final portion = s.amount * (p.amount / totalPaid);
      if (debtor == meId && p.userId == friendId) net -= portion;
      else if (debtor == friendId && p.userId == meId) net += portion;
    }
  }
  return net;
}
