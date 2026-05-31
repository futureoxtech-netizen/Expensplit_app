import { asyncHandler } from '../../utils/asyncHandler.js';
import { BadRequest } from '../../utils/errors.js';
import { uploadToS3, deleteFromS3 } from '../../middleware/upload.js';

export const uploadController = {
  // POST /uploads/receipt  (multipart/form-data, field: "image")
  // The client compresses and size-checks before sending; this just stores
  // the image and hands back a URL to attach to an expense on save.
  receipt: asyncHandler(async (req, res) => {
    if (!req.file) throw BadRequest('No image file provided');
    const url = await uploadToS3(req.file.buffer, req.file.mimetype, 'receipts');
    if (!url) throw BadRequest('Receipt upload failed — please try again');
    res.json({ ok: true, data: { url } });
  }),

  // DELETE /uploads/receipt  { url }
  // Best-effort cleanup for an orphaned receipt — i.e. one the client uploaded
  // but then failed to attach (the expense save errored out). Restricted to
  // the `receipts/` namespace so it can't be used to delete other objects.
  deleteReceipt: asyncHandler(async (req, res) => {
    const url = (req.body?.url ?? req.query?.url ?? '').toString();
    if (url && url.includes('/receipts/')) {
      await deleteFromS3(url);
    }
    res.json({ ok: true });
  }),
};
