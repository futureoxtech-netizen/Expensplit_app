import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/errors/error_messages.dart';
import '../data/payment_method_model.dart';

/// A card showing one payment method with a one-tap "copy" action. Optional
/// [onEdit]/[onDelete] render a trailing overflow menu (used where the viewer
/// owns the method). [trailing] overrides the menu entirely when provided.
class PaymentMethodTile extends StatelessWidget {
  const PaymentMethodTile({
    super.key,
    required this.method,
    this.onEdit,
    this.onDelete,
    this.showOwner = false,
  });

  final PaymentMethodModel method;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  /// When true, shows the member's name (used in group-shared lists).
  final bool showOwner;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: method.accountNumber));
    if (context.mounted) showSuccessSnack(context, 'Account number copied');
  }

  @override
  Widget build(BuildContext context) {
    final meta = method.typeMeta;
    final cs = Theme.of(context).colorScheme;
    final hasMenu = onEdit != null || onDelete != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: meta.color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(meta.icon, color: meta.color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        method.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (showOwner && (method.userName?.isNotEmpty ?? false))
                      Text(
                        method.userName!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface.withOpacity(0.55),
                        ),
                      ),
                  ],
                ),
                if (method.bankName.trim().isNotEmpty)
                  Text(method.bankName.trim(),
                      style: TextStyle(
                          fontSize: 12.5, color: cs.onSurface.withOpacity(0.6))),
                const SizedBox(height: 4),
                SelectableText(
                  method.accountNumber,
                  style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3),
                ),
                if (method.accountName.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text('Holder: ${method.accountName.trim()}',
                        style: TextStyle(
                            fontSize: 12.5, color: cs.onSurface.withOpacity(0.6))),
                  ),
                if (method.note.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(method.note.trim(),
                        style: TextStyle(
                            fontSize: 12.5,
                            fontStyle: FontStyle.italic,
                            color: cs.onSurface.withOpacity(0.6))),
                  ),
              ],
            ),
          ),
          // Actions sit side-by-side at the top-right. Stacking them in a
          // Column previously left the overflow menu floating below the copy
          // button with a large gap (two 48px tap targets stacked).
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: 'Copy',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                icon: const Icon(Icons.copy_rounded, size: 19),
                onPressed: () => _copy(context),
              ),
              if (hasMenu)
                PopupMenuButton<String>(
                  tooltip: 'More',
                  padding: EdgeInsets.zero,
                  iconSize: 19,
                  icon: const Icon(Icons.more_vert_rounded, size: 19),
                  onSelected: (v) {
                    if (v == 'edit') onEdit?.call();
                    if (v == 'delete') onDelete?.call();
                  },
                  itemBuilder: (_) => [
                    if (onEdit != null)
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    if (onDelete != null)
                      const PopupMenuItem(value: 'delete', child: Text('Remove')),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
