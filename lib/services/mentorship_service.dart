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
        'user_id': userId,
        'position': position,
        'category_id': categoryId,
        'category_name': categoryName,
        'questions': questions,
        'answers': answers,
        'status': 'pending',
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
        'is_deleted': false,
      };

      final docRef =
          await _firestore.collection('mentorships').add(mentorshipData);
      _logger.i('Mentorship created with ID: ${docRef.id}');

      // 만약 멘티라면 매칭 로직 실행
      if (position == 'mentee') {
        await _processMatchingForMentee(
          menteeRequestId: docRef.id,
          menteeId: userId,
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
    required String menteeId,
    required String categoryId,
    required List<String> answers,
  }) async {
    try {
      // 매칭 서버와 통신
      final matchResult = await _matchingClientService.requestMatch(
        menteeId: menteeId,
        menteeRequestId: menteeRequestId,
        categoryId: categoryId,
        answers: answers,
      );

      if (matchResult != null && matchResult.containsKey('match')) {
        final matchData = matchResult['match'] as Map<String, dynamic>;
        if (matchData['mentor_id'] != menteeId) {
          await _saveMatchResult(
            menteeRequestId: menteeRequestId,
            categoryId: categoryId,
            matchResult: matchResult,
          );
        } else {
          await _updateMentorshipStatus(
            mentorshipId: menteeRequestId,
            status: 'failed',
          );
        }
      } else {
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
      _logger.i('매칭 결과 데이터: $matchResult');

      final match = matchResult['match'] as Map<String, dynamic>;
      final similarityScore = match['similarity_score'] as double;

      // 멘토 요청 ID 조회
      final mentorRequestSnapshot = await _firestore
          .collection('mentorships')
          .where('user_id', isEqualTo: matchResult['mentor_id'])
          .where('category_id', isEqualTo: categoryId)
          .where('position', isEqualTo: 'mentor')
          .where('is_deleted', isEqualTo: false)
          .limit(1)
          .get();

      if (mentorRequestSnapshot.docs.isEmpty) {
        throw Exception('멘토 요청을 찾을 수 없습니다.');
      }

      final mentorRequestId = mentorRequestSnapshot.docs.first.id;
      final mentorDoc = mentorRequestSnapshot.docs.first;
      final mentorUserId = mentorDoc.data()['user_id'];

      // 멘티 정보 가져오기
      final menteeDoc =
          await _firestore.collection('mentorships').doc(menteeRequestId).get();
      final menteeUserId = menteeDoc.data()?['user_id'];

      // matches 컬렉션에 매칭 결과 저장
      final matchData = {
        'menteeRequest_id': menteeRequestId,
        'mentorRequest_id': mentorRequestId,
        'mentee_id': menteeUserId,
        'mentor_id': mentorUserId,
        'category_id': categoryId,
        'similarity_score': similarityScore,
        'status': 'success',
        'created_at': FieldValue.serverTimestamp(),
        'is_deleted': false,
      };
      _logger.i('저장할 매칭 데이터: $matchData');

      await _firestore.collection('matches').add(matchData);

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
        'updated_at': FieldValue.serverTimestamp(),
      });
      _logger.i('멘토십 상태 업데이트 완료: $mentorshipId -> $status');
    } catch (e) {
      _logger.e('Error updating mentorship status: $e');
      rethrow; // 에러를 다시 던져서 상위에서 처리할 수 있도록 함
    }
  }

  // 사용자의 현재 멘토십 상태 조회
  Future<List<Map<String, dynamic>>> getUserMentorships(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection('mentorships')
          .where('user_id', isEqualTo: userId)
          .where('is_deleted', isEqualTo: false)
          .orderBy('created_at', descending: true)
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
          .where('menteeRequest_id', isEqualTo: userId)
          .orderBy('created_at', descending: true)
          .get();

      // 멘토로서의 매칭 기록
      final mentorMatchesQuery = await _firestore
          .collection('matches')
          .where('mentorRequest_id', isEqualTo: userId)
          .orderBy('created_at', descending: true)
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

  Future<Map<String, dynamic>?> getMatchDetails(
      String mentorshipId, String userId) async {
    try {
      _logger.i('매칭 정보 조회 시작 - mentorshipId: $mentorshipId, userId: $userId');

      // 1. mentorship 문서 조회
      final mentorshipDoc =
          await _firestore.collection('mentorships').doc(mentorshipId).get();
      if (!mentorshipDoc.exists) {
        _logger.w('mentorship 문서가 존재하지 않음');
        return null;
      }

      final mentorshipData = mentorshipDoc.data()!;
      final position = mentorshipData['position'] as String?;
      _logger.i('현재 사용자 포지션: $position');

      // 2. matches 컬렉션에서 매칭 정보 검색
      QuerySnapshot matchQuery;
      if (position == 'mentor') {
        matchQuery = await _firestore
            .collection('matches')
            .where('mentorRequest_id', isEqualTo: mentorshipId)
            .where('mentor_id', isEqualTo: userId)
            .where('status', isEqualTo: 'success')
            .where('is_deleted', isEqualTo: false)
            .get();
      } else {
        matchQuery = await _firestore
            .collection('matches')
            .where('menteeRequest_id', isEqualTo: mentorshipId)
            .where('mentee_id', isEqualTo: userId)
            .where('status', isEqualTo: 'success')
            .where('is_deleted', isEqualTo: false)
            .get();
      }

      if (matchQuery.docs.isEmpty) {
        _logger.i('매칭 정보 없음, 기본 mentorship 데이터 반환');
        return mentorshipData;
      }

      // 3. 매칭된 상대방의 mentorship 정보 조회
      final matchData = matchQuery.docs.first.data() as Map<String, dynamic>;
      final oppositeRequestId = position == 'mentor'
          ? matchData['menteeRequest_id'] as String
          : matchData['mentorRequest_id'] as String;

      final oppositeMentorshipDoc = await _firestore
          .collection('mentorships')
          .doc(oppositeRequestId)
          .get();

      if (!oppositeMentorshipDoc.exists) {
        _logger.w('상대방 mentorship 문서가 존재하지 않음');
        return mentorshipData;
      }

      final oppositeMentorshipData = oppositeMentorshipDoc.data()!;

      // 4. 최종 데이터 구성
      final Map<String, dynamic> combinedData = {
        ...mentorshipData,
        'match_data': <String, dynamic>{
          ...matchData,
          'opposite_mentorship': oppositeMentorshipData
        }
      };

      _logger.i('매칭 정보 반환: $combinedData');
      return combinedData;
    } catch (e, stackTrace) {
      _logger.e('매칭 정보 조회 중 오류 발생: $e');
      _logger.e('스택 트레이스: $stackTrace');
      return null;
    }
  }
}
