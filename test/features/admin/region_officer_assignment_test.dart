import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_tajweed_app/core/services/account_creation_service.dart';
import 'package:quran_tajweed_app/core/services/auth_service.dart';
import 'package:quran_tajweed_app/core/utils/app_failure.dart';
import 'package:quran_tajweed_app/features/admin/data/repositories/firebase_organization_repository.dart';
import 'package:quran_tajweed_app/features/admin/domain/entities/organization.dart';
import 'package:quran_tajweed_app/features/admin/presentation/pages/accounts_view.dart';
import 'package:quran_tajweed_app/features/admin/presentation/pages/units_views.dart';
import 'package:quran_tajweed_app/features/admin/presentation/state/organization_cubit.dart';
import 'package:quran_tajweed_app/features/admin/presentation/widgets/org_widgets.dart';
import 'package:quran_tajweed_app/features/auth/domain/entities/app_user.dart';
import 'package:quran_tajweed_app/features/auth/domain/entities/user_role.dart';

/// The General Admin is signed in as `admin`.
class _FakeAuthService implements AuthService {
  final resetEmails = <String>[];

  @override
  String? get currentUid => 'admin';

  @override
  Future<void> sendPasswordResetEmail(String email) async =>
      resetEmails.add(email);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Creates accounts `new-1`, `new-2`… and writes their profiles to the same
/// database as the administrator.
class _FakeAccountCreationService extends AccountCreationService {
  _FakeAccountCreationService(this._firestore);

  final FakeFirebaseFirestore _firestore;

  /// The emails of the Firebase Authentication accounts created.
  final created = <String>[];
  var discarded = 0;

  /// Runs once the profile is written, before the region is claimed.
  Future<void> Function()? afterProfile;

  @override
  Future<({String uid, String email})> create(String email) async {
    created.add(email);
    return (uid: 'new-${created.length}', email: email);
  }

  @override
  Future<void> saveProfile(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).set(data);
    await afterProfile?.call();
  }

  @override
  Future<bool> discard() async {
    discarded++;
    return true;
  }

  @override
  Future<void> finish() async {}
}

const _system = AdminScope.system();

Map<String, dynamic> _account(
  String role, {
  String? regionId,
  String? squareId,
}) => {
  'name': role,
  'email': '$role@example.com',
  'phone': '',
  'role': role,
  'regionId': regionId,
  'squareId': squareId,
  'mosqueId': null,
  'isActive': true,
};

//   rTaken ── officer1, and the square sFree without a supervisor
//   rFree     (no officer)
final Map<String, Map<String, dynamic>> _seed = {
  'regions/rTaken': {'name': 'Taken', 'officerId': 'officer1', 'isActive': true},
  'regions/rFree': {'name': 'Free', 'officerId': null, 'isActive': true},
  'squares/sFree': {
    'name': 'S',
    'regionId': 'rTaken',
    'supervisorId': null,
    'isActive': true,
  },
  'users/admin': _account('general_admin'),
  'users/officer1': _account('region_officer', regionId: 'rTaken'),
};

void main() {
  late FakeFirebaseFirestore firestore;
  late _FakeAuthService auth;
  late _FakeAccountCreationService accounts;
  late FirebaseOrganizationRepository repository;

  Future<Map<String, dynamic>?> read(String path) async =>
      (await firestore.doc(path).get()).data();

  Future<List<String>> officerUids() async => [
    for (final doc in (await firestore.collection('users').get()).docs)
      if (doc.data()['role'] == 'region_officer') doc.id,
  ];

  Future<int> count(String collection) async =>
      (await firestore.collection(collection).get()).docs.length;

  Future<void> createOfficer(String regionId, {String email = 'o@x.com'}) =>
      repository.createStaff(
        name: 'مسؤول جديد',
        email: email,
        phone: '0599000000',
        role: UserRole.regionOfficer,
        regionId: regionId,
      );

  Future<void> expectRefused(Future<void> action, String reason) async {
    await expectLater(
      action,
      throwsA(
        isA<AppFailure>().having((f) => f.message, 'message', contains(reason)),
      ),
    );
  }

  /// Nothing was created, and the occupied region and its officer are as
  /// they were.
  Future<void> expectNothingCreated() async {
    expect(accounts.created.length, accounts.discarded);
    expect(await officerUids(), ['officer1']);
    expect(await count('staff_invites'), 0);
    expect(auth.resetEmails, isEmpty);
    expect((await read('regions/rTaken'))!['officerId'], 'officer1');
    expect((await read('users/officer1'))!['regionId'], 'rTaken');
  }

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    for (final MapEntry(key: path, value: data) in _seed.entries) {
      await firestore.doc(path).set(data);
    }
    auth = _FakeAuthService();
    accounts = _FakeAccountCreationService(firestore);
    repository = FirebaseOrganizationRepository(
      authService: auth,
      accountCreationService: accounts,
      firestore: firestore,
    );
  });

  group('creating a region officer', () {
    test('a region without an officer gets the new one, both ways', () async {
      await createOfficer('rFree');

      expect((await read('regions/rFree'))!['officerId'], 'new-1');
      final officer = (await read('users/new-1'))!;
      expect(officer['role'], 'region_officer');
      expect(officer['regionId'], 'rFree');
      expect(officer['squareId'], isNull);
      expect(accounts.discarded, 0);
      expect(auth.resetEmails, ['o@x.com']);
      // The other region and its officer are untouched.
      expect((await read('regions/rTaken'))!['officerId'], 'officer1');
      expect((await read('users/officer1'))!['regionId'], 'rTaken');
    });

    test('an occupied region is refused before anything is created', () async {
      await expectRefused(createOfficer('rTaken'), 'مسؤول بالفعل');

      expect(accounts.created, isEmpty);
      await expectNothingCreated();
    });

    test('no region selected is refused', () async {
      await expectRefused(createOfficer(''), 'اختر المنطقة');

      expect(accounts.created, isEmpty);
      await expectNothingCreated();
    });

    test('a region that does not exist is refused', () async {
      await firestore.doc('regions/rTaken').delete();
      await firestore.doc('regions/rFree').delete();

      await expectRefused(createOfficer('rFree'), 'غير موجودة');

      expect(accounts.created, isEmpty);
      expect(await officerUids(), ['officer1']);
    });

    test('a region an officer account still points to is refused', () async {
      // Left over from the old behaviour: the region no longer names the
      // account, but the account still belongs to it.
      await firestore.doc('regions/rTaken').update({'officerId': null});

      await expectRefused(createOfficer('rTaken'), 'مسؤول بالفعل');

      expect(accounts.created, isEmpty);
      expect(await officerUids(), ['officer1']);
      expect((await read('regions/rTaken'))!['officerId'], isNull);
    });

    test('a second officer for the same region is refused', () async {
      await createOfficer('rFree');

      await expectRefused(
        createOfficer('rFree', email: 'second@x.com'),
        'مسؤول بالفعل',
      );

      expect(accounts.created, ['o@x.com']);
      expect(await officerUids(), unorderedEquals(['officer1', 'new-1']));
      expect((await read('regions/rFree'))!['officerId'], 'new-1');
      expect((await read('users/new-1'))!['regionId'], 'rFree');
    });

    test(
      'a region taken while the account was being created keeps its officer, '
      'and the new account is taken back',
      () async {
        accounts.afterProfile = () async {
          await firestore
              .doc('users/rival')
              .set(_account('region_officer', regionId: 'rFree'));
          await firestore.doc('regions/rFree').update({'officerId': 'rival'});
        };

        await expectRefused(createOfficer('rFree'), 'مسؤول بالفعل');

        expect((await read('regions/rFree'))!['officerId'], 'rival');
        expect((await read('users/rival'))!['regionId'], 'rFree');
        expect(await read('users/new-1'), isNull);
        expect(await count('staff_invites'), 0);
        expect(accounts.discarded, 1);
        expect(auth.resetEmails, isEmpty);
        expect(await officerUids(), unorderedEquals(['officer1', 'rival']));
      },
    );

    test('a square supervisor is created as before', () async {
      await repository.createStaff(
        name: 'مشرف',
        email: 's@x.com',
        phone: '0599000000',
        role: UserRole.squareSupervisor,
        regionId: 'rTaken',
        squareId: 'sFree',
      );

      expect((await read('squares/sFree'))!['supervisorId'], 'new-1');
      final supervisor = (await read('users/new-1'))!;
      expect(supervisor['regionId'], 'rTaken');
      expect(supervisor['squareId'], 'sFree');
      expect((await read('regions/rTaken'))!['officerId'], 'officer1');
      expect(auth.resetEmails, ['s@x.com']);
    });
  });

  group('moving a region officer', () {
    AppUser officer(String uid, Map<String, dynamic> data) =>
        AppUser.fromMap(uid, data)!;

    test('to a free region: the account and both regions change', () async {
      await repository.assignStaff(
        user: officer('officer1', _seed['users/officer1']!),
        regionId: 'rFree',
      );

      expect((await read('users/officer1'))!['regionId'], 'rFree');
      expect((await read('regions/rFree'))!['officerId'], 'officer1');
      expect((await read('regions/rTaken'))!['officerId'], isNull);
    });

    test('to an occupied region is refused and changes nothing', () async {
      await createOfficer('rFree');
      final newcomer = officer('new-1', (await read('users/new-1'))!);

      await expectRefused(
        repository.assignStaff(user: newcomer, regionId: 'rTaken'),
        'مسؤول بالفعل',
      );

      expect((await read('regions/rTaken'))!['officerId'], 'officer1');
      expect((await read('users/officer1'))!['regionId'], 'rTaken');
      expect((await read('users/new-1'))!['regionId'], 'rFree');
      expect((await read('regions/rFree'))!['officerId'], 'new-1');
    });

    test('to their own region again keeps the link', () async {
      await repository.assignStaff(
        user: officer('officer1', _seed['users/officer1']!),
        regionId: 'rTaken',
      );

      expect((await read('users/officer1'))!['regionId'], 'rTaken');
      expect((await read('regions/rTaken'))!['officerId'], 'officer1');
    });
  });

  group('what the lists show', () {
    const first = AppUser(
      uid: 'o1',
      name: 'الأول',
      email: 'o1@example.com',
      role: UserRole.regionOfficer,
      isActive: true,
      regionId: 'a',
    );
    const stale = AppUser(
      uid: 'o2',
      name: 'القديم',
      email: 'o2@example.com',
      role: UserRole.regionOfficer,
      isActive: true,
      regionId: 'a',
    );
    const regionA = Region(id: 'a', name: 'أ', isActive: true, officerId: 'o1');
    const regionB = Region(id: 'b', name: 'ب', isActive: true);

    Organization organization(List<Region> regions, List<AppUser> users) =>
        Organization(
          regions: regions,
          squares: const [],
          mosques: const [],
          users: users,
        );

    test('only regions without an officer are offered to a new one', () {
      final consistent = organization([regionA, regionB], [first]);

      expect(consistent.regionsOpenTo(null).map((r) => r.id), ['b']);
      expect(consistent.regionsOpenTo(first).map((r) => r.id), ['a', 'b']);
      expect(organization([regionA], [first]).regionsOpenTo(null), isEmpty);
    });

    test('a region an account still points to is not offered', () {
      const unnamed = Region(id: 'a', name: 'أ', isActive: true);
      final leftover = organization([unnamed], [stale]);

      expect(leftover.regionsOpenTo(null), isEmpty);
      // Its own account can be linked to it again.
      expect(leftover.regionsOpenTo(stale).map((r) => r.id), ['a']);
    });

    test('two accounts on one region are both shown, and flagged', () {
      final broken = organization([regionA, regionB], [first, stale]);

      expect(broken.officersOf('a'), [first, stale]);
      expect(broken.hasConsistentOfficer(regionA), isFalse);
      expect(broken.isOfficerOfRegion(first), isTrue);
      expect(broken.isOfficerOfRegion(stale), isFalse);
      // The occupied region is offered to neither a new officer nor the
      // account it does not name.
      expect(broken.regionsOpenTo(stale).map((r) => r.id), ['b']);
    });

    test('consistent data is not flagged', () {
      final consistent = organization([regionA, regionB], [first]);

      expect(consistent.hasConsistentOfficer(regionA), isTrue);
      expect(consistent.hasConsistentOfficer(regionB), isTrue);
      expect(consistent.isOfficerOfRegion(first), isTrue);
    });

    test('a region naming an account that is not its officer is flagged', () {
      const dangling = Region(
        id: 'b',
        name: 'ب',
        isActive: true,
        officerId: 'gone',
      );
      final broken = organization([dangling], [first]);

      expect(broken.officersOf('b'), isEmpty);
      expect(broken.hasConsistentOfficer(dangling), isFalse);
    });
  });

  group('the account screens', () {
    Future<OrganizationCubit> pump(WidgetTester tester, Widget view) async {
      final cubit = OrganizationCubit(repository, _system);
      addTearDown(cubit.close);
      await tester.runAsync(cubit.load);
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: BlocProvider.value(
                value: cubit,
                child: OrganizationMessages(child: view),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return cubit;
    }

    const officers = AccountsView(roles: [UserRole.regionOfficer]);

    testWidgets('no regions: creation is blocked with a message', (
      tester,
    ) async {
      await firestore.doc('regions/rTaken').delete();
      await firestore.doc('regions/rFree').delete();
      await pump(tester, officers);

      await tester.tap(find.text('إضافة مسؤول منطقة'));
      await tester.pumpAndSettle();

      expect(find.text('لا توجد مناطق. أضف منطقة أولًا.'), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      expect(accounts.created, isEmpty);
    });

    testWidgets('every region occupied: creation is blocked with a message', (
      tester,
    ) async {
      await firestore.doc('regions/rFree').delete();
      await pump(tester, officers);

      await tester.tap(find.text('إضافة مسؤول منطقة'));
      await tester.pumpAndSettle();

      expect(
        find.text('لكل منطقة مسؤول بالفعل. أضف منطقة جديدة أولًا.'),
        findsOneWidget,
      );
      expect(find.byType(AlertDialog), findsNothing);
      expect(accounts.created, isEmpty);
    });

    testWidgets('no region selected: the form asks for one', (tester) async {
      await pump(tester, officers);

      await tester.tap(find.text('إضافة مسؤول منطقة'));
      await tester.pumpAndSettle();
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'مسؤول جديد');
      await tester.enterText(fields.at(1), 'o@x.com');
      await tester.enterText(fields.at(2), '0599000000');
      await tester.tap(find.text('إنشاء الحساب'));
      await tester.pumpAndSettle();

      expect(find.text('اختر المنطقة'), findsOneWidget);
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(accounts.created, isEmpty);
    });

    testWidgets('the occupied region is not among the choices', (tester) async {
      await pump(tester, officers);

      await tester.tap(find.text('إضافة مسؤول منطقة'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      expect(find.text('Free'), findsWidgets);
      expect(find.text('Taken'), findsNothing);
    });

    testWidgets('both lists flag two accounts on one region', (tester) async {
      await firestore
          .doc('users/old')
          .set(_account('region_officer', regionId: 'rTaken'));

      await pump(tester, officers);
      expect(
        find.text('تنبيه: المنطقة لا تسجّل هذا الحساب مسؤولًا لها.'),
        findsOneWidget,
      );

      await pump(tester, const RegionsView());
      expect(
        find.text('تنبيه: ربط المسؤول غير متطابق. راجع حسابات المسؤولين.'),
        findsOneWidget,
      );
      expect(find.text('المسؤول: بدون مسؤول'), findsOneWidget);
    });
  });
}
