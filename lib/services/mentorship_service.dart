import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:mentors_app/services/matching_client_service.dart';

class MentorshipService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Logger _logger = Logger();
  final MatchingClientService _matchingClientService = MatchingClientService();

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
        await _processMatchingForMentee(
          menteeRequestId: docRef.id,
          categoryId: categoryId,
          answers: answers,
        );
      }

      return docRef.id;
    } catch (e) {
      _logger.e('Error creating mentorship: $e');
      return null;
    }
  }

  Future<void> _processMatchingForMentee({
    required String menteeRequestId,
    required String categoryId,
    required List<String> answers,
  }) async {
    try {
      // 답변 텍스트만 추출
      final answerTexts = answers;

      // 매칭 서버와 통신
      final matchResult = await _matchingClientService.requestMatch(
        menteeId: menteeRequestId,
        categoryId: categoryId,
        answers: answerTexts,
      );

      // 매칭 결과가 있는 경우
      if (matchResult != null) {
        // 사용자 본인과의 매칭 방지
        if (matchResult['mentor_id'] != menteeRequestId) {
          await _saveMatchResult(
            menteeRequestId: menteeRequestId,
            categoryId: categoryId,
            matchResult: matchResult,
          );
        } else {
          // 자신과의 매칭인 경우 매칭 실패 처리
          await _updateMentorshipStatus(
            mentorshipId: menteeRequestId,
            status: 'failed',
          );
        }
      } else {
        // 매칭 실패 처리
        await _updateMentorshipStatus(
          mentorshipId: menteeRequestId,
          status: 'failed',
        );
      }
    } catch (e) {
      _logger.e('Matching process error: $e');
      // 매칭 중 오류 발생 시 상태 업데이트
      await _updateMentorshipStatus(
        mentorshipId: menteeRequestId,
        status: 'matching_error',
      );
    }
  }

  Future<void> _saveMatchResult({
    required String menteeRequestId,
    required String categoryId,
    required Map<String, dynamic> matchResult,
  }) async {
    try {
      // 멘토 요청 ID 조회
      final mentorRequestSnapshot = await _firestore
          .collection('mentorships')
          .where('userId', isEqualTo: matchResult['mentor_id'])
          .where('categoryId', isEqualTo: matchResult['category_id'])
          .where('position', isEqualTo: 'mentor')
          .where('isDeleted', isEqualTo: false)
          .limit(1)
          .get();

      if (mentorRequestSnapshot.docs.isEmpty) {
        throw Exception('멘토 요청을 찾을 수 없습니다.');
      }

      final mentorRequestId = mentorRequestSnapshot.docs.first.id;

      // matches 컬렉션에 매칭 결과 저장
      await _firestore.collection('matches').add({
        'menteeRequestId': menteeRequestId,
        'mentorRequestId': mentorRequestId,
        'categoryId': matchResult['category_id'],
        'similarityScore': matchResult['similarity_score'],
        'status': 'success',
        'createdAt': FieldValue.serverTimestamp(),
        'isDeleted': false,
      });

      // 멘토십 상태 업데이트
      await Future.wait([
        _updateMentorshipStatus(
          mentorshipId: menteeRequestId,
          status: 'matched',
        ),
        _updateMentorshipStatus(
          mentorshipId: mentorRequestId,
          status: 'matched',
        ),
      ]);
    } catch (e) {
      _logger.e('Error saving match result: $e');
      // 매칭 결과 저장 실패 시 상태 업데이트
      await _updateMentorshipStatus(
        mentorshipId: menteeRequestId,
        status: 'failed',
      );
    }
  }

  Future<void> _updateMentorshipStatus({
    required String mentorshipId,
    required String status,
  }) async {
    try {
      await _firestore.collection('mentorships').doc(mentorshipId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _logger.e('Error updating mentorship status: $e');
    }
  }

  // 사용자의 현재 멘토십 상태 조회
  Future<List<Map<String, dynamic>>> getUserMentorships(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('mentorships')
          .where('userId', isEqualTo: userId)
          .where('isDeleted', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      _logger.e('Error fetching user mentorships: $e');
      return [];
    }
  }

  // 사용자의 매칭 기록 조회
  Future<List<Map<String, dynamic>>> getUserMatches(String userId) async {
    try {
      // 멘티로서의 매칭 기록
      final menteeMatchesQuery = await _firestore
          .collection('matches')
          .where('menteeRequestId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      // 멘토로서의 매칭 기록
      final mentorMatchesQuery = await _firestore
          .collection('matches')
          .where('mentorRequestId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      final menteeMatches = menteeMatchesQuery.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        data['role'] = 'mentee';
        return data;
      }).toList();

      final mentorMatches = mentorMatchesQuery.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        data['role'] = 'mentor';
        return data;
      }).toList();

      return [...menteeMatches, ...mentorMatches];
    } catch (e) {
      _logger.e('Error fetching user matches: $e');
      return [];
    }
  }
}
