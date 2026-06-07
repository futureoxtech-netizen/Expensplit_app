import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/app_colors.dart';
import '../data/app_update_model.dart';

/// Shows the soft/forced update prompt. For a forced update the dialog cannot
/// be dismissed (no barrier tap, no back button, no "Later"); the user must
/// update to continue. Returns when the user dismisses a soft prompt.
Future<void> showAppUpdateDialog(BuildContext context, AppUpdateInfo info) {
  return showDialog<void>(
    context: context,
    barrierDismissible: !info.forceUpdate,
    builder: (ctx) => _UpdateDialog(info: info),
  );
}

class _UpdateDialog extends StatelessWidget {
  const _UpdateDialog({required this.info});
  final AppUpdateInfo info;

  Future<void> _openStore(BuildContext context) async {
    final url = info.storeUrl.trim();
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final force = info.forceUpdate;

    final message = info.message.trim().isNotEmpty
        ? info.message.trim()
        : (force
            ? 'This version is no longer supported. Please update to the '
                'latest version to keep using Expensplit.'
            : 'A new version of Expensplit is available with the latest '
                'improvements and fixes.');

    return PopScope(
      // Block the system back button when an update is mandatory.
      canPop: !force,
      child: AlertDialog(
        scrollable: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.system_update_rounded,
                  color: Colors.white, size: 36),
            ),
            const SizedBox(height: 18),
            Text(
              force ? 'Update required' : 'Update available',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: cs.onSurface.withOpacity(0.7),
              ),
            ),
            if (info.latestVersion.isNotEmpty) ...[
              const SizedBox(height: 14),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'v${info.currentVersion}  →  v${info.latestVersion}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        actions: [
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _openStore(context),
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('Update now',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              if (!force)
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Maybe later',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
