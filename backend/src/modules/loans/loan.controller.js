import { loanService } from './loan.service.js';

export const loanController = {
  async create(req, res, next) {
    try {
      const { lenderId, borrowerId, loanType, guestCounterparty, amount, currency, description, notes, dueDate, clientOpId } = req.body;
      const loan = await loanService.create({
        creatorId: req.user.id,
        lenderId,
        borrowerId,
        loanType,
        guestCounterparty,
        amount,
        currency,
        description,
        notes,
        dueDate,
        clientOpId,
      });
      res.status(201).json({ ok: true, data: loan });
    } catch (err) {
      next(err);
    }
  },

  async approve(req, res, next) {
    try {
      const loan = await loanService.approve({ loanId: req.params.id, userId: req.user.id });
      res.json({ ok: true, data: loan });
    } catch (err) {
      next(err);
    }
  },

  async reject(req, res, next) {
    try {
      const loan = await loanService.reject({ loanId: req.params.id, userId: req.user.id });
      res.json({ ok: true, data: loan });
    } catch (err) {
      next(err);
    }
  },

  async recordPayment(req, res, next) {
    try {
      const { amount, note, method, paidAt, clientOpId } = req.body;
      const payment = await loanService.recordPayment({
        loanId: req.params.id,
        userId: req.user.id,
        amount,
        note,
        method,
        paidAt,
        clientOpId,
      });
      res.status(201).json({ ok: true, data: payment });
    } catch (err) {
      next(err);
    }
  },

  async deletePayment(req, res, next) {
    try {
      await loanService.deletePayment({
        paymentId: req.params.paymentId,
        loanId: req.params.id,
        userId: req.user.id,
      });
      res.json({ ok: true });
    } catch (err) {
      next(err);
    }
  },

  async list(req, res, next) {
    try {
      const { status } = req.query;
      const loans = await loanService.listForUser({ userId: req.user.id, status });
      res.json({ ok: true, data: loans });
    } catch (err) {
      next(err);
    }
  },

  async getById(req, res, next) {
    try {
      const loan = await loanService.getById({ loanId: req.params.id, userId: req.user.id });
      res.json({ ok: true, data: loan });
    } catch (err) {
      next(err);
    }
  },

  async deleteLoan(req, res, next) {
    try {
      await loanService.deleteLoan({ loanId: req.params.id, userId: req.user.id });
      res.json({ ok: true });
    } catch (err) {
      next(err);
    }
  },
};
