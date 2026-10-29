import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/report_repository.dart';
import '../domain/report.dart';

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepository();
});

final allReportsStreamProvider = StreamProvider<List<Report>>((ref) {
  final repository = ref.watch(reportRepositoryProvider);
  return repository.streamAllReports();
});
