import nodemailer from 'nodemailer';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { env } from '../config/env.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// Logo embedded as a CID attachment so it shows up inline even on
// clients that block remote images. Lives in app/assets/images/logo.png
// in the monorepo — we resolve from this file regardless of cwd.
const LOGO_PATH = path.resolve(__dirname, '../../../app/assets/images/logo.png');
const LOGO_CID = 'expensplit-logo';

const transporter = nodemailer.createTransport({
  host: env.SMTP_HOST,
  port: Number(env.SMTP_PORT),
  secure: false,      // STARTTLS — upgrades after EHLO
  requireTLS: true,   // fail if server doesn't offer STARTTLS
  auth: { user: env.SMTP_USER, pass: env.SMTP_PASS },
  tls: { rejectUnauthorized: false }, // allow self-signed certs on private mail
});

function emailShell(title, intro, code, expiryMins = 10, accent = '#6C5CE7') {
  // Note: email clients (Gmail in particular) strip `display:flex`,
  // `gap`, and `-webkit-background-clip:text`. Use tables for layout
  // and solid colours for branding so it renders identically across
  // Gmail, Outlook, Apple Mail, mobile previews, etc.
  return `
    <div style="font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Arial,sans-serif;max-width:480px;margin:0 auto;padding:20px;color:#0B0B12;background:#F7F7FB">
      <!-- Header: logo + wordmark, side-by-side via table for email safety -->
      <table cellpadding="0" cellspacing="0" border="0" role="presentation" style="margin:0 0 18px 0">
        <tr>
          <td style="vertical-align:middle;padding-right:12px">
            <img src="cid:${LOGO_CID}" width="40" height="40" alt="Expensplit"
                 style="display:block;border:0;border-radius:10px;background:#ffffff" />
          </td>
          <td style="vertical-align:middle">
            <span style="font-size:22px;font-weight:800;letter-spacing:-0.3px;color:#6C5CE7;line-height:1">Expensplit</span>
          </td>
        </tr>
      </table>

      <!-- Card -->
      <div style="background:#ffffff;border-radius:14px;padding:24px;border:1px solid #EAEAF2">
        <p style="font-size:20px;font-weight:800;margin:0 0 10px 0;color:#0B0B12">${title}</p>
        <p style="margin:0 0 22px 0;color:#555555;line-height:1.55;font-size:14px">${intro}</p>

        <!-- OTP: nowrap + tight letter-spacing so all 6 digits fit on one line in narrow Gmail previews -->
        <div style="background:${accent}14;border:1px solid ${accent}33;border-radius:14px;padding:16px 12px;text-align:center">
          <span style="display:inline-block;font-size:28px;font-weight:800;letter-spacing:5px;color:#0B0B12;font-family:'SF Mono',Menlo,Consolas,monospace;white-space:nowrap">
            ${code}
          </span>
        </div>

        <p style="color:#777777;font-size:13px;margin:22px 0 0 0;line-height:1.5">
          This code expires in <strong>${expiryMins} minutes</strong>.<br/>
          If you didn't request this, you can safely ignore this email.
        </p>
      </div>

      <p style="color:#A0A0B0;font-size:11px;margin-top:20px;text-align:center;line-height:1.5">
        Sent by Expensplit · Please do not reply to this email.
      </p>
    </div>`;
}

const logoAttachment = {
  filename: 'logo.png',
  path: LOGO_PATH,
  cid: LOGO_CID,
};

export async function sendPasswordResetEmail(to, otp) {
  await transporter.sendMail({
    from: env.SMTP_FROM,
    to,
    subject: 'Reset your Expensplit password',
    html: emailShell(
      'Reset your password',
      'You requested a password reset. Use the code below to continue.',
      otp,
      10,
      '#FF6B6B',
    ),
    attachments: [logoAttachment],
  });
}

export async function sendOtpEmail(to, otp) {
  await transporter.sendMail({
    from: env.SMTP_FROM,
    to,
    subject: 'Your Expensplit verification code',
    html: emailShell(
      'Verify your email',
      'Use the code below to verify your email and finish creating your Expensplit account.',
      otp,
      10,
    ),
    attachments: [logoAttachment],
  });
}
