// Shared definition of a "payment method / payment information" record.
//
// The same shape is embedded in two places:
//   • User.paymentMethods   — the methods a user saves on their own profile so
//                             they can reuse ("import") them later.
//   • Group.paymentInfos    — the payment details a member shares inside a
//                             group so the people who owe them can pay back.
//
// `accountNumber` is the catch-all "where to send the money" value: an IBAN, a
// wallet phone number (EasyPaisa / JazzCash), a PayPal email, a UPI id, etc.

export const PAYMENT_TYPES = [
  'bank',
  'easypaisa',
  'jazzcash',
  'sadapay',
  'nayapay',
  'raast',
  'paypal',
  'wise',
  'upi',
  'card',
  'crypto',
  'other',
];

// Plain field map reused by both embedded sub-schemas. Kept as a factory so the
// two Mongoose sub-schemas don't accidentally share one mutable object.
export const paymentMethodFields = () => ({
  type: { type: String, enum: PAYMENT_TYPES, default: 'other' },
  label: { type: String, default: '', trim: true, maxlength: 60 },
  accountName: { type: String, default: '', trim: true, maxlength: 80 },
  accountNumber: { type: String, default: '', trim: true, maxlength: 120 },
  bankName: { type: String, default: '', trim: true, maxlength: 80 },
  note: { type: String, default: '', trim: true, maxlength: 200 },
});

/** Serialise an embedded payment sub-document to the client shape. */
export function paymentToJson(pm) {
  return {
    id: pm._id.toString(),
    type: pm.type ?? 'other',
    label: pm.label ?? '',
    accountName: pm.accountName ?? '',
    accountNumber: pm.accountNumber ?? '',
    bankName: pm.bankName ?? '',
    note: pm.note ?? '',
  };
}
