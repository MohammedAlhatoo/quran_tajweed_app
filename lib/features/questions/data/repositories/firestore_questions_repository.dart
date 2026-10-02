import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/constants/firebase_collections.dart';
import '../../../../core/utils/app_failure.dart';
import '../../domain/entities/exam_question.dart';
import '../../domain/repositories/questions_repository.dart';

/// Reads the questions saved for an examination in `exam_questions`. It never
/// reads `question_answers`.
class FirestoreQuestionsRepository implements QuestionsRepository {
  FirestoreQuestionsRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  @override
  Future<List<ExamQuestion>> fetchExamQuestions({
    required String examId,
    required String studentId,
  }) async {
    try {
      // The security rules allow a student to read only their own records,
      // so the query must filter on studentId.
      final snapshot = await _firestore
          .collection(FirebaseCollections.examQuestions)
          .where('studentId', isEqualTo: studentId)
          .where('examId', isEqualTo: examId)
          .get();
      final questions = [
        for (final doc in snapshot.docs)
          ?ExamQuestion.fromMap(doc.id, doc.data()),
      ];
      // Sorted here to avoid requiring a composite index.
      questions.sort((a, b) => a.order.compareTo(b.order));
      return questions;
    } on FirebaseException catch (e) {
      throw AppFailure.fromFirebase(e);
    }
  }
}
