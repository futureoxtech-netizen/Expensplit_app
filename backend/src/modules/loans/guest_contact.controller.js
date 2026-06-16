import { guestContactService } from './guest_contact.service.js';

export const guestContactController = {
  async list(req, res, next) {
    try {
      const contacts = await guestContactService.listForUser({ ownerId: req.user.id });
      res.json({ ok: true, data: contacts });
    } catch (err) {
      next(err);
    }
  },

  async create(req, res, next) {
    try {
      const { name, phone, email, avatarColor, clientId } = req.body;
      const contact = await guestContactService.create({
        ownerId: req.user.id,
        name,
        phone,
        email,
        avatarColor,
        clientId,
      });
      res.status(201).json({ ok: true, data: contact });
    } catch (err) {
      next(err);
    }
  },

  async update(req, res, next) {
    try {
      const { name, phone, email, avatarColor } = req.body;
      const contact = await guestContactService.update({
        contactId: req.params.id,
        ownerId: req.user.id,
        name,
        phone,
        email,
        avatarColor,
      });
      res.json({ ok: true, data: contact });
    } catch (err) {
      next(err);
    }
  },

  async delete(req, res, next) {
    try {
      await guestContactService.delete({ contactId: req.params.id, ownerId: req.user.id });
      res.json({ ok: true });
    } catch (err) {
      next(err);
    }
  },
};
