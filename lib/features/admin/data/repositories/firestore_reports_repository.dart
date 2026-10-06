import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firebase_collections.dart';
import '../../../../core/utils/app_failure.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../exams/domain/entities/exam.dart';
import '../../../exams/domain/entities/exam_status.dart';
import '../../../exams/domain/repositories/evaluations_repository.dart';
import '../../domain/entities/exam_report.dart';
import '../../domain/repositories/reports_repository.dart';
import '../../domain/services/report_builder.dart';

/// Builds the report on the device from the documents of the scope. It reads
/// every examination of the scope and one evaluation per approved
/// examination, which suits the size of Phase 1.
class FirestoreReportsRepository implements ReportsRepository {
  FirestoreReportsRepository({
    required this._evaluations,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final EvaluationsRepository _evaluations;
  final FirebaseFirestore _firestore;

  static DateTime? _toDate(Object? value) =>
      value is Timestamp ? value.toDate() : null;

  /// The documents of [collection] inside [scope]. The security rules
  /// require a supervisor's queries to filter on the square, and an
  /// officer's on the region.
  Query<Map<String, dynamic>> _scoped(String collection, ReportScope scope) {
    final query = _firestore.collection(collection);
    if (scope.squareId case final squareId?) {
      return query.where('squareId', isEqualTo: squareId);
    }
    if (scope.regionId case final regionId?) {
      return query.where('regionId', isEqualTo: regionId);
    }
    return query;
  }

  Future<Map<String, String>> _names(Query<Map<String, dynamic>> query) async {
    final snapshot = await query.get();
    return {
      for (final doc in snapshot.docs)
        doc.id: doc.data()['name'] as String? ?? '',
    };
  }

  /// The name of the square or the region of [scope], or empty when the
  /// scope is the whole system or the name cannot be read. The report is
  /// still shown without it.
  Future<String> _scopeName(ReportScope scope) async {
    final (collection, id) = switch (scope) {
      ReportScope(:final squareId?) => (FirebaseCollections.squares, squareId),
      ReportScope(:final regionId?) => (FirebaseCollections.regions, regionId),
      _ => (null, null),
    };
    if (collection == null || id == null) return '';
    try {
      final doc = await _firestore.collection(collection).doc(id).get();
      return doc.data()?['name'] as String? ?? '';
    } on FirebaseException {
      return '';
    }
  }

  @override
  Future<ExamReport> fetchReport(ReportScope scope) async {
    try {
      final examsSnapshot = await _scoped(
        FirebaseCollections.exams,
        scope,
      ).get();
      final exams = [
        for (final doc in examsSnapshot.docs)
          ?Exam.fromMap(doc.id, doc.data(), toDate: _toDate),
      ];
      final evaluations = await _evaluations.fetchEvaluations([
        for (final exam in exams)
          if (exam.status == ExamStatus.approved) exam.id,
      ]);
      final studentNames = await _names(
        _scoped(
          FirebaseCollections.users,
          scope,
        ).where('role', isEqualTo: UserRole.student.value),
      );
      final courseNames = await _names(
        _firestore.collection(FirebaseCollections.courses),
      );

      // A square has no smaller unit; a region is split by square, and the
      // system by region. Examinations are grouped by the scope they were
      // started in.
      final (unitNames, unitOf, unitTitle) = switch (scope) {
        ReportScope(squareId: _?) => (const <String, String>{}, null, ''),
        ReportScope(:final regionId?) => (
          await _names(
            _firestore
                .collection(FirebaseCollections.squares)
                .where('regionId', isEqualTo: regionId),
          ),
          (Exam exam) => exam.squareId,
          'حسب المربع',
        ),
        _ => (
          await _names(_firestore.collection(FirebaseCollections.regions)),
          (Exam exam) => exam.regionId,
          'حسب المنطقة',
        ),
      };

      return ReportBuilder.build(
        exams: exams,
        evaluations: evaluations,
        students: studentNames.length,
        studentNames: studentNames,
        courseNames: courseNames,
        unitNames: unitNames,
        unitOf: unitOf,
        unitTitle: unitTitle,
        scopeName: await _scopeName(scope),
      );
    } on FirebaseException catch (e) {
      throw AppFailure.fromFirebase(e);
    }
  }
}
