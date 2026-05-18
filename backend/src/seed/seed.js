import 'dotenv/config';
import mongoose from 'mongoose';
import bcrypt from 'bcryptjs';
import { env } from '../config/env.js';
import { User } from '../modules/users/user.model.js';
import { Group } from '../modules/groups/group.model.js';
import { Expense } from '../modules/expenses/expense.model.js';
import { computeShares } from '../utils/splitCalculator.js';

async function main() {
  await mongoose.connect(env.MONGO_URI);
  console.log('Connected to Mongo for seeding');

  await Promise.all([
    User.deleteMany({ email: { $in: ['alice@demo.io', 'bob@demo.io', 'cara@demo.io'] } }),
    Group.deleteMany({ name: 'Weekend Trip' }),
  ]);

  const passwordHash = await bcrypt.hash('password123', 10);
  const [alice, bob, cara] = await User.create([
    { name: 'Alice', email: 'alice@demo.io', passwordHash, currency: 'USD', referralCode: 'ALICE001' },
    { name: 'Bob', email: 'bob@demo.io', passwordHash, currency: 'USD', referralCode: 'BOB00001' },
    { name: 'Cara', email: 'cara@demo.io', passwordHash, currency: 'USD', referralCode: 'CARA0001' },
  ]);

  const group = await Group.create({
    name: 'Weekend Trip',
    description: 'Lake house getaway',
    category: 'trip',
    coverColor: '#6C5CE7',
    currency: 'USD',
    members: [
      { user: alice._id, role: 'owner' },
      { user: bob._id, role: 'member' },
      { user: cara._id, role: 'member' },
    ],
    createdBy: alice._id,
  });

  const sampleExpenses = [
    { description: 'Groceries', amount: 120, paidBy: alice._id, category: 'groceries', mode: 'equal' },
    { description: 'Gas', amount: 60, paidBy: bob._id, category: 'transport', mode: 'equal' },
    {
      description: 'Cabin rental',
      amount: 450,
      paidBy: cara._id,
      category: 'rent',
      mode: 'percent',
      splits: [
        { userId: alice._id.toString(), value: 40 },
        { userId: bob._id.toString(), value: 30 },
        { userId: cara._id.toString(), value: 30 },
      ],
    },
  ];

  for (const e of sampleExpenses) {
    const splits =
      e.splits ||
      [alice, bob, cara].map((u) => ({ userId: u._id.toString() }));
    const shares = computeShares({ total: e.amount, mode: e.mode, splits });
    await Expense.create({
      group: group._id,
      description: e.description,
      amount: e.amount,
      currency: 'USD',
      category: e.category,
      splitMode: e.mode,
      paidBy: e.paidBy,
      shares: shares.map((s) => ({ user: s.userId, amount: s.amount })),
      createdBy: e.paidBy,
    });
  }

  console.log('\nSeed complete.');
  console.log('Login with:');
  console.log('  alice@demo.io / password123');
  console.log('  bob@demo.io   / password123');
  console.log('  cara@demo.io  / password123');
  console.log(`Group invite code: ${group.inviteCode}`);

  await mongoose.disconnect();
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
