/// Dart port of the backend `splitCalculator` + payer resolution, so an expense
/// added offline produces the same shares/payers locally as the server would.

class ShareResult {
  ShareResult(this.userId, this.amount);
  final String userId;
  final double amount;
}

double _round2(double n) => (n * 100).round() / 100;

/// Returns each participant's share. `splits` is `[{userId, value?}]`.
/// Throws [ArgumentError] with a friendly message on invalid input (mirrors the
/// server's BadRequest messages so offline validation matches online).
List<ShareResult> computeShares({
  required double total,
  required String mode,
  required List<Map<String, dynamic>> splits,
}) {
  if (splits.isEmpty) {
    throw ArgumentError('Pick at least one participant to split with');
  }
  List<ShareResult> shares;
  double valueOf(Map<String, dynamic> s) => (s['value'] as num?)?.toDouble() ?? 0;

  switch (mode) {
    case 'equal':
      final each = total / splits.length;
      shares = [for (final s in splits) ShareResult(s['userId'].toString(), _round2(each))];
      break;
    case 'exact':
      final sum = splits.fold<double>(0, (a, s) => a + valueOf(s));
      if ((sum - total).abs() > 0.01) {
        throw ArgumentError(
            'Exact amounts must add up to the total (${_round2(sum)} of ${_round2(total)})');
      }
      shares = [for (final s in splits) ShareResult(s['userId'].toString(), _round2(valueOf(s)))];
      break;
    case 'percent':
      final sum = splits.fold<double>(0, (a, s) => a + valueOf(s));
      if ((sum - 100).abs() > 0.01) {
        throw ArgumentError('Percentages must add up to 100% (currently ${_round2(sum)}%)');
      }
      shares = [
        for (final s in splits) ShareResult(s['userId'].toString(), _round2(valueOf(s) / 100 * total))
      ];
      break;
    case 'shares':
      final sum = splits.fold<double>(0, (a, s) => a + valueOf(s));
      if (sum <= 0) throw ArgumentError('Share weights must be greater than zero');
      shares = [
        for (final s in splits) ShareResult(s['userId'].toString(), _round2(valueOf(s) / sum * total))
      ];
      break;
    default:
      throw ArgumentError('Unknown split mode: $mode');
  }

  // Reconcile rounding residual onto the first participant.
  final sumShares = shares.fold<double>(0, (a, s) => a + s.amount);
  final residual = _round2(total - sumShares);
  if (residual.abs() >= 0.01) {
    shares[0] = ShareResult(shares[0].userId, _round2(shares[0].amount + residual));
  }
  return shares;
}

/// Normalises payer input into `(paidBy, payers)`. `payers` is empty for a
/// single-payer expense. Throws [ArgumentError] if multi-payer amounts don't
/// add up to [total].
({String paidBy, List<ShareResult> payers}) resolvePayers({
  required String paidBy,
  required List<Map<String, dynamic>> payers,
  required double total,
}) {
  final nonZero = payers.where((p) => ((p['amount'] as num?)?.toDouble() ?? 0) > 0).toList();
  if (nonZero.length <= 1) {
    final single = nonZero.isNotEmpty ? nonZero.first['userId'].toString() : paidBy;
    return (paidBy: single, payers: <ShareResult>[]);
  }
  final sum = nonZero.fold<double>(0, (a, p) => a + ((p['amount'] as num).toDouble()));
  if ((sum - total).abs() > 0.01) {
    throw ArgumentError('Payer amounts must add up to the total (${_round2(sum)} of ${_round2(total)})');
  }
  final list = [for (final p in nonZero) ShareResult(p['userId'].toString(), _round2((p['amount'] as num).toDouble()))];
  final primary = list.reduce((a, b) => b.amount > a.amount ? b : a);
  return (paidBy: primary.userId, payers: list);
}
