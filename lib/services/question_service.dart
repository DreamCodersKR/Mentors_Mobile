import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

class QuestionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger();

  Future<List<Map<String, dynamic>>> getQuestions({
    required String categoryId,
    required String position,
  }) async {
    try {
      final questionSnapshot = await _firestore
          .collection('categories')
          .doc(categoryId)
          .collection('questions')
          .where('position', isEqualTo: position)
          .get();

      if (questionSnapshot.docs.isEmpty) {
        _logger.w(
            'No questions found for category: $categoryId, position: $position');
        return [];
      }

      final questions =
          questionSnapshot.docs.first.data()['questionnaire'] as List;
      return List<Map<String, dynamic>>.from(questions);
    } catch (e) {
      _logger.e('Error getting questions: $e');
      return [];
    }
  }
}
