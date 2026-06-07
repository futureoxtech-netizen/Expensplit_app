import { Expense } from '../modules/expenses/expense.model.js';
import { Settlement } from '../modules/settlements/settlement.model.js';
import { Group } from '../modules/groups/group.model.js';
import { PersonalExpense } from '../modules/personal/personal.model.js';
import { Goal } from '../modules/goals/goal.model.js';
import { logger } from './logger.js';

// Reconcile indexes for the offline-first models. Their `clientOpId` unique
// index changed from `sparse` to a `partial` filter (so the many rows with
// clientOpId:null don't collide). `autoIndex` can't alter an existing index in
// place, so we run `syncIndexes()` once on boot — it drops the obsolete index
// and creates the new one. It's a no-op when the indexes already match.
export async function syncOfflineIndexes() {
  for (const Model of [Expense, Settlement, Group, PersonalExpense, Goal]) {
    try {
      await Model.syncIndexes();
    } catch (err) {
      logger.warn({ err, model: Model.modelName }, 'Index sync failed (continuing)');
    }
  }
  logger.info('Offline-first indexes reconciled');
}
