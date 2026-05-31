import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../app/theme/app_colors.dart';
import '../../core/errors/error_messages.dart';
import '../services/receipt_repository.dart';
import 'receipt_viewer.dart';

/// Hard ceiling enforced on the client after compression. 2 MB.
const int kMaxReceiptBytes = 2 * 1024 * 1024;

/// Holds the receipt selection for one expense form and defers the actual S3
/// upload until the expense is saved — so picking an image and then cancelling
/// the form never leaves an orphan in storage.
///
/// Usage:
///   final ctrl = ReceiptController(initialUrl: expense?.receiptUrl);
///   ReceiptPicker(controller: ctrl);
///   // on save:
///   final url = await ctrl.resolveUrl(ref);   // uploads the pending pick
///   ... create/update with receiptUrl: url ...
///   // on save failure (after resolveUrl):
///   await ctrl.rollback(ref);                 // deletes the orphan
class ReceiptController extends ChangeNotifier {
  ReceiptController({String? initialUrl})
      : _initialUrl = (initialUrl == null || initialUrl.isEmpty) ? null : initialUrl;

  final String? _initialUrl;
  Uint8List? _pendingBytes;
  String? _pendingName;
  bool _removed = false;
  String? _lastUploadedUrl;

  Uint8List? get pendingBytes => _pendingBytes;
  String? get existingUrl => _removed ? null : _initialUrl;
  bool get hasReceipt => _pendingBytes != null || (!_removed && _initialUrl != null);

  /// Whether the selection differs from what's stored — i.e. an update should
  /// send `receiptUrl`.
  bool get isDirty => _pendingBytes != null || _removed;

  void setPicked(Uint8List bytes, String name) {
    _pendingBytes = bytes;
    _pendingName = name;
    _removed = false;
    notifyListeners();
  }

  void clear() {
    _pendingBytes = null;
    _pendingName = null;
    if (_initialUrl != null) _removed = true;
    notifyListeners();
  }

  /// Upload a freshly-picked image (if any) and return the URL to persist.
  /// Returns the existing URL unchanged, or '' if the receipt was removed.
  /// Call only when the user actually saves.
  Future<String> resolveUrl(WidgetRef ref) async {
    if (_pendingBytes != null) {
      final url = await ref.read(receiptRepositoryProvider).upload(
            bytes: _pendingBytes!,
            filename: _pendingName ?? 'receipt.jpg',
          );
      _lastUploadedUrl = url;
      return url;
    }
    if (_removed) return '';
    return _initialUrl ?? '';
  }

  /// Delete a just-uploaded image when the expense save fails afterwards.
  Future<void> rollback(WidgetRef ref) async {
    final url = _lastUploadedUrl;
    _lastUploadedUrl = null;
    if (url != null && url.isNotEmpty) {
      await ref.read(receiptRepositoryProvider).delete(url);
    }
  }
}

class ReceiptPicker extends StatefulWidget {
  const ReceiptPicker({
    super.key,
    required this.controller,
    this.accent = AppColors.primary,
  });

  final ReceiptController controller;
  final Color accent;

  @override
  State<ReceiptPicker> createState() => _ReceiptPickerState();
}

class _ReceiptPickerState extends State<ReceiptPicker> {
  bool _busy = false;

  Future<void> _chooseSource() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            if (!kIsWeb)
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded),
                title: const Text('Take a photo'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
          ],
        ),
      ),
    );
    if (source != null) await _pick(source);
  }

  Future<void> _pick(ImageSource source) async {
    setState(() => _busy = true);
    try {
      // image_picker compresses + downscales here, before we ever read bytes.
      final picked = await ImagePicker().pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1600,
        maxHeight: 1600,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      if (bytes.lengthInBytes > kMaxReceiptBytes) {
        if (mounted) {
          showErrorSnack(
            context,
            null,
            fallback:
                'That image is over 2 MB even after compression. Please pick a smaller one.',
          );
        }
        return;
      }
      widget.controller.setPicked(bytes, picked.name);
    } catch (e) {
      if (mounted) {
        showErrorSnack(context, e, fallback: 'Could not load that image');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _view() {
    final c = widget.controller;
    showReceiptViewer(context, url: c.existingUrl, bytes: c.pendingBytes);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final c = widget.controller;
        if (!c.hasReceipt) return _addButton(context);
        return _preview(context, c);
      },
    );
  }

  Widget _addButton(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: _busy ? null : _chooseSource,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: cs.onSurface.withOpacity(0.18),
            // Subtle dashed-feel via a lighter border + tinted fill.
          ),
          color: cs.onSurface.withOpacity(0.02),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: widget.accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: _busy
                  ? Padding(
                      padding: const EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: widget.accent),
                    )
                  : Icon(Icons.receipt_long_rounded, color: widget.accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Add receipt',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(
                    'Optional · image up to 2 MB',
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurface.withOpacity(0.55),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.add_rounded, color: cs.onSurface.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }

  Widget _preview(BuildContext context, ReceiptController c) {
    final cs = Theme.of(context).colorScheme;
    final Widget img = c.pendingBytes != null
        ? Image.memory(c.pendingBytes!, fit: BoxFit.cover)
        : CachedNetworkImage(
            imageUrl: c.existingUrl!,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              color: cs.onSurface.withOpacity(0.05),
              child: const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            errorWidget: (_, __, ___) => Container(
              color: cs.onSurface.withOpacity(0.05),
              child: Icon(Icons.broken_image_rounded,
                  color: cs.onSurface.withOpacity(0.4)),
            ),
          );

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          // Constrained, responsive preview — fills the width, capped height.
          GestureDetector(
            onTap: _view,
            child: SizedBox(
              height: 170,
              width: double.infinity,
              child: img,
            ),
          ),
          // Gradient + label so the controls stay legible over any image.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withOpacity(0.55), Colors.transparent],
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long_rounded,
                      color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  const Text('Receipt attached',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                  const Spacer(),
                  const Icon(Icons.zoom_in_rounded,
                      color: Colors.white70, size: 18),
                  const SizedBox(width: 2),
                  const Text('Tap to view',
                      style: TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
            ),
          ),
          // Remove + replace actions, top-right.
          Positioned(
            top: 8,
            right: 8,
            child: Row(
              children: [
                _circleBtn(
                  icon: Icons.swap_horiz_rounded,
                  tooltip: 'Replace',
                  onTap: _busy ? null : _chooseSource,
                ),
                const SizedBox(width: 6),
                _circleBtn(
                  icon: Icons.close_rounded,
                  tooltip: 'Remove',
                  onTap: _busy ? null : widget.controller.clear,
                ),
              ],
            ),
          ),
          if (_busy)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x66000000),
                child: Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _circleBtn({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.black.withOpacity(0.45),
      shape: const CircleBorder(),
      child: IconButton(
        tooltip: tooltip,
        visualDensity: VisualDensity.compact,
        iconSize: 18,
        constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: Colors.white),
        onPressed: onTap,
      ),
    );
  }
}
