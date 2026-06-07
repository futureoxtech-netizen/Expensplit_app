import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/dio_client.dart';
import 'data/app_update_model.dart';
import 'data/app_update_repository.dart';

final appUpdateRepositoryProvider = Provider<AppUpdateRepository>(
  (ref) => AppUpdateRepository(DioClient.instance),
);

/// One-shot check performed at launch. Null means "no info / don't prompt".
final appUpdateCheckProvider = FutureProvider<AppUpdateInfo?>(
  (ref) => ref.read(appUpdateRepositoryProvider).check(),
);
