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
import { BadRequest } from './errors.js';

export function computeShares({ total, mode, splits }) {
  if (!Array.isArray(splits) || splits.length === 0) {
    throw BadRequest('Pick at least one participant to split with', 'SPLIT_EMPTY');
  }
  const round = (n) => Math.round(n * 100) / 100;
  let shares;

  if (mode === 'equal') {
    const each = total / splits.length;
    shares = splits.map((s) => ({ userId: s.userId, amount: round(each) }));
  } else if (mode === 'exact') {
    const sum = splits.reduce((a, s) => a + Number(s.value || 0), 0);
    if (Math.abs(sum - total) > 0.01) {
      throw BadRequest(
        `Exact amounts must add up to the total (${round(sum)} of ${round(total)})`,
        'SPLIT_EXACT_MISMATCH',
      );
    }
    shares = splits.map((s) => ({ userId: s.userId, amount: round(Number(s.value)) }));
  } else if (mode === 'percent') {
    const sum = splits.reduce((a, s) => a + Number(s.value || 0), 0);
    if (Math.abs(sum - 100) > 0.01) {
      throw BadRequest(
        `Percentages must add up to 100% (currently ${round(sum)}%)`,
        'SPLIT_PERCENT_MISMATCH',
      );
    }
    shares = splits.map((s) => ({ userId: s.userId, amount: round((Number(s.value) / 100) * total) }));
  } else if (mode === 'shares') {
    const sum = splits.reduce((a, s) => a + Number(s.value || 0), 0);
    if (sum <= 0) throw BadRequest('Share weights must be greater than zero', 'SPLIT_SHARES_INVALID');
    shares = splits.map((s) => ({ userId: s.userId, amount: round((Number(s.value) / sum) * total) }));
  } else {
    throw BadRequest(`Unknown split mode: ${mode}`, 'SPLIT_MODE_INVALID');
  }

  // Reconcile rounding residual onto the first participant
  const sumShares = shares.reduce((a, s) => a + s.amount, 0);
  const residual = round(total - sumShares);
  if (Math.abs(residual) >= 0.01) {
    shares[0].amount = round(shares[0].amount + residual);
  }
  return shares;
}
