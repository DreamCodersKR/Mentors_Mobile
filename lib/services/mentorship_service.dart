import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

class MentorshipService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger();

  Future<String?> createMentorship({
    required String userId,
    required String position,
    required String categoryId,
    required String categoryName,
    required List<Map<String, dynamic>> questions,
    required List<String> answers,
  }) async {
    try {
      final mentorshipData = {
        'userId': userId,
        'position': position,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'questions': questions,
        'answers': answers,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'isDeleted': false,
      };

      final docRef =
          await _firestore.collection('mentorships').add(mentorshipData);
      _logger.i('Mentorship created with ID: ${docRef.id}');

      // 만약 멘티라면 매칭 로직 실행
      if (position == 'mentee') {
        // TODO: 매칭 로직 구현
        // 1. 같은 카테고리의 멘토 리스트 조회
        // 2. 답변 유사도 계산
        // 3. 매칭 결과 저장
      }

      return docRef.id;
    } catch (e) {
      _logger.e('Error creating mentorship: $e');
      return null;
    }
  }

  // TODO: 추가 필요한 메서드들
  // 1. 유사도 계산 메서드
  // 2. 매칭 결과 저장 메서드
  // 3. 매칭 상태 업데이트 메서드
}
