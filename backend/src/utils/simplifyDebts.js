/**
 * Greedy debt simplification.
 * Input: array of { userId, net } where positive = owed money, negative = owes money.
 * Output: array of { from, to, amount } transfers that settle all balances.
 */
export function simplifyDebts(balances) {
  const debtors = [];
  const creditors = [];
  for (const b of balances) {
    const net = Math.round(b.net * 100) / 100;
    if (net < -0.009) debtors.push({ userId: b.userId, amount: -net });
    else if (net > 0.009) creditors.push({ userId: b.userId, amount: net });
  }
  debtors.sort((a, b) => b.amount - a.amount);
  creditors.sort((a, b) => b.amount - a.amount);

  const transfers = [];
  let i = 0;
  let j = 0;
  while (i < debtors.length && j < creditors.length) {
    const pay = Math.min(debtors[i].amount, creditors[j].amount);
    const amount = Math.round(pay * 100) / 100;
    if (amount > 0) {
      transfers.push({ from: debtors[i].userId, to: creditors[j].userId, amount });
    }
    debtors[i].amount -= pay;
    creditors[j].amount -= pay;
    if (debtors[i].amount < 0.01) i += 1;
    if (creditors[j].amount < 0.01) j += 1;
  }
  return transfers;
}
