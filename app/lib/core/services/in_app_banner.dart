import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Shows a brief in-app banner at the top of the screen — used when a socket
/// event arrives while the app is in the foreground so the user sees a
/// transient confirmation without a system-level push notification.
///
/// Usage:
///   InAppBanner.instance.attach(navigatorKey);  // once, in app.dart
///   InAppBanner.instance.show(
///     title: 'New expense',
///     message: 'Alice added "Dinner" to Roomies',
///     onTap: () => router.go('/groups/123'),
///   );
class InAppBanner {
  InAppBanner._();
  static final InAppBanner instance = InAppBanner._();

  GlobalKey<NavigatorState>? _navKey;
  OverlayEntry? _current;
  Timer? _autoDismiss;

  void attach(GlobalKey<NavigatorState> key) {
    _navKey = key;
  }

  /// Show a banner. If one is already on screen it is replaced so we never
  /// pile up — the latest event wins.
  void show({
    required String title,
    required String message,
    IconData icon = Icons.notifications_active_rounded,
    Color? accent,
    VoidCallback? onTap,
    Duration duration = const Duration(seconds: 4),
  }) {
    final overlay = _navKey?.currentState?.overlay;
    if (overlay == null) return;

    _autoDismiss?.cancel();
    _current?.remove();

    final entry = OverlayEntry(
      builder: (ctx) => _BannerHost(
        title: title,
        message: message,
        icon: icon,
        accent: accent ?? AppColors.primary,
        onTap: onTap == null
            ? null
            : () {
                _dismiss();
                onTap();
              },
        onClose: _dismiss,
      ),
    );
    _current = entry;
    overlay.insert(entry);

    _autoDismiss = Timer(duration, _dismiss);
  }

  void _dismiss() {
    _autoDismiss?.cancel();
    _autoDismiss = null;
    _current?.remove();
    _current = null;
  }
}

class _BannerHost extends StatefulWidget {
  const _BannerHost({
    required this.title,
    required this.message,
    required this.icon,
    required this.accent,
    required this.onClose,
    this.onTap,
  });

  final String title;
  final String message;
  final IconData icon;
  final Color accent;
  final VoidCallback onClose;
  final VoidCallback? onTap;

  @override
  State<_BannerHost> createState() => _BannerHostState();
}

class _BannerHostState extends State<_BannerHost>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  )..forward();
  late final Animation<Offset> _slide = Tween(
    begin: const Offset(0, -1.1),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
  late final Animation<double> _fade =
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _animateOutAndClose() async {
    await _ctrl.reverse();
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: SlideTransition(
          position: _slide,
          child: FadeTransition(
            opacity: _fade,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onTap,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.dark
                          ? const Color(0xFF1C1C28)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: widget.accent.withOpacity(0.25),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.14),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: widget.accent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Icon(widget.icon,
                              size: 20, color: widget.accent),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.message,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  height: 1.3,
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: _animateOutAndClose,
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: theme.colorScheme.onSurface
                                  .withOpacity(0.55),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
