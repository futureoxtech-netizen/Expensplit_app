import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Open a full-screen, zoomable viewer for a receipt image. Pass [url] for a
/// stored receipt or [bytes] for a not-yet-uploaded local pick.
Future<void> showReceiptViewer(
  BuildContext context, {
  String? url,
  Uint8List? bytes,
}) {
  return Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black,
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (_, __, ___) => _ReceiptViewer(url: url, bytes: bytes),
      transitionsBuilder: (_, anim, __, child) =>
          FadeTransition(opacity: anim, child: child),
    ),
  );
}

class _ReceiptViewer extends StatelessWidget {
  const _ReceiptViewer({this.url, this.bytes});
  final String? url;
  final Uint8List? bytes;

  @override
  Widget build(BuildContext context) {
    final Widget image;
    if (bytes != null) {
      image = Image.memory(bytes!, fit: BoxFit.contain);
    } else if (url != null && url!.isNotEmpty) {
      image = CachedNetworkImage(
        imageUrl: url!,
        fit: BoxFit.contain,
        placeholder: (_, __) => const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
        errorWidget: (_, __, ___) => const _ViewerError(),
      );
    } else {
      image = const _ViewerError();
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Pinch-to-zoom / pan. Tapping the dimmed area dismisses.
          Positioned.fill(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 5,
                child: Center(child: image),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Material(
                  color: Colors.black.withOpacity(0.4),
                  shape: const CircleBorder(),
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewerError extends StatelessWidget {
  const _ViewerError();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.broken_image_rounded, color: Colors.white54, size: 48),
          SizedBox(height: 8),
          Text("Couldn't load receipt",
              style: TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }
}
