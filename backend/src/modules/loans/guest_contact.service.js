import { GuestContact } from './guest_contact.model.js';
import { NotFound, Forbidden } from '../../utils/errors.js';

export const guestContactService = {
  async create({ ownerId, name, phone, email, avatarColor, clientId }) {
    // Idempotency: return existing row if clientId matches.
    if (clientId) {
      const existing = await GuestContact.findOne({ clientId }).lean();
      if (existing) return existing;
    }
    const gc = await GuestContact.create({
      owner: ownerId,
      name,
      phone: phone ?? null,
      email: email ?? null,
      avatarColor: avatarColor ?? '#6C5CE7',
      clientId: clientId ?? null,
    });
    return gc.toObject();
  },

  async update({ contactId, ownerId, name, phone, email, avatarColor }) {
    const gc = await GuestContact.findOne({ _id: contactId, owner: ownerId, deletedAt: null });
    if (!gc) throw new NotFound('Guest contact not found');
    if (name !== undefined) gc.name = name;
    if (phone !== undefined) gc.phone = phone;
    if (email !== undefined) gc.email = email;
    if (avatarColor !== undefined) gc.avatarColor = avatarColor;
    await gc.save();
    return gc.toObject();
  },

  async delete({ contactId, ownerId }) {
    const gc = await GuestContact.findOne({ _id: contactId, owner: ownerId, deletedAt: null });
    if (!gc) throw new NotFound('Guest contact not found');
    gc.deletedAt = new Date();
    await gc.save();
  },

  async listForUser({ ownerId }) {
    return GuestContact.find({ owner: ownerId, deletedAt: null }).lean();
  },

  async deltaSince({ ownerId, since, limit = 300 }) {
    const sinceDate = since ? new Date(since) : null;
    const changedSince =
      sinceDate && !Number.isNaN(sinceDate.getTime()) ? { updatedAt: { $gt: sinceDate } } : {};
    // Return both active and soft-deleted contacts that changed, so the client
    // can apply deletions on other devices.
    return GuestContact.find({ owner: ownerId, ...changedSince })
      .sort({ updatedAt: 1 })
      .limit(limit)
      .lean();
  },
};
