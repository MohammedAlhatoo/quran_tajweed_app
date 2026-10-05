// Seeds the curriculum into Firestore with administrative credentials.
//
//   dart run tool/seed_curriculum.dart --project ai-quran-exam --dry-run
//   dart run tool/seed_curriculum.dart --project ai-quran-exam --apply
//
// The credentials are the Application Default Credentials of the machine:
// either `gcloud auth application-default login`, or the path of a
// service-account key in GOOGLE_APPLICATION_CREDENTIALS. The key is kept
// outside the project and is never committed.
//
// When FIRESTORE_EMULATOR_HOST is set, the tool talks to the emulator instead
// and needs no credentials.
import 'dart:io';

import 'package:args/args.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:quran_tajweed_app/features/courses/data/seed/curriculum_seeder.dart';

import 'src/admin_seed_store.dart';
import 'src/seed_plan.dart';

Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption('project', help: 'The Firebase project ID.')
    ..addFlag(
      'dry-run',
      negatable: false,
      help: 'Read Firestore and report what would be written. Writes nothing.',
    )
    ..addFlag(
      'apply',
      negatable: false,
      help: 'Write the curriculum. Never deletes.',
    );

  final ArgResults options;
  try {
    options = parser.parse(arguments);
  } on FormatException catch (error) {
    _fail('${error.message}\n\n${parser.usage}');
  }
  final project = options.option('project');
  final dryRun = options.flag('dry-run');
  final apply = options.flag('apply');
  if (project == null || project.isEmpty || dryRun == apply) {
    _fail(
      'Give --project and exactly one of --dry-run or --apply.\n\n'
      '${parser.usage}',
    );
  }

  final emulator = Platform.environment['FIRESTORE_EMULATOR_HOST'];
  final http.Client client;
  if (emulator != null && emulator.isNotEmpty) {
    client = _EmulatorClient();
  } else {
    try {
      client = await clientViaApplicationDefaultCredentials(
        scopes: [AdminSeedStore.scope],
      );
    } on Object catch (error) {
      _fail(
        'No administrative credentials were found: $error\n\n'
        'Run `gcloud auth application-default login` with an account that '
        'may write to Firestore in $project, or set '
        'GOOGLE_APPLICATION_CREDENTIALS to the path of a service-account '
        'key kept outside the project.',
      );
    }
  }

  stdout.writeln(
    '${apply ? 'APPLY' : 'DRY RUN'}: project $project'
    '${emulator == null || emulator.isEmpty ? '' : ' (emulator $emulator)'}',
  );
  try {
    final store = RecordingSeedStore(
      emulator == null || emulator.isEmpty
          ? AdminSeedStore(client, project)
          : AdminSeedStore(client, project, rootUrl: 'http://$emulator/'),
      apply: apply,
    );
    final result = await CurriculumSeeder(store).seed();
    stdout
      ..writeln()
      ..write(describeSeedPlan(buildSeedPlan(store, result), apply: apply))
      ..writeln()
      ..writeln(
        apply
            ? 'Done. Nothing was deleted.'
            : 'Dry run: nothing was written to Firestore.',
      );
  } on FirestoreRequestException catch (error) {
    stderr.writeln('Firestore refused the request. $error');
    if (apply) {
      stderr.writeln(
        'Some collections may already be written. The seed is idempotent: '
        'run it again once the cause is fixed.',
      );
    }
    exitCode = 1;
  } finally {
    client.close();
  }
}

Never _fail(String message) {
  stderr.writeln(message);
  exit(64);
}

/// The emulator treats the `owner` token as an administrator.
class _EmulatorClient extends http.BaseClient {
  final http.Client _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer owner';
    return _inner.send(request);
  }

  @override
  void close() => _inner.close();
}
