import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/app_failure.dart';
import '../../domain/repositories/student_profile_repository.dart';

sealed class MosqueNameState {
  const MosqueNameState();
}

class MosqueNameLoading extends MosqueNameState {
  const MosqueNameLoading();
}

class MosqueNameLoaded extends MosqueNameState {
  const MosqueNameLoaded(this.name);

  /// Null when the mosque cannot be shown.
  final String? name;
}

class MosqueNameError extends MosqueNameState {
  const MosqueNameError(this.message);

  final String message;
}

/// Loads the name of the student's mosque for the personal info screen.
class MosqueNameCubit extends Cubit<MosqueNameState> {
  MosqueNameCubit(this._repository) : super(const MosqueNameLoading());

  final StudentProfileRepository _repository;

  Future<void> load(String? mosqueId) async {
    if (mosqueId == null) {
      emit(const MosqueNameLoaded(null));
      return;
    }
    emit(const MosqueNameLoading());
    try {
      emit(MosqueNameLoaded(await _repository.fetchMosqueName(mosqueId)));
    } on AppFailure catch (failure) {
      emit(MosqueNameError(failure.message));
    }
  }
}
