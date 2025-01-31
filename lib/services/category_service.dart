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

  Future<List<String>> getBoardCategories() async {
    try {
      final querySnapshot = await _firestore
          .collection('categories')
          .where('what_for', isEqualTo: 'board')
          .get();

      // 카테고리 이름들을 리스트로 추출
      final categories = querySnapshot.docs
          .map((doc) => (doc.data()['cate_name'] ?? '') as String)
          .where((category) => category.isNotEmpty)
          .toList();

      // 기본 카테고리 "말머리 선택" 추가
      categories.insert(0, "말머리 선택");

      return categories;
    } catch (e) {
      _logger.e('게시판 카테고리 조회 실패: $e');
      // 실패 시 기본 카테고리 반환
      return [
        "말머리 선택",
        "IT/전문기술",
        "예술",
        "학업/교육",
        "마케팅",
        "자기개발",
        "취업&커리어",
        "금융/경제",
        "기타"
      ];
    }
  }
}
