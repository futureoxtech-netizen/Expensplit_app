/**
 * Seed / reset the AppConfig singleton document.
 *
 * Controls:
 *  - Soft-update prompt  → bump android/ios latestVersion above the user's
 *                          installed version.
 *  - Force-update block  → bump android/ios minSupportedVersion above the
 *                          user's installed version.
 *  - Maintenance screen  → set maintenance.enabled = true.
 *
 * Run: npm run seed:config
 */

import 'dotenv/config';
import mongoose from 'mongoose';
import { env } from '../config/env.js';
import { AppConfig } from '../modules/appConfig/appConfig.model.js';

const CONFIG = {
  key: 'app',

  // ── Android ──────────────────────────────────────────────────────────────
  android: {
    // Newest version in the Play Store.
    // Clients below this version see a soft (dismissible) update prompt.
    latestVersion: '0.1.0',
    // Oldest version the API still supports.
    // Clients below this version see a forced (blocking) update screen.
    minSupportedVersion: '0.0.0',
    storeUrl: 'https://play.google.com/store/apps/details?id=com.yourapp',
  },

  // ── iOS ──────────────────────────────────────────────────────────────────
  ios: {
    latestVersion: '0.1.0',
    minSupportedVersion: '0.0.0',
    storeUrl: 'https://apps.apple.com/app/id000000000',
  },

  // ── Update dialog copy ───────────────────────────────────────────────────
  // Shown in the soft-update dialog (user can dismiss).
  updateMessage: 'A new version is available with improvements and bug fixes. Update for the best experience.',

  // Shown in the forced-update screen (user cannot dismiss).
  forceUpdateMessage: 'This version is no longer supported. Please update the app to continue using it.',

  // ── Maintenance mode ─────────────────────────────────────────────────────
  // Set enabled: true to show a full-screen blocking notice in the app.
  maintenance: {
    enabled: false,
    message: 'We are currently performing scheduled maintenance. We will be back shortly — thank you for your patience.',
  },
};

async function main() {
  await mongoose.connect(env.MONGO_URI);
  console.log('Connected to Mongo');

  const doc = await AppConfig.findOneAndUpdate(
    { key: 'app' },
    CONFIG,
    { upsert: true, new: true, setDefaultsOnInsert: true },
  );

  console.log('\nAppConfig seeded successfully:');
  console.log('  Android   latest=%s  minSupported=%s', doc.android.latestVersion, doc.android.minSupportedVersion);
  console.log('  iOS       latest=%s  minSupported=%s', doc.ios.latestVersion, doc.ios.minSupportedVersion);
  console.log('  Maintenance: %s', doc.maintenance.enabled ? 'ENABLED ⚠️' : 'disabled');

  await mongoose.disconnect();
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
