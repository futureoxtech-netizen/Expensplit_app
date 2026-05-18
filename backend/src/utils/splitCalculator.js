/**
 * Compute each participant's share of an expense.
 * mode: 'equal' | 'exact' | 'percent' | 'shares'
 * splits: [{ userId, value? }]
 *   - equal: value ignored
 *   - exact: value = amount (must sum to total)
 *   - percent: value = 0-100 (must sum to 100)
 *   - shares: value = positive weight
 *
 * Returns: [{ userId, amount }] (rounded to 2dp, residual goes to first participant)
 */
export function computeShares({ total, mode, splits }) {
  if (!Array.isArray(splits) || splits.length === 0) {
    throw new Error('splits must be a non-empty array');
  }
  const round = (n) => Math.round(n * 100) / 100;
  let shares;

  if (mode === 'equal') {
    const each = total / splits.length;
    shares = splits.map((s) => ({ userId: s.userId, amount: round(each) }));
  } else if (mode === 'exact') {
    const sum = splits.reduce((a, s) => a + Number(s.value || 0), 0);
    if (Math.abs(sum - total) > 0.01) {
      throw new Error(`Exact splits must sum to total (${sum} vs ${total})`);
    }
    shares = splits.map((s) => ({ userId: s.userId, amount: round(Number(s.value)) }));
  } else if (mode === 'percent') {
    const sum = splits.reduce((a, s) => a + Number(s.value || 0), 0);
    if (Math.abs(sum - 100) > 0.01) {
      throw new Error(`Percent splits must sum to 100 (got ${sum})`);
    }
    shares = splits.map((s) => ({ userId: s.userId, amount: round((Number(s.value) / 100) * total) }));
  } else if (mode === 'shares') {
    const sum = splits.reduce((a, s) => a + Number(s.value || 0), 0);
    if (sum <= 0) throw new Error('Share weights must be positive');
    shares = splits.map((s) => ({ userId: s.userId, amount: round((Number(s.value) / sum) * total) }));
  } else {
    throw new Error(`Unknown split mode: ${mode}`);
  }

  // Reconcile rounding residual onto the first participant
  const sumShares = shares.reduce((a, s) => a + s.amount, 0);
  const residual = round(total - sumShares);
  if (Math.abs(residual) >= 0.01) {
    shares[0].amount = round(shares[0].amount + residual);
  }
  return shares;
}
