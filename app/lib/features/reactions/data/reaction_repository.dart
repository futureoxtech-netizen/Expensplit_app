import '../../../core/network/dio_client.dart';
import 'reaction_model.dart';

class ReactionRepository {
  ReactionRepository(this._client);
  final DioClient _client;

  /// Add / switch / toggle-off the caller's reaction. The server applies
  /// WhatsApp semantics from the single [emoji] and returns the fresh summary.
  Future<List<ReactionSummary>> toggle({
    required String targetType,
    required String targetId,
    required String emoji,
  }) async {
    final res = await _client.post('/reactions', body: {
      'targetType': targetType,
      'targetId': targetId,
      'emoji': emoji,
    });
    return _reactionsFrom(res);
  }

  /// Explicitly clear the caller's reaction on a target.
  Future<List<ReactionSummary>> clear({
    required String targetType,
    required String targetId,
  }) async {
    final res = await _client.delete('/reactions/$targetType/$targetId');
    return _reactionsFrom(res);
  }

  List<ReactionSummary> _reactionsFrom(Map<String, dynamic> res) {
    final data = res['data'];
    if (data is Map<String, dynamic>) return parseReactions(data['reactions']);
    return const [];
  }
}
