import 'package:flutter_test/flutter_test.dart';
import 'package:quran_tajweed_app/core/utils/app_failure.dart';
import 'package:quran_tajweed_app/features/admin/domain/entities/organization.dart';
import 'package:quran_tajweed_app/features/admin/domain/repositories/organization_repository.dart';
import 'package:quran_tajweed_app/features/admin/presentation/state/organization_cubit.dart';
import 'package:quran_tajweed_app/features/auth/domain/entities/app_user.dart';
import 'package:quran_tajweed_app/features/auth/domain/entities/mosque.dart';
import 'package:quran_tajweed_app/features/auth/domain/entities/user_role.dart';

const _supervisor = AppUser(
  uid: 'sup-1',
  name: 'مشرف',
  email: 'sup@example.com',
  role: UserRole.squareSupervisor,
  isActive: true,
  regionId: 'region-1',
  squareId: 'square-1',
);

const _student = AppUser(
  uid: 'uid-1',
  name: 'طالب',
  email: 'student@example.com',
  role: UserRole.student,
  isActive: true,
  regionId: 'region-1',
  squareId: 'square-1',
  mosqueId: 'mosque-1',
);

const _squares = [
  Square(
    id: 'square-1',
    name: 'المربع الأول',
    regionId: 'region-1',
    isActive: true,
    supervisorId: 'sup-1',
  ),
  Square(
    id: 'square-2',
    name: 'المربع الثاني',
    regionId: 'region-1',
    isActive: true,
  ),
  Square(
    id: 'square-3',
    name: 'المربع الثالث',
    regionId: 'region-1',
    isActive: true,
    supervisorId: 'sup-9',
  ),
];

const _mosque = Mosque(
  id: 'mosque-1',
  name: 'مسجد النور',
  squareId: 'square-1',
  regionId: 'region-1',
);

const _organization = Organization(
  regions: [Region(id: 'region-1', name: 'المنطقة الأولى', isActive: true)],
  squares: _squares,
  mosques: [_mosque],
  users: [_supervisor, _student],
);

class _FakeOrganizationRepository implements OrganizationRepository {
  AppFailure? failure;
  AppFailure? loadFailure;
  final calls = <String>[];
  AdminScope? loadedScope;

  Future<void> _record(String call) async {
    if (failure case final failure?) throw failure;
    calls.add(call);
  }

  @override
  Future<Organization> fetchOrganization(AdminScope scope) async {
    if (loadFailure case final failure?) throw failure;
    loadedScope = scope;
    return _organization;
  }

  @override
  Future<void> saveRegion({
    String? id,
    required String name,
    required bool isActive,
  }) => _record('region:$id:$name:$isActive');

  @override
  Future<void> saveSquare({
    String? id,
    required String name,
    required String regionId,
    required bool isActive,
  }) => _record('square:$id:$name:$regionId:$isActive');

  @override
  Future<void> saveMosque({
    String? id,
    required String name,
    required String address,
    required Square square,
    required bool isActive,
  }) => _record('mosque:$id:$name:${square.id}:$isActive');

  @override
  Future<void> moveMosque({
    required AdminScope scope,
    required Mosque mosque,
    required Square square,
  }) => _record('move:${scope.regionId}:${mosque.id}:${square.id}');

  @override
  Future<void> createStaff({
    required String name,
    required String email,
    required String phone,
    required UserRole role,
    required String regionId,
    String? squareId,
  }) => _record('create:${role.value}:$email:$regionId:$squareId');

  @override
  Future<void> assignStaff({
    required AppUser user,
    required String regionId,
    String? squareId,
  }) => _record('assign:${user.uid}:$regionId:$squareId');

  @override
  Future<void> setAccountActive({
    required AppUser user,
    required bool isActive,
  }) => _record('active:${user.uid}:$isActive');

  @override
  Future<void> sendPasswordReset(String email) => _record('reset:$email');
}

void main() {
  late _FakeOrganizationRepository repository;
  late OrganizationCubit cubit;

  setUp(() {
    repository = _FakeOrganizationRepository();
    cubit = OrganizationCubit(repository, const AdminScope.region('region-1'));
  });

  group('entities', () {
    test('the system scope has no region', () {
      expect(const AdminScope.system().isSystem, isTrue);
      expect(const AdminScope.region('region-1').isSystem, isFalse);
    });

    test('Square.fromMap needs a region', () {
      expect(Square.fromMap('s', {'name': 'مربع'}), isNull);
      final square = Square.fromMap('s', {
        'name': 'مربع',
        'regionId': 'region-1',
        'isActive': true,
      })!;
      expect(square.supervisorId, isNull);
      expect(square.isActive, isTrue);
    });

    test('Mosque.fromMap reads the address and whether it is active', () {
      final mosque = Mosque.fromMap('m', {
        'name': 'مسجد',
        'squareId': 'square-1',
        'regionId': 'region-1',
        'address': 'شارع',
      })!;
      expect(mosque.address, 'شارع');
      expect(mosque.isActive, isFalse);
    });

    test('a supervisor is offered free squares and their own', () {
      expect(_organization.squaresOpenTo(null).map((s) => s.id), ['square-2']);
      expect(_organization.squaresOpenTo(_supervisor).map((s) => s.id), [
        'square-1',
        'square-2',
      ]);
    });

    test('names fall back when the unit is outside the scope', () {
      expect(_organization.squareName('square-2'), 'المربع الثاني');
      expect(_organization.squareName(null), 'بدون مربع');
      expect(_organization.userName('sup-1'), 'مشرف');
      expect(_organization.userName('someone-else'), isNull);
      expect(_organization.usersWithRole(UserRole.student), [_student]);
    });
  });

  group('OrganizationCubit', () {
    test('load reads the organization of its scope', () async {
      await cubit.load();

      expect(repository.loadedScope!.regionId, 'region-1');
      expect(cubit.state.organization, same(_organization));
      expect(cubit.state.loadError, isNull);
    });

    test('a failed first load is reported', () async {
      repository.loadFailure = const AppFailure('تعذّر الاتصال.');

      await cubit.load();

      expect(cubit.state.organization, isNull);
      expect(cubit.state.loadError, 'تعذّر الاتصال.');
    });

    test('a change is saved, then the data is reloaded', () async {
      await cubit.load();
      repository.loadedScope = null;

      await cubit.saveSquare(name: 'مربع جديد', regionId: 'region-1');

      expect(repository.calls, ['square:null:مربع جديد:region-1:true']);
      expect(repository.loadedScope, isNotNull);
      expect(cubit.state.isBusy, isFalse);
      expect(cubit.state.isError, isFalse);
      expect(cubit.state.message, isNotNull);
    });

    test('moving a mosque passes the administrator scope', () async {
      await cubit.load();

      await cubit.moveMosque(mosque: _mosque, square: _squares[1]);

      expect(repository.calls, ['move:region-1:mosque-1:square-2']);
    });

    test('accounts are created, linked and suspended', () async {
      await cubit.load();

      await cubit.createStaff(
        name: 'مشرف جديد',
        email: 'new@example.com',
        phone: '0599000000',
        role: UserRole.squareSupervisor,
        regionId: 'region-1',
        squareId: 'square-2',
      );
      await cubit.assignStaff(user: _supervisor, regionId: 'region-1');
      await cubit.setAccountActive(user: _student, isActive: false);
      await cubit.sendPasswordReset('sup@example.com');

      expect(repository.calls, [
        'create:square_supervisor:new@example.com:region-1:square-2',
        'assign:sup-1:region-1:null',
        'active:uid-1:false',
        'reset:sup@example.com',
      ]);
    });

    test('a failed change is reported and keeps the data', () async {
      await cubit.load();
      repository.failure = const AppFailure(
        'لا تملك صلاحية تنفيذ هذا الإجراء.',
      );

      await cubit.saveRegion(name: 'منطقة');

      expect(cubit.state.isError, isTrue);
      expect(cubit.state.message, 'لا تملك صلاحية تنفيذ هذا الإجراء.');
      expect(cubit.state.organization, same(_organization));
      expect(repository.calls, isEmpty);
    });
  });
}
