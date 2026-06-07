/**
 * Multi-payer support. An expense may be paid by several people, each covering
 * part of the total (stored in `expense.payers`). Older / single-payer expenses
 * only have `paidBy` + the full `amount`.
 *
 * `effectivePayers` normalises both shapes into a `[{ user, amount }]` list so
 * balance math has a single code path.
 */
export function effectivePayers(exp) {
  if (Array.isArray(exp.payers) && exp.payers.length > 0) {
    return exp.payers
      .filter((p) => p && p.user)
      .map((p) => ({ user: p.user, amount: Number(p.amount) || 0 }));
  }
  if (exp.paidBy) {
    return [{ user: exp.paidBy, amount: Number(exp.amount) || 0 }];
  }
  return [];
}

/**
 * Net amount between two users contributed by a single expense.
 * Positive  → `friendId` owes `meId`.
 * Negative  → `meId` owes `friendId`.
 *
 * Each sharer's debt is split across the payers in proportion to how much each
 * payer covered — the standard Splitwise convention, and a faithful
 * generalisation of the single-payer case.
 */
export function pairwiseNetForExpense(exp, meId, friendId) {
  const payers = effectivePayers(exp);
  const totalPaid = payers.reduce((a, p) => a + p.amount, 0);
  if (totalPaid <= 0) return 0;

  let net = 0;
  for (const s of exp.shares ?? []) {
    if (!s.user) continue;
    const debtor = s.user.toString();
    if (debtor !== meId && debtor !== friendId) continue;
    for (const p of payers) {
      const payer = p.user.toString();
      if (payer === debtor) continue; // you never owe yourself
      const portion = s.amount * (p.amount / totalPaid);
      if (debtor === meId && payer === friendId) net -= portion;
      else if (debtor === friendId && payer === meId) net += portion;
    }
  }
  return net;
}
