import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Width threshold above which we render modals as centered dialogs
/// (desktop / web / tablet) instead of bottom sheets. Anything narrower
/// keeps the mobile-native bottom-sheet pattern.
const double _dialogBreakpoint = 600;

bool _isWide(BuildContext context) {
  if (kIsWeb) return MediaQuery.of(context).size.width >= _dialogBreakpoint;
  return MediaQuery.of(context).size.width >= _dialogBreakpoint;
}

/// A drag handle displayed at the top of every bottom sheet.
class AppSheetHandle extends StatelessWidget {
  const AppSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).dividerColor,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

/// Show a responsive modal:
///   • Narrow screens (mobile): a bottom sheet — DraggableScrollableSheet
///     up to 90 % of the height.
///   • Wide screens (web / tablet / desktop): a centered Dialog with a
///     fixed max width so content stays readable.
///
/// The [builder] receives the modal context and is reused unchanged for
/// both presentations, so callers don't need to branch.
Future<T?> showAppSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext ctx) builder,
  double maxHeightFraction = 0.90,
  double maxDialogWidth = 480,
  bool isDismissible = true,
  bool enableDrag = true,
}) {
  if (_isWide(context)) {
    return showDialog<T>(
      context: context,
      barrierDismissible: isDismissible,
      builder: (ctx) => Dialog(
        clipBehavior: Clip.antiAlias,
        backgroundColor: Theme.of(ctx).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: maxDialogWidth,
            maxHeight: MediaQuery.of(ctx).size.height * maxHeightFraction,
          ),
          child: builder(ctx),
        ),
      ),
    );
  }

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    useSafeArea: true,
    clipBehavior: Clip.antiAlias,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) {
      return DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: maxHeightFraction,
        expand: false,
        builder: (_, scrollCtrl) => builder(ctx),
      );
    },
  );
}

/// Responsive non-draggable modal. Good for small menus / confirms.
///   • Narrow: fixed-height bottom sheet that keeps the keyboard inset.
///   • Wide: centered Dialog.
Future<T?> showAppFixedSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext ctx) builder,
  double maxDialogWidth = 480,
  bool isDismissible = true,
}) {
  if (_isWide(context)) {
    return showDialog<T>(
      context: context,
      barrierDismissible: isDismissible,
      builder: (ctx) => Dialog(
        clipBehavior: Clip.antiAlias,
        backgroundColor: Theme.of(ctx).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxDialogWidth),
          child: builder(ctx),
        ),
      ),
    );
  }

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: isDismissible,
    useSafeArea: true,
    clipBehavior: Clip.antiAlias,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(ctx).viewInsets.bottom,
      ),
      child: builder(ctx),
    ),
  );
}
