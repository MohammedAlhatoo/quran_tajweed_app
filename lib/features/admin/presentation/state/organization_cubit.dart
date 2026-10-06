import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/app_failure.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/domain/entities/mosque.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../domain/entities/organization.dart';
import '../../domain/repositories/organization_repository.dart';

class OrganizationState {
  const OrganizationState({
    this.organization,
    this.isBusy = false,
    this.loadError,
    this.message,
    this.isError = false,
  });

  /// Null until the first load succeeds.
  final Organization? organization;

  /// A change is being saved.
  final bool isBusy;

  /// Why the first load failed.
  final String? loadError;

  /// The outcome of the last change, set only on the state it produced.
  final String? message;

  /// Whether [message] reports a failure.
  final bool isError;
}

/// The regions, squares, mosques and accounts an administrator manages, and
/// the changes to them. Every change reloads the data.
class OrganizationCubit extends Cubit<OrganizationState> {
  OrganizationCubit(this._repository, this.scope)
    : super(const OrganizationState());

  final OrganizationRepository _repository;

  /// The whole system for the General Admin, one region for an officer.
  final AdminScope scope;

  Future<void> load() async {
    try {
      emit(
        OrganizationState(
          organization: await _repository.fetchOrganization(scope),
        ),
      );
    } on AppFailure catch (failure) {
      emit(
        OrganizationState(
          organization: state.organization,
          loadError: state.organization == null ? failure.message : null,
          message: state.organization == null ? null : failure.message,
          isError: true,
        ),
      );
    }
  }

  Future<void> saveRegion({
    String? id,
    required String name,
    bool isActive = true,
  }) => _change(
    () => _repository.saveRegion(id: id, name: name, isActive: isActive),
    success: 'تم حفظ المنطقة.',
  );

  Future<void> saveSquare({
    String? id,
    required String name,
    required String regionId,
    bool isActive = true,
  }) => _change(
    () => _repository.saveSquare(
      id: id,
      name: name,
      regionId: regionId,
      isActive: isActive,
    ),
    success: 'تم حفظ المربع.',
  );

  Future<void> saveMosque({
    String? id,
    required String name,
    required String address,
    required Square square,
    bool isActive = true,
  }) => _change(
    () => _repository.saveMosque(
      id: id,
      name: name,
      address: address,
      square: square,
      isActive: isActive,
    ),
    success: 'تم حفظ المسجد.',
  );

  Future<void> moveMosque({required Mosque mosque, required Square square}) =>
      _change(
        () => _repository.moveMosque(
          scope: scope,
          mosque: mosque,
          square: square,
        ),
        success: 'تم نقل المسجد وطلابه إلى المربع الجديد.',
      );

  Future<void> createStaff({
    required String name,
    required String email,
    required String phone,
    required UserRole role,
    required String regionId,
    String? squareId,
  }) => _change(
    () => _repository.createStaff(
      name: name,
      email: email,
      phone: phone,
      role: role,
      regionId: regionId,
      squareId: squareId,
    ),
    success: 'تم إنشاء الحساب وإرسال رابط تعيين كلمة المرور إلى بريده.',
  );

  Future<void> assignStaff({
    required AppUser user,
    required String regionId,
    String? squareId,
  }) => _change(
    () => _repository.assignStaff(
      user: user,
      regionId: regionId,
      squareId: squareId,
    ),
    success: 'تم تحديث ارتباط الحساب.',
  );

  Future<void> setAccountActive({
    required AppUser user,
    required bool isActive,
  }) => _change(
    () => _repository.setAccountActive(
      scope: scope,
      user: user,
      isActive: isActive,
    ),
    success: isActive ? 'تم تفعيل الحساب.' : 'تم إيقاف الحساب.',
  );

  Future<void> deleteStaff(AppUser user) => _change(
    () => _repository.deleteStaff(scope: scope, user: user),
    success: 'تم حذف الحساب.',
  );

  Future<void> deleteSquare(Square square) => _change(
    () => _repository.deleteSquare(scope: scope, square: square),
    success: 'تم حذف المربع.',
  );

  Future<void> deleteMosque(Mosque mosque) => _change(
    () => _repository.deleteMosque(scope: scope, mosque: mosque),
    success: 'تم حذف المسجد.',
  );

  Future<void> deleteRegion(Region region) => _change(
    () => _repository.deleteRegion(scope: scope, region: region),
    success: 'تم حذف المنطقة.',
  );

  Future<void> sendPasswordReset(String email) => _change(
    () => _repository.sendPasswordReset(email),
    success: 'تم إرسال رابط تعيين كلمة المرور.',
  );

  /// Runs [change], reloads, and reports the outcome. A change that fails
  /// half-way is still followed by a reload, so the screen shows what was
  /// actually saved.
  Future<void> _change(
    Future<void> Function() change, {
    required String success,
  }) async {
    if (state.isBusy) return;
    emit(OrganizationState(organization: state.organization, isBusy: true));
    var message = success;
    var isError = false;
    try {
      await change();
    } on AppFailure catch (failure) {
      message = failure.message;
      isError = true;
    }
    var organization = state.organization;
    try {
      organization = await _repository.fetchOrganization(scope);
    } on AppFailure {
      // The previous data stays on screen.
    }
    emit(
      OrganizationState(
        organization: organization,
        message: message,
        isError: isError,
      ),
    );
  }
}
