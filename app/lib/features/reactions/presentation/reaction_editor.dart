import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/errors/error_messages.dart';
import '../../../shared/widgets/app_sheet.dart';
import '../../../shared/widgets/avatar.dart';
import '../../auth/providers/auth_provider.dart';
import '../data/reaction_model.dart';
import '../providers/reaction_providers.dart';
import 'reaction_picker.dart';

/// Attaches WhatsApp-style reactions to any expense or settlement.
///
/// Two layouts, driven by [child]:
///   • [child] non-null (feed rows): wraps the card so a long-press opens the
///     emoji picker, and floats the reaction chips so they *overlap* the
///     bottom-right edge of the card — exactly like a WhatsApp reaction badge.
///     With no reactions the card renders untouched; discovery is via
///     long-press.
///   • [child] null (detail screen): renders an inline chip strip with an
///     always-visible "add reaction" button, since there's no row to
///     long-press.
///
/// Toggling is optimistic: the chips update instantly, the API call follows,
/// and the realtime `reaction:changed` broadcast reconciles every client
/// (including this one) by replacing [reactions] — which clears the local
/// override. Failures revert and surface a snackbar.
class ReactionEditor extends ConsumerStatefulWidget {
  const ReactionEditor({
    super.key,
    required this.targetType,
    required this.targetId,
    required this.groupId,
    required this.reactions,
    this.child,
    this.onTap,
    this.borderRadius = 20,
  });

  final String targetType;
  final String targetId;
  final String groupId;
  final List<ReactionSummary> reactions;
  final Widget? child;
  final VoidCallback? onTap;
  final double borderRadius;

  @override
  ConsumerState<ReactionEditor> createState() => _ReactionEditorState();
}

class _ReactionEditorState extends ConsumerState<ReactionEditor> {
  final _anchorKey = GlobalKey();

  /// Pending optimistic state; `null` means "show the server's [reactions]".
  List<ReactionSummary>? _override;

  @override
  void didUpdateWidget(covariant ReactionEditor old) {
    super.didUpdateWidget(old);
    // Fresh data from the provider (a new list instance) supersedes any
    // optimistic guess we were showing.
    if (!identical(old.reactions, widget.reactions)) _override = null;
  }

  List<ReactionSummary> get _current => _override ?? widget.reactions;

  ReactionUser? get _me {
    final u = ref.read(authProvider).user;
    if (u == null) return null;
    return ReactionUser(id: u.id, name: u.name, avatarUrl: u.avatarUrl);
  }

  String? _myEmoji() {
    final id = _me?.id;
    if (id == null) return null;
    for (final r in _current) {
      if (r.mineFor(id)) return r.emoji;
    }
    return null;
  }

  Future<void> _toggle(String emoji) async {
    final me = _me;
    if (me == null) return;
    final optimistic = applyReactionToggle(_current, emoji, me);
    setState(() => _override = optimistic);
    try {
      await ref.read(reactionRepositoryProvider).toggle(
            targetType: widget.targetType,
            targetId: widget.targetId,
            emoji: emoji,
          );
      // Success: the realtime broadcast will deliver authoritative data and
      // clear the override. Leave the optimistic state in place until then.
    } catch (e) {
      if (!mounted) return;
      setState(() => _override = null); // revert to server truth
      showErrorSnack(context, e, fallback: 'Could not update reaction');
    }
  }

  Rect _anchorRect() {
    final box = _anchorKey.currentContext?.findRenderObject();
    if (box is RenderBox && box.attached) {
      return box.localToGlobal(Offset.zero) & box.size;
    }
    final size = MediaQuery.of(context).size;
    return Rect.fromLTWH(0, size.height / 2, size.width, 0);
  }

  Future<void> _openPicker() async {
    if (_me == null) return;
    final picked = await showReactionPicker(
      context,
      targetRect: _anchorRect(),
      selectedEmoji: _myEmoji(),
    );
    if (picked != null) await _toggle(picked);
  }

  void _showViewers() {
    final reactions = _current;
    if (reactions.isEmpty) {
      // Nothing to show yet — offer to add one instead.
      _openPicker();
      return;
    }
    showAppFixedSheet<void>(
      context: context,
      builder: (_) => _ReactionViewersSheet(
        reactions: reactions,
        myId: _me?.id,
        onRemoveMine: (emoji) {
          Navigator.of(context).pop();
          _toggle(emoji); // toggling the emoji you reacted with removes it
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Detail layout: inline strip + add button.
    if (widget.child == null) {
      return KeyedSubtree(key: _anchorKey, child: _buildInlineStrip());
    }

    final me = _me;
    final reactions = _current;

    final card = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        onLongPress: _openPicker,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: widget.child,
      ),
    );

    // No reactions yet — render the bare card, no reserved space.
    if (reactions.isEmpty) {
      return KeyedSubtree(key: _anchorKey, child: card);
    }

    // Overlap layout: reserve a sliver of space below the card and float the
    // chip cluster over its bottom-right corner.
    return KeyedSubtree(
      key: _anchorKey,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: card,
          ),
          Positioned(
            right: 10,
            bottom: 0,
            child: _OverlapCluster(
              reactions: reactions,
              myId: me?.id,
              onShowViewers: _showViewers,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineStrip() {
    final me = _me;
    final reactions = _current;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final r in reactions)
          _ReactionChip(
            emoji: r.emoji,
            count: r.count,
            mine: r.mineFor(me?.id),
            // WhatsApp-style: a single tap opens the "who reacted" list.
            onTap: _showViewers,
            onLongPress: _showViewers,
          ),
        if (me != null)
          _AddReactionButton(onTap: _openPicker, faded: reactions.isEmpty),
      ],
    );
  }
}

/// The floating cluster of reaction chips that overlaps the bottom-right edge
/// of a card. Each chip is individually tappable (toggle) and the whole
/// cluster long-presses to reveal who reacted.
class _OverlapCluster extends StatelessWidget {
  const _OverlapCluster({
    required this.reactions,
    required this.myId,
    required this.onShowViewers,
  });

  final List<ReactionSummary> reactions;
  final String? myId;
  final VoidCallback onShowViewers;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final r in reactions)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: _ReactionChip(
              emoji: r.emoji,
              count: r.count,
              mine: r.mineFor(myId),
              elevated: true,
              // Single tap → who reacted (WhatsApp-style).
              onTap: onShowViewers,
              onLongPress: onShowViewers,
            ),
          ),
      ],
    );
  }
}

class _ReactionChip extends StatelessWidget {
  const _ReactionChip({
    required this.emoji,
    required this.count,
    required this.mine,
    required this.onTap,
    required this.onLongPress,
    this.elevated = false,
  });

  final String emoji;
  final int count;
  final bool mine;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// When true the chip is rendered opaque with a shadow + ring so it reads as
  /// floating above the card it overlaps.
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Opaque backgrounds for the elevated (overlapping) variant so the card
    // border beneath never shows through; translucent for the inline variant.
    final Color bg;
    if (elevated) {
      bg = mine ? Color.lerp(cs.surface, AppColors.primary, 0.16)! : cs.surface;
    } else {
      bg = mine
          ? AppColors.primary.withOpacity(0.14)
          : cs.onSurface.withOpacity(0.05);
    }
    final border = mine
        ? AppColors.primary.withOpacity(0.55)
        : cs.onSurface.withOpacity(elevated ? 0.10 : 0.08);
    final countColor = mine ? AppColors.primary : cs.onSurface.withOpacity(0.7);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border),
            boxShadow: elevated
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.10),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 14)),
              if (count > 1) ...[
                const SizedBox(width: 4),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: countColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AddReactionButton extends StatelessWidget {
  const _AddReactionButton({required this.onTap, required this.faded});

  final VoidCallback onTap;
  final bool faded;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: cs.onSurface.withOpacity(0.04),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cs.onSurface.withOpacity(0.08)),
          ),
          child: Icon(
            Icons.add_reaction_outlined,
            size: 16,
            color: cs.onSurface.withOpacity(faded ? 0.4 : 0.6),
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet listing who reacted, grouped by emoji — opened by a single tap
/// on a reaction chip (WhatsApp-style). Tapping your own row removes it.
class _ReactionViewersSheet extends StatelessWidget {
  const _ReactionViewersSheet({
    required this.reactions,
    required this.myId,
    this.onRemoveMine,
  });

  final List<ReactionSummary> reactions;
  final String? myId;
  final void Function(String emoji)? onRemoveMine;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final total = reactions.fold<int>(0, (a, r) => a + r.count);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: AppSheetHandle()),
            Text(
              'Reactions · $total',
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            for (final r in reactions)
              for (final u in r.users)
                Builder(builder: (context) {
                  final isMine = u.id == myId;
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: isMine && onRemoveMine != null
                        ? () => onRemoveMine!(r.emoji)
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Avatar(name: u.name, imageUrl: u.avatarUrl, size: 36),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  u.name.isEmpty
                                      ? 'Someone'
                                      : (isMine ? '${u.name} (you)' : u.name),
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                if (isMine && onRemoveMine != null)
                                  Text(
                                    'Tap to remove',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: cs.onSurface.withOpacity(0.5),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Text(r.emoji, style: const TextStyle(fontSize: 20)),
                        ],
                      ),
                    ),
                  );
                }),
          ],
        ),
      ),
    );
  }
}
