import 'package:flutter/foundation.dart';

/// The fixed reaction palette. Must stay in sync with the backend
/// `ALLOWED_REACTIONS` list — the server rejects anything outside it.
const List<String> kReactionEmojis = ['👍', '❤️', '😂', '😮', '😢', '🙏', '🎉', '💰'];

/// One person who reacted, as carried inside a [ReactionSummary].
@immutable
class ReactionUser {
  const ReactionUser({required this.id, required this.name, this.avatarUrl});

  factory ReactionUser.fromJson(Map<String, dynamic> j) => ReactionUser(
        id: (j['id'] ?? j['_id'] ?? '').toString(),
        name: (j['name'] ?? '') as String,
        avatarUrl: j['avatarUrl'] as String?,
      );

  final String id;
  final String name;
  final String? avatarUrl;
}

/// Aggregated reactions for a single emoji on one target. The server sends no
/// per-viewer `mine` flag (the same summary is broadcast to the whole group),
/// so each client derives "did I react?" locally via [mineFor].
@immutable
class ReactionSummary {
  const ReactionSummary({required this.emoji, required this.users});

  factory ReactionSummary.fromJson(Map<String, dynamic> j) => ReactionSummary(
        emoji: (j['emoji'] ?? '').toString(),
        users: ((j['users'] ?? const []) as List)
            .whereType<Map<String, dynamic>>()
            .map(ReactionUser.fromJson)
            .toList(),
      );

  final String emoji;
  final List<ReactionUser> users;

  int get count => users.length;

  bool mineFor(String? myId) =>
      myId != null && users.any((u) => u.id == myId);
}

/// Parse a raw `reactions` JSON array into summaries, dropping any empty
/// buckets. Shared by the expense/settlement models and the realtime bridge.
List<ReactionSummary> parseReactions(dynamic raw) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map<String, dynamic>>()
      .map(ReactionSummary.fromJson)
      .where((r) => r.emoji.isNotEmpty && r.users.isNotEmpty)
      .toList();
}

/// Pure, optimistic application of a WhatsApp-style toggle, used to update the
/// UI instantly before the server round-trip confirms. Rules:
///   • tapping the emoji you already reacted with removes your reaction
///   • tapping a different emoji moves your reaction to it
///   • otherwise it adds your reaction
/// Empty buckets are dropped and the result is re-sorted most-reacted first.
List<ReactionSummary> applyReactionToggle(
  List<ReactionSummary> current,
  String emoji,
  ReactionUser me,
) {
  // Work on mutable copies of each bucket's user list.
  final buckets = <String, List<ReactionUser>>{
    for (final r in current) r.emoji: [...r.users],
  };

  // Find the emoji I currently own (if any) and remove me from it.
  String? myEmoji;
  for (final entry in buckets.entries) {
    if (entry.value.any((u) => u.id == me.id)) {
      myEmoji = entry.key;
      break;
    }
  }
  if (myEmoji != null) {
    buckets[myEmoji]!.removeWhere((u) => u.id == me.id);
  }

  // Add me to the tapped emoji unless I was just toggling it off.
  if (myEmoji != emoji) {
    final list = buckets.putIfAbsent(emoji, () => <ReactionUser>[]);
    if (!list.any((u) => u.id == me.id)) list.add(me);
  }

  final result = <ReactionSummary>[
    for (final entry in buckets.entries)
      if (entry.value.isNotEmpty)
        ReactionSummary(emoji: entry.key, users: entry.value),
  ]..sort((a, b) {
      final byCount = b.count.compareTo(a.count);
      if (byCount != 0) return byCount;
      return kReactionEmojis
          .indexOf(a.emoji)
          .compareTo(kReactionEmojis.indexOf(b.emoji));
    });
  return result;
}
