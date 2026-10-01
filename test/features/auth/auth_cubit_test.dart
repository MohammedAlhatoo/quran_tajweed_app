import 'package:flutter_test/flutter_test.dart';
import 'package:quran_tajweed_app/features/auth/domain/entities/app_user.dart';
import 'package:quran_tajweed_app/features/auth/domain/entities/mosque.dart';
import 'package:quran_tajweed_app/features/auth/domain/entities/user_role.dart';
import 'package:quran_tajweed_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:quran_tajweed_app/features/auth/presentation/state/auth_cubit.dart';
import 'package:quran_tajweed_app/features/auth/presentation/state/auth_state.dart';
import 'package:quran_tajweed_app/features/auth/presentation/state/mosques_cubit.dart';

const _student = AppUser(
  uid: 'uid-1',
  name: 'طالب',
  email: 'student@example.com',
  role: UserRole.student,
  isActive: true,
  mosqueId: 'mosque-1',
  squareId: 'square-1',
  regionId: 'region-1',
);

class _FakeAuthRepository implements AuthRepository {
  AuthFailure? failure;
  List<Mosque> mosques = const [];
  Map<String, String>? lastRegistration;
  AppUser? savedSession;

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    if (failure case final failure?) throw failure;
    return _student;
  }

  @override
  Future<AppUser> registerStudent({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String mosqueId,
  }) async {
    if (failure case final failure?) throw failure;
    lastRegistration = {
      'name': name,
      'email': email,
      'phone': phone,
      'mosqueId': mosqueId,
    };
    return _student;
  }

  @override
  Future<List<Mosque>> fetchActiveMosques() async {
    if (failure case final failure?) throw failure;
    return mosques;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    if (failure case final failure?) throw failure;
  }

  @override
  Future<AppUser?> restoreSession() async {
    if (failure case final failure?) throw failure;
    return savedSession;
  }

  @override
  Future<void> signOut() async {}
}

void main() {
  late _FakeAuthRepository repository;

  setUp(() => repository = _FakeAuthRepository());

  group('AuthCubit', () {
    test('signIn emits loading then authenticated', () async {
      final cubit = AuthCubit(repository);
      final states = <AuthState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.signIn(email: 'student@example.com', password: '123456');
      await pumpEventQueue();
      await subscription.cancel();

      expect(states, hasLength(2));
      expect(states[0], isA<AuthLoading>());
      expect((states[1] as AuthAuthenticated).user.uid, 'uid-1');
    });

    test(
      'signIn emits the failure message, e.g. a suspended account',
      () async {
        repository.failure = const AuthFailure('هذا الحساب موقوف.');
        final cubit = AuthCubit(repository);

        await cubit.signIn(email: 'student@example.com', password: '123456');

        expect((cubit.state as AuthError).message, 'هذا الحساب موقوف.');
      },
    );

    test('registerStudent trims input and marks the account as new', () async {
      final cubit = AuthCubit(repository);

      await cubit.registerStudent(
        name: ' طالب جديد ',
        email: ' new@example.com ',
        phone: ' 0599123456 ',
        password: '123456',
        mosqueId: 'mosque-1',
      );

      expect((cubit.state as AuthAuthenticated).isNewAccount, isTrue);
      expect(repository.lastRegistration, {
        'name': 'طالب جديد',
        'email': 'new@example.com',
        'phone': '0599123456',
        'mosqueId': 'mosque-1',
      });
    });

    test('sendPasswordResetEmail emits reset sent', () async {
      final cubit = AuthCubit(repository);

      await cubit.sendPasswordResetEmail(' student@example.com ');

      expect(
        (cubit.state as AuthPasswordResetSent).email,
        'student@example.com',
      );
    });
  });

  group('AuthCubit session', () {
    test('restoreSession emits authenticated for a saved session', () async {
      repository.savedSession = _student;
      final cubit = AuthCubit(repository);

      await cubit.restoreSession();

      expect((cubit.state as AuthAuthenticated).user.uid, 'uid-1');
    });

    test('restoreSession emits unauthenticated without a session', () async {
      final cubit = AuthCubit(repository);

      await cubit.restoreSession();

      expect(cubit.state, isA<AuthUnauthenticated>());
    });

    test('restoreSession emits an error for a suspended account', () async {
      repository.failure = const AuthFailure('هذا الحساب موقوف.');
      final cubit = AuthCubit(repository);

      await cubit.restoreSession();

      expect((cubit.state as AuthError).message, 'هذا الحساب موقوف.');
    });

    test('signOut emits unauthenticated', () async {
      final cubit = AuthCubit(repository);
      await cubit.signIn(email: 'student@example.com', password: '123456');

      await cubit.signOut();

      expect(cubit.state, isA<AuthUnauthenticated>());
    });
  });

  group('MosquesCubit', () {
    test('load emits the active mosques', () async {
      repository.mosques = const [
        Mosque(
          id: 'mosque-1',
          name: 'مسجد',
          squareId: 'square-1',
          regionId: 'region-1',
        ),
      ];
      final cubit = MosquesCubit(repository);

      await cubit.load();

      expect((cubit.state as MosquesLoaded).mosques.single.id, 'mosque-1');
    });

    test('load emits an error when reading fails', () async {
      repository.failure = const AuthFailure('تعذّر الاتصال.');
      final cubit = MosquesCubit(repository);

      await cubit.load();

      expect((cubit.state as MosquesError).message, 'تعذّر الاتصال.');
    });
  });

  group('entities', () {
    test('AppUser.fromMap rejects a document without a valid role', () {
      expect(AppUser.fromMap('uid-1', {'role': 'teacher'}), isNull);
      expect(
        AppUser.fromMap('uid-1', {
          'role': 'student',
          'isActive': false,
        })!.isActive,
        isFalse,
      );
    });

    test('Mosque.fromMap requires a square and a region', () {
      expect(Mosque.fromMap('m', {'name': 'مسجد', 'squareId': 's'}), isNull);
      expect(
        Mosque.fromMap('m', {'name': 'مسجد', 'squareId': 's', 'regionId': 'r'}),
        isNotNull,
      );
    });
  });
}
