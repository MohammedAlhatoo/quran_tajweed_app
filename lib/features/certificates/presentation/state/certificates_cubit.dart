import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/app_failure.dart';
import '../../domain/entities/certificate.dart';
import '../../domain/repositories/certificates_repository.dart';

sealed class CertificatesState {
  const CertificatesState();
}

class CertificatesLoading extends CertificatesState {
  const CertificatesLoading();
}

class CertificatesLoaded extends CertificatesState {
  const CertificatesLoaded(this.certificates);

  final List<Certificate> certificates;
}

class CertificatesError extends CertificatesState {
  const CertificatesError(this.message);

  final String message;
}

/// The student's certificates, newest first.
class CertificatesCubit extends Cubit<CertificatesState> {
  CertificatesCubit(this._repository, this._studentId)
    : super(const CertificatesLoading());

  final CertificatesRepository _repository;
  final String _studentId;

  Future<void> load() async {
    emit(const CertificatesLoading());
    try {
      emit(
        CertificatesLoaded(
          await _repository.fetchStudentCertificates(_studentId),
        ),
      );
    } on AppFailure catch (failure) {
      emit(CertificatesError(failure.message));
    }
  }
}
