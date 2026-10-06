import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_tajweed_app/core/services/account_creation_service.dart';
import 'package:quran_tajweed_app/core/services/auth_service.dart';
import 'package:quran_tajweed_app/core/utils/app_failure.dart';
import 'package:quran_tajweed_app/features/admin/data/repositories/firebase_organization_repository.dart';
import 'package:quran_tajweed_app/features/admin/domain/entities/organization.dart';
import 'package:quran_tajweed_app/features/auth/domain/entities/app_user.dart';
import 'package:quran_tajweed_app/features/auth/domain/entities/mosque.dart';
import 'package:quran_tajweed_app/features/auth/domain/entities/user_role.dart';

/// The General Admin is signed in as `admin`.
class _FakeAuthService implements AuthService {
  @override
  String? get currentUid => 'admin';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _system = AdminScope.system();
const _officerScope = AdminScope.region('r1');

Map<String, dynamic> _account(
  String role, {
  String? regionId,
  String? squareId,
  String? mosqueId,
}) => {
  'name': role,
  'email': '$role@example.com',
  'phone': '',
  'role': role,
  'regionId': regionId,
  'squareId': squareId,
  'mosqueId': mosqueId,
  'isActive': true,
};

Map<String, dynamic> _exam(String id) => {
  'examId': id,
  'studentId': 'stu1',
  'mosqueId': 'm1',
  'squareId': 's1',
  'regionId': 'r1',
};

/// The curriculum and the examination data, which no deletion may touch.
const _protected = [
  'courses',
  'tajweed_rules',
  'course_rules',
  'question_bank',
  'question_answers',
  'exam_segments',
  'exams',
  'submissions',
  'evaluations',
  'notifications',
  'certificates',
];

//   r1 ── s1 ── m1 ── stu1, exam e1   (sup1 also named by s1b)
//      ├─ s1b                         (no mosque; named sup1)
//      └─ sEmpty ── mEmpty            (supEmpty; nothing else)
//   r2                                (officer2 only)
//   rEmpty                            (nothing)
final Map<String, Map<String, dynamic>> _seed = {
  'regions/r1': {'name': 'R1', 'officerId': 'officer1', 'isActive': true},
  'regions/r2': {'name': 'R2', 'officerId': 'officer2', 'isActive': true},
  'regions/rEmpty': {'name': 'Empty', 'officerId': null, 'isActive': true},
  'squares/s1': {
    'name': 'S1',
    'regionId': 'r1',
    'supervisorId': 'sup1',
    'isActive': true,
  },
  'squares/s1b': {
    'name': 'S1b',
    'regionId': 'r1',
    'supervisorId': 'sup1',
    'isActive': true,
  },
  'squares/sEmpty': {
    'name': 'Empty',
    'regionId': 'r1',
    'supervisorId': 'supEmpty',
    'isActive': true,
  },
  'mosques/m1': {'name': 'M1', 'squareId': 's1', 'regionId': 'r1'},
  'mosques/mEmpty': {'name': 'Empty', 'squareId': 'sEmpty', 'regionId': 'r1'},
  'users/admin': _account('general_admin'),
  'users/officer1': _account('region_officer', regionId: 'r1'),
  'users/officer2': _account('region_officer', regionId: 'r2'),
  'users/sup1': _account('square_supervisor', regionId: 'r1', squareId: 's1'),
  'users/supEmpty': _account(
    'square_supervisor',
    regionId: 'r1',
    squareId: 'sEmpty',
  ),
  'users/stu1': _account(
    'student',
    regionId: 'r1',
    squareId: 's1',
    mosqueId: 'm1',
  ),
  'staff_invites/sup1': {'role': 'square_supervisor', 'createdBy': 'admin'},
  'staff_invites/officer1': {'role': 'region_officer', 'createdBy': 'admin'},
  'courses/c1': {'name': 'C1'},
  'tajweed_rules/rule1': {'name': 'الإخفاء'},
  'course_rules/c1_rule1': {'courseId': 'c1', 'ruleId': 'rule1'},
  'question_bank/q1': {'question': 'سؤال'},
  'question_answers/q1': {'correctAnswer': 'أ'},
  'exam_segments/seg1': {
    'courseIds': ['c1'],
  },
  'exams/e1': _exam('e1'),
  'submissions/e1': _exam('e1'),
  'evaluations/e1': {'examId': 'e1', 'supervisorId': 'sup1'},
  'certificates/e1': {'examId': 'e1', 'studentId': 'stu1'},
  'notifications/e1_submitted': {'squareId': 's1', 'relatedId': 'e1'},
  'notifications/e1_result': {'userId': 'stu1', 'relatedId': 'e1'},
};

AppUser _user(String uid) {
  return AppUser.fromMap(uid, _seed['users/$uid']!)!;
}

Square _square(String id) => Square.fromMap(id, _seed['squares/$id']!)!;

Mosque _mosque(String id) => Mosque.fromMap(id, _seed['mosques/$id']!)!;

Region _region(String id) => Region.fromMap(id, _seed['regions/$id']!);

void main() {
  late FakeFirebaseFirestore firestore;
  late FirebaseOrganizationRepository repository;
  late Map<String, Map<String, dynamic>> protectedBefore;

  Future<Map<String, dynamic>?> read(String path) async =>
      (await firestore.doc(path).get()).data();

  Future<bool> exists(String path) async =>
      (await firestore.doc(path).get()).exists;

  Future<Map<String, Map<String, dynamic>>> protectedData() async => {
    for (final collection in _protected)
      for (final doc in (await firestore.collection(collection).get()).docs)
        doc.reference.path: doc.data(),
  };

  Future<void> expectRefused(Future<void> deletion, String reason) async {
    await expectLater(
      deletion,
      throwsA(
        isA<AppFailure>().having((f) => f.message, 'message', contains(reason)),
      ),
    );
  }

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    for (final MapEntry(key: path, value: data) in _seed.entries) {
      await firestore.doc(path).set(data);
    }
    repository = FirebaseOrganizationRepository(
      authService: _FakeAuthService(),
      accountCreationService: AccountCreationService(),
      firestore: firestore,
    );
    protectedBefore = await protectedData();
  });

  // Whatever a test does, the curriculum and the examination data stay as
  // they were: nothing is deleted with an account or a unit.
  tearDown(() async {
    expect(await protectedData(), protectedBefore);
    expect(protectedBefore, hasLength(12));
  });

  group('suspending a square supervisor', () {
    test('frees every square that names them, and keeps the rest', () async {
      await repository.setAccountActive(
        scope: _system,
        user: _user('sup1'),
        isActive: false,
      );

      final account = (await read('users/sup1'))!;
      expect(account['isActive'], isFalse);
      expect(account['squareId'], isNull);
      expect((await read('squares/s1'))!['supervisorId'], isNull);
      expect((await read('squares/s1b'))!['supervisorId'], isNull);
      expect((await read('squares/sEmpty'))!['supervisorId'], 'supEmpty');
      expect(await exists('mosques/m1'), isTrue);
      expect(await exists('users/stu1'), isTrue);
    });

    test('the freed square is offered to a new supervisor', () async {
      await repository.setAccountActive(
        scope: _system,
        user: _user('sup1'),
        isActive: false,
      );

      final organization = await repository.fetchOrganization(_system);
      expect(
        organization.squaresOpenTo(null).map((square) => square.id),
        containsAll(['s1', 's1b']),
      );
    });

    test('an officer frees the squares of their own region', () async {
      await repository.setAccountActive(
        scope: _officerScope,
        user: _user('sup1'),
        isActive: false,
      );

      expect((await read('squares/s1'))!['supervisorId'], isNull);
      expect((await read('squares/s1b'))!['supervisorId'], isNull);
    });

    test('suspending a student or reactivating changes no square', () async {
      await repository.setAccountActive(
        scope: _system,
        user: _user('stu1'),
        isActive: false,
      );
      await repository.setAccountActive(
        scope: _system,
        user: _user('sup1'),
        isActive: true,
      );

      expect((await read('users/stu1'))!['squareId'], 's1');
      expect((await read('users/sup1'))!['squareId'], 's1');
      expect((await read('squares/s1'))!['supervisorId'], 'sup1');
    });
  });

  group('deleting a staff account', () {
    test('a supervisor is deleted and cleared from their squares', () async {
      await repository.deleteStaff(scope: _system, user: _user('sup1'));

      expect(await exists('users/sup1'), isFalse);
      expect(await exists('staff_invites/sup1'), isFalse);
      expect((await read('squares/s1'))!['supervisorId'], isNull);
      expect((await read('squares/s1b'))!['supervisorId'], isNull);
      expect(await exists('mosques/m1'), isTrue);
      expect(await exists('users/stu1'), isTrue);
      expect(await exists('regions/r1'), isTrue);
    });

    test('an officer is deleted and the region stays', () async {
      await repository.deleteStaff(scope: _system, user: _user('officer1'));

      expect(await exists('users/officer1'), isFalse);
      expect(await exists('staff_invites/officer1'), isFalse);
      final region = (await read('regions/r1'))!;
      expect(region['officerId'], isNull);
      expect(region['name'], 'R1');
      expect((await read('regions/r2'))!['officerId'], 'officer2');
      expect(await exists('squares/s1'), isTrue);
      expect(await exists('mosques/m1'), isTrue);
      expect(await exists('users/stu1'), isTrue);
    });

    test('an account without an invitation is deleted too', () async {
      await repository.deleteStaff(scope: _system, user: _user('supEmpty'));

      expect(await exists('users/supEmpty'), isFalse);
      expect((await read('squares/sEmpty'))!['supervisorId'], isNull);
    });

    test('a region officer cannot delete an account', () async {
      await expectRefused(
        repository.deleteStaff(scope: _officerScope, user: _user('sup1')),
        'للمدير العام فقط',
      );
      await expectRefused(
        repository.deleteStaff(scope: _officerScope, user: _user('officer2')),
        'للمدير العام فقط',
      );

      expect(await exists('users/sup1'), isTrue);
      expect(await exists('users/officer2'), isTrue);
      expect((await read('squares/s1'))!['supervisorId'], 'sup1');
    });

    test('the General Admin cannot delete their own account', () async {
      // The signed-in account, shown here with a staff role.
      const self = AppUser(
        uid: 'admin',
        name: 'أنا',
        email: 'admin@example.com',
        role: UserRole.regionOfficer,
        isActive: true,
        regionId: 'r1',
      );

      await expectRefused(
        repository.deleteStaff(scope: _system, user: self),
        'لا يمكنك حذف حسابك',
      );
      expect(await exists('users/admin'), isTrue);
    });

    test('a student or a General Admin account is never deleted', () async {
      await expectRefused(
        repository.deleteStaff(scope: _system, user: _user('stu1')),
        'مسؤولي المناطق ومشرفي المربعات فقط',
      );
      await expectRefused(
        repository.deleteStaff(scope: _system, user: _user('admin')),
        'مسؤولي المناطق ومشرفي المربعات فقط',
      );

      expect(await exists('users/stu1'), isTrue);
      expect(await exists('users/admin'), isTrue);
    });
  });

  group('deleting a square', () {
    test(
      'an empty square is deleted; its supervisor and region stay',
      () async {
        await firestore.doc('mosques/mEmpty').delete();

        await repository.deleteSquare(
          scope: _system,
          square: _square('sEmpty'),
        );

        expect(await exists('squares/sEmpty'), isFalse);
        final supervisor = (await read('users/supEmpty'))!;
        expect(supervisor['squareId'], isNull);
        expect(supervisor['regionId'], 'r1');
        expect(await exists('regions/r1'), isTrue);
      },
    );

    test('a square with mosques is refused', () async {
      await expectRefused(
        repository.deleteSquare(scope: _system, square: _square('sEmpty')),
        'مساجد',
      );
      expect(await exists('squares/sEmpty'), isTrue);
      expect(await exists('mosques/mEmpty'), isTrue);
    });

    test('a square with students is refused', () async {
      await firestore.doc('mosques/m1').delete();

      await expectRefused(
        repository.deleteSquare(scope: _system, square: _square('s1')),
        'طلابًا',
      );
      expect(await exists('squares/s1'), isTrue);
      expect((await read('users/sup1'))!['squareId'], 's1');
    });

    test('a square with examinations is refused', () async {
      await firestore.doc('mosques/m1').delete();
      await firestore.doc('users/stu1').delete();

      await expectRefused(
        repository.deleteSquare(scope: _system, square: _square('s1')),
        'امتحانات',
      );
      expect(await exists('squares/s1'), isTrue);
    });

    test('a region officer cannot delete a square', () async {
      await expectRefused(
        repository.deleteSquare(scope: _officerScope, square: _square('s1b')),
        'للمدير العام فقط',
      );
      expect(await exists('squares/s1b'), isTrue);
    });
  });

  group('deleting a mosque', () {
    test('an empty mosque is deleted; its square stays', () async {
      await repository.deleteMosque(scope: _system, mosque: _mosque('mEmpty'));

      expect(await exists('mosques/mEmpty'), isFalse);
      expect(await exists('squares/sEmpty'), isTrue);
    });

    test('a mosque with students is refused', () async {
      await expectRefused(
        repository.deleteMosque(scope: _system, mosque: _mosque('m1')),
        'طلابًا',
      );
      expect(await exists('mosques/m1'), isTrue);
    });

    test('a mosque with examinations is refused', () async {
      await firestore.doc('users/stu1').delete();

      await expectRefused(
        repository.deleteMosque(scope: _system, mosque: _mosque('m1')),
        'امتحانات',
      );
      expect(await exists('mosques/m1'), isTrue);
    });

    test('a region officer cannot delete a mosque', () async {
      await expectRefused(
        repository.deleteMosque(
          scope: _officerScope,
          mosque: _mosque('mEmpty'),
        ),
        'للمدير العام فقط',
      );
      expect(await exists('mosques/mEmpty'), isTrue);
    });
  });

  group('deleting a region', () {
    test('an empty region is deleted', () async {
      await repository.deleteRegion(scope: _system, region: _region('rEmpty'));

      expect(await exists('regions/rEmpty'), isFalse);
      expect(await exists('regions/r1'), isTrue);
    });

    test('a region with squares is refused', () async {
      await expectRefused(
        repository.deleteRegion(scope: _system, region: _region('r1')),
        'مربعات',
      );
      expect(await exists('regions/r1'), isTrue);
      expect(await exists('squares/s1'), isTrue);
    });

    test(
      'a region with mosques, accounts or examinations is refused',
      () async {
        for (final square in ['s1', 's1b', 'sEmpty']) {
          await firestore.doc('squares/$square').delete();
        }
        await expectRefused(
          repository.deleteRegion(scope: _system, region: _region('r1')),
          'مساجد',
        );

        await firestore.doc('mosques/m1').delete();
        await firestore.doc('mosques/mEmpty').delete();
        await expectRefused(
          repository.deleteRegion(scope: _system, region: _region('r1')),
          'حسابات',
        );

        for (final uid in ['officer1', 'sup1', 'supEmpty', 'stu1']) {
          await firestore.doc('users/$uid').delete();
        }
        await expectRefused(
          repository.deleteRegion(scope: _system, region: _region('r1')),
          'امتحانات',
        );
        expect(await exists('regions/r1'), isTrue);
      },
    );

    test('a region that still has its officer is refused', () async {
      await expectRefused(
        repository.deleteRegion(scope: _system, region: _region('r2')),
        'حسابات',
      );
      expect(await exists('regions/r2'), isTrue);
      expect(await exists('users/officer2'), isTrue);
    });

    test('a region officer cannot delete a region', () async {
      await expectRefused(
        repository.deleteRegion(
          scope: _officerScope,
          region: _region('rEmpty'),
        ),
        'للمدير العام فقط',
      );
      expect(await exists('regions/rEmpty'), isTrue);
    });
  });
}
