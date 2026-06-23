import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/local_store.dart';
import '../../../core/sync/sync_engine.dart';
import '../data/reaction_repository.dart';

final reactionRepositoryProvider = Provider<ReactionRepository>(
  (ref) => ReactionRepository(LocalStore.instance, SyncEngine.instance),
);
