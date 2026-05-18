import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../data/report_model.dart';
import '../data/report_repository.dart';

final reportRepositoryProvider = Provider<ReportRepository>(
  (ref) => ReportRepository(DioClient.instance),
);

class ReportQuery {
  const ReportQuery({required this.from, required this.to, this.groupId});

  final DateTime from;
  final DateTime to;
  final String? groupId;

  @override
  bool operator ==(Object other) =>
      other is ReportQuery &&
      other.from == from &&
      other.to == to &&
      other.groupId == groupId;

  @override
  int get hashCode => Object.hash(from, to, groupId);
}

final reportProvider =
    FutureProvider.autoDispose.family<ReportData, ReportQuery>((ref, q) async {
  return ref.watch(reportRepositoryProvider).fetch(
        from: q.from,
        to: q.to,
        groupId: q.groupId,
      );
});
