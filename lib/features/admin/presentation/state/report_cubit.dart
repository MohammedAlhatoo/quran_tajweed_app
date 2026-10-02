import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/app_failure.dart';
import '../../domain/entities/exam_report.dart';
import '../../domain/repositories/reports_repository.dart';

sealed class ReportState {
  const ReportState();
}

class ReportLoading extends ReportState {
  const ReportLoading();
}

class ReportLoaded extends ReportState {
  const ReportLoaded(this.report);

  final ExamReport report;
}

class ReportError extends ReportState {
  const ReportError(this.message);

  final String message;
}

/// The report of one scope: a square, a region or the whole system.
class ReportCubit extends Cubit<ReportState> {
  ReportCubit(this._repository, this._scope) : super(const ReportLoading());

  final ReportsRepository _repository;

  /// Null when the account has no scope yet, such as a supervisor without a
  /// square.
  final ReportScope? _scope;

  Future<void> load() async {
    final scope = _scope;
    if (scope == null) {
      emit(const ReportError('حسابك غير مرتبط بنطاق. تواصل مع الإدارة.'));
      return;
    }
    // Keep the current report visible while refreshing.
    if (state is! ReportLoaded) emit(const ReportLoading());
    try {
      emit(ReportLoaded(await _repository.fetchReport(scope)));
    } on AppFailure catch (failure) {
      emit(ReportError(failure.message));
    }
  }
}
