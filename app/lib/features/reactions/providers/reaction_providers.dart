import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../data/reaction_repository.dart';

final reactionRepositoryProvider = Provider<ReactionRepository>(
  (ref) => ReactionRepository(DioClient.instance),
);
