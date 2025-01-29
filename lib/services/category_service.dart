import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

class CategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger();

  Future<DocumentSnapshot?> getCategoryByName(String categoryName) async {
    try {
      final querySnapshot = await _firestore
          .collection('categories')
          .where('cate_name', isEqualTo: categoryName)
          .where('what_for', isEqualTo: 'main')
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        _logger.w('Category not found: $categoryName');
        return null;
      }

      return querySnapshot.docs.first;
    } catch (e) {
      _logger.e('Error getting category: $e');
      return null;
    }
  }
}
