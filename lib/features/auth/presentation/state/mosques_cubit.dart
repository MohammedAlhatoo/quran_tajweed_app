import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/mosque.dart';
import '../../domain/repositories/auth_repository.dart';

sealed class MosquesState {
  const MosquesState();
}

class MosquesLoading extends MosquesState {
  const MosquesLoading();
}

class MosquesLoaded extends MosquesState {
  const MosquesLoaded(this.mosques);

  final List<Mosque> mosques;
}

class MosquesError extends MosquesState {
  const MosquesError(this.message);

  final String message;
}

/// Loads the active mosques a student can choose from during registration.
class MosquesCubit extends Cubit<MosquesState> {
  MosquesCubit(this._repository) : super(const MosquesLoading());

  final AuthRepository _repository;

  Future<void> load() async {
    emit(const MosquesLoading());
    try {
      emit(MosquesLoaded(await _repository.fetchActiveMosques()));
    } on AuthFailure catch (failure) {
      emit(MosquesError(failure.message));
    }
  }
}
