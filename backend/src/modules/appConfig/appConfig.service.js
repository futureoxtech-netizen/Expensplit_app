import { AppConfig } from './appConfig.model.js';
import { isVersionLessThan } from '../../utils/semver.js';

export const appConfigService = {
  // Fetch the singleton config, creating it with defaults on first call so the
  // endpoint never 404s on a fresh database.
  async get() {
    let config = await AppConfig.findOne({ key: 'app' });
    if (!config) {
      config = await AppConfig.create({ key: 'app' });
    }
    return config;
  },

  // Compare a client's version against the policy for its platform and report
  // whether an update is available (soft) and/or required (force).
  async checkVersion({ platform, version }) {
    const config = await this.get();
    const plat = platform === 'ios' ? 'ios' : 'android';
    const policy = config[plat] ?? {};

    const latestVersion = policy.latestVersion || '0.0.0';
    const minSupportedVersion = policy.minSupportedVersion || '0.0.0';
    const current = version || '0.0.0';

    const forceUpdate = isVersionLessThan(current, minSupportedVersion);
    // A soft update is offered when below latest but still supported.
    const updateAvailable = isVersionLessThan(current, latestVersion);

    return {
      platform: plat,
      currentVersion: current,
      latestVersion,
      minSupportedVersion,
      updateAvailable,
      forceUpdate,
      storeUrl: policy.storeUrl || '',
      message: forceUpdate
        ? config.forceUpdateMessage || ''
        : config.updateMessage || '',
      // System maintenance — blocks the app entirely while enabled.
      maintenance: !!config.maintenance?.enabled,
      maintenanceMessage: config.maintenance?.message || '',
    };
  },

  // Admin/maintenance helper to update the policy.
  async update(data) {
    const config = await this.get();
    if (data.android) Object.assign(config.android, data.android);
    if (data.ios) Object.assign(config.ios, data.ios);
    if (data.updateMessage !== undefined) config.updateMessage = data.updateMessage;
    if (data.forceUpdateMessage !== undefined) {
      config.forceUpdateMessage = data.forceUpdateMessage;
    }
    await config.save();
    return config;
  },
};
