import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../app/theme/app_colors.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _scanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final code = capture.barcodes.firstOrNull?.rawValue;
    if (code == null || code.isEmpty) return;
    _scanned = true;
    _controller.stop();
    Navigator.of(context).pop(code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Scan invite QR code'),
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _controller,
              builder: (_, state, _child) => Icon(
                state.torchState == TorchState.on
                    ? Icons.flashlight_on_rounded
                    : Icons.flashlight_off_rounded,
                color: Colors.white,
              ),
            ),
            onPressed: _controller.toggleTorch,
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),
          // Scanning overlay
          CustomPaint(
            painter: _ScanOverlayPainter(),
            child: const SizedBox.expand(),
          ),
          // Label at bottom
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.only(bottom: 60),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Point your camera at the group invite QR code',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double cutSize = size.width * 0.65;
    final double left = (size.width - cutSize) / 2;
    final double top = (size.height - cutSize) / 2;
    final Rect cutRect = Rect.fromLTWH(left, top, cutSize, cutSize);
    final RRect cutRRect = RRect.fromRectAndRadius(cutRect, const Radius.circular(16));

    // Dim everything outside the cutout
    final Paint dimPaint = Paint()..color = Colors.black.withOpacity(0.6);
    final Path dimPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(cutRRect)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(dimPath, dimPaint);

    // Corner brackets
    const double cornerLen = 24;
    const double strokeW = 4;
    final Paint bracketPaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = strokeW
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Top-left
    canvas.drawLine(Offset(left, top + cornerLen), Offset(left, top), bracketPaint);
    canvas.drawLine(Offset(left, top), Offset(left + cornerLen, top), bracketPaint);
    // Top-right
    canvas.drawLine(Offset(left + cutSize - cornerLen, top), Offset(left + cutSize, top), bracketPaint);
    canvas.drawLine(Offset(left + cutSize, top), Offset(left + cutSize, top + cornerLen), bracketPaint);
    // Bottom-left
    canvas.drawLine(Offset(left, top + cutSize - cornerLen), Offset(left, top + cutSize), bracketPaint);
    canvas.drawLine(Offset(left, top + cutSize), Offset(left + cornerLen, top + cutSize), bracketPaint);
    // Bottom-right
    canvas.drawLine(Offset(left + cutSize - cornerLen, top + cutSize), Offset(left + cutSize, top + cutSize), bracketPaint);
    canvas.drawLine(Offset(left + cutSize, top + cutSize), Offset(left + cutSize, top + cutSize - cornerLen), bracketPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
