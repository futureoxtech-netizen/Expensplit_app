import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../data/reaction_model.dart';

/// Show the WhatsApp-style floating emoji picker anchored near [targetRect]
/// (the global bounds of the long-pressed row). Returns the chosen emoji, or
/// `null` if the user dismissed by tapping outside.
///
/// [selectedEmoji] highlights the emoji the caller already reacted with so
/// re-tapping it (to toggle off) reads as the obvious "remove" affordance.
Future<String?> showReactionPicker(
  BuildContext context, {
  required Rect targetRect,
  String? selectedEmoji,
}) {
  return showGeneralDialog<String>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Reactions',
    barrierColor: Colors.black.withOpacity(0.08),
    transitionDuration: const Duration(milliseconds: 160),
    pageBuilder: (_, __, ___) => const SizedBox.shrink(),
    transitionBuilder: (ctx, anim, _, __) => _ReactionPickerOverlay(
      animation: anim,
      targetRect: targetRect,
      selectedEmoji: selectedEmoji,
    ),
  );
}

class _ReactionPickerOverlay extends StatelessWidget {
  const _ReactionPickerOverlay({
    required this.animation,
    required this.targetRect,
    required this.selectedEmoji,
  });

  final Animation<double> animation;
  final Rect targetRect;
  final String? selectedEmoji;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final size = media.size;
    const pillHeight = 60.0;
    final safeTop = media.padding.top + 8;

    // Prefer floating above the row; flip below if there isn't room.
    final aboveTop = targetRect.top - 12 - pillHeight;
    final placeAbove = aboveTop >= safeTop;
    final top = placeAbove ? aboveTop : targetRect.bottom + 12;

    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutBack);

    return Stack(
      children: [
        Positioned(
          top: top,
          left: 12,
          right: 12,
          child: Align(
            alignment: Alignment.center,
            child: FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: curved,
                alignment:
                    placeAbove ? Alignment.bottomCenter : Alignment.topCenter,
                child: _PickerPill(
                  maxWidth: size.width - 24,
                  selectedEmoji: selectedEmoji,
                  onPick: (e) => Navigator.of(context).pop(e),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PickerPill extends StatelessWidget {
  const _PickerPill({
    required this.maxWidth,
    required this.selectedEmoji,
    required this.onPick,
  });

  final double maxWidth;
  final String? selectedEmoji;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: cs.onSurface.withOpacity(0.06)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.16),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final emoji in kReactionEmojis)
                  _PickerEmoji(
                    emoji: emoji,
                    selected: emoji == selectedEmoji,
                    onTap: () => onPick(emoji),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PickerEmoji extends StatefulWidget {
  const _PickerEmoji({
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_PickerEmoji> createState() => _PickerEmojiState();
}

class _PickerEmojiState extends State<_PickerEmoji> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 1.28 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: Container(
          width: 44,
          height: 48,
          alignment: Alignment.center,
          decoration: widget.selected
              ? BoxDecoration(
                  color: AppColors.primary.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(16),
                )
              : null,
          child: Text(widget.emoji, style: const TextStyle(fontSize: 28)),
        ),
      ),
    );
  }
}
