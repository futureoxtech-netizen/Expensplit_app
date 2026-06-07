import mongoose from 'mongoose';

// Per-platform version policy used to drive soft (recommended) and force
// (mandatory) update prompts in the mobile app.
const platformPolicySchema = new mongoose.Schema(
  {
    // The newest version available in the store. Clients below this are
    // offered a *soft* (dismissible) update prompt. Defaults to the current
    // shipping version so a fresh DB never prompts until an admin bumps it.
    latestVersion: { type: String, default: '0.1.0' },
    // The oldest version the API still supports. Clients below this are
    // shown a *forced* (blocking) update prompt.
    minSupportedVersion: { type: String, default: '0.0.0' },
    storeUrl: { type: String, default: '' },
  },
  { _id: false },
);

// Singleton document: there is only ever one AppConfig row (key === 'app').
const appConfigSchema = new mongoose.Schema(
  {
    key: { type: String, default: 'app', unique: true },
    android: { type: platformPolicySchema, default: () => ({}) },
    ios: { type: platformPolicySchema, default: () => ({}) },
    // Optional copy shown in the update dialog. Falls back to a sensible
    // default in the client when empty.
    updateMessage: { type: String, default: '' },
    forceUpdateMessage: { type: String, default: '' },
    // System maintenance switch. When enabled, the app shows a full-screen
    // blocking notice and the user can't use it until it's turned off.
    maintenance: {
      enabled: { type: Boolean, default: false },
      message: { type: String, default: '' },
    },
  },
  { timestamps: true },
);

export const AppConfig = mongoose.model('AppConfig', appConfigSchema);
