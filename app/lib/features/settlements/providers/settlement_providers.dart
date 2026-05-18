import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../data/settlement_repository.dart';

final settlementRepositoryProvider = Provider<SettlementRepository>(
  (ref) => SettlementRepository(DioClient.instance),
);
