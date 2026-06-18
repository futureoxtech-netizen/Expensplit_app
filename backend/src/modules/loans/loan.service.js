import { Loan } from './loan.model.js';
import { LoanPayment } from './loan_payment.model.js';
import { User } from '../users/user.model.js';
import { notifyUser } from '../../services/notifications.service.js';
import { activityService } from '../activity/activity.service.js';
import { recordTombstone } from '../sync/tombstone.model.js';
import { BadRequest, NotFound, Forbidden } from '../../utils/errors.js';

// Record a loan event in the (group-less) activity feed for both parties so it
// shows up alongside group activity. Recipients are the real app users involved
// — guest counterparties aren't users, so only the creator sees guest loans.
function logLoanActivity({ actor, recipients, type, message, loanId }) {
  const ids = [...new Set(recipients.filter(Boolean).map((r) => r.toString()))];
  if (!ids.length) return;
  activityService
    .log({
      actor,
      type,
      message,
      recipients: ids,
      meta: { loanId: loanId.toString(), route: `/loans/${loanId.toString()}` },
    })
    .catch(() => {});
}

const POPULATE_USERS = [
  { path: 'lender', select: 'name email avatarUrl' },
  { path: 'borrower', select: 'name email avatarUrl' },
  { path: 'createdBy', select: 'name email avatarUrl' },
];

function loanToJson(loan, payments = []) {
  return {
    _id: loan._id,
    lender: loan.lender,
    borrower: loan.borrower,
    counterpartyType: loan.counterpartyType ?? 'user',
    guestCounterparty: loan.guestCounterparty ?? null,
    amount: loan.amount,
    paidAmount: loan.paidAmount,
    currency: loan.currency,
    description: loan.description,
    notes: loan.notes,
    dueDate: loan.dueDate,
    status: loan.status,
    createdBy: loan.createdBy,
    createdAt: loan.createdAt,
    updatedAt: loan.updatedAt,
    payments,
  };
}

export const loanService = {
  // ── Create a loan ──────────────────────────────────────────────────────────
  // The creator may be either the lender ("I lent X") or the borrower ("I
  // borrowed from X"). The *other* party (the counterparty) must approve.
  // For guest loans, pass loanType + guestCounterparty instead of lenderId/borrowerId.
  async create({ creatorId, lenderId, borrowerId, loanType, guestCounterparty, amount, currency, description, notes, dueDate, clientOpId }) {
    // ── Guest loan: counterparty is not a registered user ───────────────────
    if (guestCounterparty) {
      if (!loanType) throw new BadRequest('loanType is required for guest loans');

      // Idempotency
      if (clientOpId) {
        const existing = await Loan.findOne({ clientOpId }).lean();
        if (existing) return loanToJson(existing);
      }

      const isLender = loanType === 'given';
      const loan = await Loan.create({
        lender: isLender ? creatorId : null,
        borrower: isLender ? null : creatorId,
        counterpartyType: 'guest',
        guestCounterparty: {
          clientId: guestCounterparty.clientId ?? null,
          name: guestCounterparty.name ?? '',
          phone: guestCounterparty.phone ?? null,
          email: guestCounterparty.email ?? null,
          avatarColor: guestCounterparty.avatarColor ?? '#6C5CE7',
        },
        amount,
        currency: currency ?? 'PKR',
        description: description ?? '',
        notes: notes ?? '',
        dueDate: dueDate ? new Date(dueDate) : null,
        status: 'active', // guest loans need no approval
        createdBy: creatorId,
        clientOpId: clientOpId ?? null,
      });
      logLoanActivity({
        actor: creatorId,
        recipients: [creatorId],
        type: 'loan.created',
        message: isLender
          ? `You lent ${guestCounterparty.name || 'a contact'} ${currency ?? 'PKR'} ${amount}.`
          : `You borrowed ${currency ?? 'PKR'} ${amount} from ${guestCounterparty.name || 'a contact'}.`,
        loanId: loan._id,
      });
      return loanToJson(loan.toObject());
    }

    // ── User-to-user loan ───────────────────────────────────────────────────
    const creator = creatorId.toString();
    const lenderStr = lenderId.toString();
    const borrowerStr = borrowerId.toString();
    if (lenderStr === borrowerStr) {
      throw new BadRequest('Lender and borrower must be different people');
    }
    if (creator !== lenderStr && creator !== borrowerStr) {
      throw new Forbidden('You must be a party to this loan');
    }

    // Idempotency: return existing if clientOpId matches.
    if (clientOpId) {
      const existing = await Loan.findOne({ clientOpId })
        .populate(POPULATE_USERS)
        .lean();
      if (existing) return loanToJson(existing);
    }

    const [lender, borrower] = await Promise.all([
      User.findById(lenderId).lean(),
      User.findById(borrowerId).lean(),
    ]);
    if (!lender) throw new NotFound('Lender not found');
    if (!borrower) throw new NotFound('Borrower not found');

    const loan = await Loan.create({
      lender: lenderId,
      borrower: borrowerId,
      counterpartyType: 'user',
      amount,
      currency: currency ?? 'PKR',
      description: description ?? '',
      notes: notes ?? '',
      dueDate: dueDate ? new Date(dueDate) : null,
      status: 'pending_approval',
      createdBy: creatorId,
      clientOpId: clientOpId ?? null,
    });

    const populated = await Loan.findById(loan._id).populate(POPULATE_USERS).lean();

    // Notify the counterparty (the party who didn't create it) to review.
    const creatorIsLender = creator === lenderStr;
    const counterpartyId = creatorIsLender ? borrowerId : lenderId;
    const creatorUser = creatorIsLender ? lender : borrower;
    await notifyUser(counterpartyId, {
      title: `Loan request from ${creatorUser.name}`,
      message: creatorIsLender
        ? `${creatorUser.name} says they lent you ${currency} ${amount}${description ? ` for "${description}"` : ''}. Tap to review.`
        : `${creatorUser.name} says they borrowed ${currency} ${amount} from you${description ? ` for "${description}"` : ''}. Tap to review.`,
      type: 'loan.pending_approval',
      data: { loanId: loan._id.toString(), route: `/loans/${loan._id.toString()}` },
    });

    logLoanActivity({
      actor: creatorId,
      recipients: [lenderId, borrowerId],
      type: 'loan.pending_approval',
      message: `${creatorUser.name} recorded a loan of ${currency ?? 'PKR'} ${amount}${description ? ` for "${description}"` : ''}.`,
      loanId: loan._id,
    });

    return loanToJson(populated);
  },

  // ── Approve a loan ─────────────────────────────────────────────────────────
  // Only the counterparty (the party who didn't create the loan) may approve.
  async approve({ loanId, userId }) {
    const loan = await Loan.findById(loanId).populate(POPULATE_USERS);
    if (!loan || loan.deletedAt) throw new NotFound('Loan not found');
    const uid = userId.toString();
    const lenderId = loan.lender._id.toString();
    const borrowerId = loan.borrower._id.toString();
    if (uid === loan.createdBy.toString() || (uid !== lenderId && uid !== borrowerId)) {
      throw new Forbidden('Only the other party can approve this loan');
    }
    if (loan.status !== 'pending_approval') {
      throw new BadRequest('Loan is not awaiting approval');
    }
    loan.status = 'active';
    await loan.save();

    const approver = uid === lenderId ? loan.lender : loan.borrower;
    await notifyUser(loan.createdBy, {
      title: 'Loan confirmed',
      message: `${approver.name} confirmed the loan of ${loan.currency} ${loan.amount}.`,
      type: 'loan.approved',
      data: { loanId: loanId.toString(), route: `/loans/${loanId.toString()}` },
    });

    logLoanActivity({
      actor: userId,
      recipients: [lenderId, borrowerId],
      type: 'loan.approved',
      message: `${approver.name} confirmed the loan of ${loan.currency} ${loan.amount}.`,
      loanId,
    });

    return loanToJson(loan.toObject());
  },

  // ── Reject a loan ──────────────────────────────────────────────────────────
  // Only the counterparty (the party who didn't create the loan) may reject.
  async reject({ loanId, userId }) {
    const loan = await Loan.findById(loanId).populate(POPULATE_USERS);
    if (!loan || loan.deletedAt) throw new NotFound('Loan not found');
    const uid = userId.toString();
    const lenderId = loan.lender._id.toString();
    const borrowerId = loan.borrower._id.toString();
    if (uid === loan.createdBy.toString() || (uid !== lenderId && uid !== borrowerId)) {
      throw new Forbidden('Only the other party can reject this loan');
    }
    if (loan.status !== 'pending_approval') {
      throw new BadRequest('Loan is not awaiting approval');
    }
    loan.status = 'rejected';
    await loan.save();

    const rejecter = uid === lenderId ? loan.lender : loan.borrower;
    await notifyUser(loan.createdBy, {
      title: 'Loan rejected',
      message: `${rejecter.name} rejected the loan request of ${loan.currency} ${loan.amount}.`,
      type: 'loan.rejected',
      data: { loanId: loanId.toString(), route: `/loans/${loanId.toString()}` },
    });

    logLoanActivity({
      actor: userId,
      recipients: [lenderId, borrowerId],
      type: 'loan.rejected',
      message: `${rejecter.name} rejected the loan request of ${loan.currency} ${loan.amount}.`,
      loanId,
    });

    return loanToJson(loan.toObject());
  },

  // ── Record a payment ───────────────────────────────────────────────────────
  async recordPayment({ loanId, userId, amount, note, method, paidAt, clientOpId }) {
    const loan = await Loan.findById(loanId).populate(POPULATE_USERS);
    if (!loan || loan.deletedAt) throw new NotFound('Loan not found');
    const lenderId = loan.lender._id.toString();
    const borrowerId = loan.borrower._id.toString();
    const uid = userId.toString();
    if (uid !== lenderId && uid !== borrowerId) {
      throw new Forbidden('Only lender or borrower can record payments');
    }
    if (loan.status === 'rejected') throw new BadRequest('Cannot add payment to a rejected loan');

    // Idempotency
    if (clientOpId) {
      const existing = await LoanPayment.findOne({ clientOpId }).lean();
      if (existing) return existing;
    }

    const payment = await LoanPayment.create({
      loan: loanId,
      amount,
      note: note ?? '',
      method: method ?? 'cash',
      paidAt: paidAt ? new Date(paidAt) : new Date(),
      recordedBy: userId,
      clientOpId: clientOpId ?? null,
    });

    // Update the loan's paidAmount and possibly settle it.
    const allPayments = await LoanPayment.find({ loan: loanId, deletedAt: null }).lean();
    const totalPaid = allPayments.reduce((s, p) => s + p.amount, 0);
    loan.paidAmount = Math.min(totalPaid, loan.amount);
    if (loan.paidAmount >= loan.amount) loan.status = 'settled';
    else if (loan.status !== 'active') loan.status = 'active'; // reactivate if was pending
    await loan.save();

    // Notify the other party.
    const otherId = uid === lenderId ? borrowerId : lenderId;
    const actor = uid === lenderId ? loan.lender : loan.borrower;
    await notifyUser(otherId, {
      title: 'Payment recorded',
      message: `${actor.name} recorded a payment of ${loan.currency} ${amount} on your loan.`,
      type: 'loan.payment',
      data: { loanId: loanId.toString(), route: `/loans/${loanId.toString()}` },
    });

    logLoanActivity({
      actor: userId,
      recipients: [lenderId, borrowerId],
      type: 'loan.payment',
      message: `${actor.name} recorded a payment of ${loan.currency} ${amount}.`,
      loanId,
    });

    return payment;
  },

  // ── List loans for a user ──────────────────────────────────────────────────
  async listForUser({ userId, status }) {
    const filter = {
      $or: [{ lender: userId }, { borrower: userId }],
      deletedAt: null,
    };
    if (status) filter.status = status;

    const loans = await Loan.find(filter)
      .sort({ updatedAt: -1 })
      .populate(POPULATE_USERS)
      .lean();

    return Promise.all(
      loans.map(async (loan) => {
        const payments = await LoanPayment.find({ loan: loan._id, deletedAt: null })
          .sort({ paidAt: -1 })
          .lean();
        return loanToJson(loan, payments);
      })
    );
  },

  // ── Get a single loan ──────────────────────────────────────────────────────
  async getById({ loanId, userId }) {
    const loan = await Loan.findById(loanId).populate(POPULATE_USERS).lean();
    if (!loan || loan.deletedAt) throw new NotFound('Loan not found');
    const lenderId = loan.lender._id.toString();
    const borrowerId = loan.borrower._id.toString();
    if (userId.toString() !== lenderId && userId.toString() !== borrowerId) {
      throw new Forbidden('Access denied');
    }
    const payments = await LoanPayment.find({ loan: loanId, deletedAt: null })
      .sort({ paidAt: -1 })
      .lean();
    return loanToJson(loan, payments);
  },

  // ── Delete a loan (soft) ───────────────────────────────────────────────────
  async deleteLoan({ loanId, userId }) {
    const loan = await Loan.findById(loanId);
    if (!loan || loan.deletedAt) throw new NotFound('Loan not found');
    if (loan.createdBy.toString() !== userId.toString()) {
      throw new Forbidden('Only the creator can delete this loan');
    }
    loan.deletedAt = new Date();
    await loan.save();
    // Tombstone so the OTHER party's device drops the loan too. Without this the
    // delta sync just stops returning the (now deletedAt) loan, so the
    // counterparty keeps a stale copy forever. Both parties are recipients; the
    // creator's own device already hard-deleted it locally (a no-op there).
    recordTombstone({
      entityType: 'loan',
      entityId: loan._id,
      users: [loan.lender, loan.borrower].filter(Boolean),
    }).catch(() => {});
    return { ok: true };
  },

  // ── Delete a payment ───────────────────────────────────────────────────────
  async deletePayment({ paymentId, loanId, userId }) {
    const payment = await LoanPayment.findOne({ _id: paymentId, loan: loanId });
    if (!payment || payment.deletedAt) throw new NotFound('Payment not found');
    if (payment.recordedBy.toString() !== userId.toString()) {
      throw new Forbidden('Only the recorder can delete this payment');
    }
    payment.deletedAt = new Date();
    await payment.save();

    // Recalculate paidAmount.
    const loan = await Loan.findById(loanId);
    if (loan) {
      const allPayments = await LoanPayment.find({ loan: loanId, deletedAt: null }).lean();
      loan.paidAmount = Math.min(
        allPayments.reduce((s, p) => s + p.amount, 0),
        loan.amount
      );
      if (loan.status === 'settled' && loan.paidAmount < loan.amount) {
        loan.status = 'active';
      }
      await loan.save();
    }
    return { ok: true };
  },

  // ── Delta sync: loans for user changed since a timestamp ──────────────────
  async deltaSince({ userId, since, limit = 300 }) {
    const sinceDate = since ? new Date(since) : null;
    const changedSince = sinceDate && !Number.isNaN(sinceDate.getTime())
      ? { updatedAt: { $gt: sinceDate } }
      : {};

    const loans = await Loan.find({
      $or: [{ lender: userId }, { borrower: userId }],
      deletedAt: null,
      ...changedSince,
    })
      .sort({ updatedAt: 1 })
      .limit(limit)
      .populate(POPULATE_USERS)
      .lean();

    return Promise.all(
      loans.map(async (loan) => {
        const payments = await LoanPayment.find({ loan: loan._id, deletedAt: null })
          .sort({ paidAt: -1 })
          .lean();
        return loanToJson(loan, payments);
      })
    );
  },
};
