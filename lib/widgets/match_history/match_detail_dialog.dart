import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:mentors_app/main.dart';

class MatchDetailDialog extends StatelessWidget {
  final Map<String, dynamic> mentorship;
  final Logger _logger = Logger();

  MatchDetailDialog({
    super.key,
    required this.mentorship,
  });

  Future<void> _startChat(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _logger.w('사용자가 로그인되어 있지 않음');
      return;
    }

    try {
      _logger.d('채팅 시작 시도: mentorship 데이터 - ${mentorship.toString()}');

      // 멘토/멘티 포지션 확인
      final position = mentorship['position'];
      final mentorshipId = mentorship['id'];
      final categoryId = mentorship['category_id'];

      logger.i('멘토쉽 자체의 id : $mentorshipId');

      // matches 컬렉션에서 해당하는 match 문서 찾기
      final matchesQuery = await FirebaseFirestore.instance
          .collection('matches')
          .where('status', isEqualTo: 'success')
          .where('is_deleted', isEqualTo: false)
          .where('category_id', isEqualTo: categoryId)
          .where(position == 'mentor' ? 'mentorRequest_id' : 'menteeRequest_id',
              isEqualTo: mentorshipId)
          .get();

      _logger.d('matches 쿼리 결과: ${matchesQuery.docs.length}개의 문서 발견');

      if (matchesQuery.docs.isEmpty) {
        _logger.w('매칭 정보를 찾을 수 없음');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('매칭 정보를 찾을 수 없습니다.')),
          );
        }
        return;
      }

      final matchData = matchesQuery.docs.first.data();
      _logger.d('matchData: $matchData');
      final matchId = matchesQuery.docs.first.id;

      // 이미 존재하는 채팅방 확인
      final existingChatQuery = await FirebaseFirestore.instance
          .collection('chats')
          .where('matches_id', isEqualTo: matchId)
          .where('is_deleted', isEqualTo: false)
          .get();

      _logger.d('기존 채팅방 확인 결과: ${existingChatQuery.docs.length}개 발견');

      if (existingChatQuery.docs.isNotEmpty) {
        // 이미 채팅방이 존재하는 경우 해당 채팅방으로 이동
        if (context.mounted) {
          Navigator.pop(context); // 다이얼로그 닫기
          Navigator.pushNamed(
            context,
            '/chat_room',
            arguments: existingChatQuery.docs.first.id,
          );
        }
        return;
      }

      // 새로운 채팅방 생성
      final mentorId = matchData['mentor_id'];
      final menteeId = matchData['mentee_id'];
      _logger.d('채팅방 생성 시도: mentorId=$mentorId, menteeId=$menteeId');

      final chatRoom =
          await FirebaseFirestore.instance.collection('chats').add({
        'participants': [mentorId, menteeId],
        'matches_id': matchId,
        'mentor_id': mentorId,
        'mentee_id': menteeId,
        'last_message': '',
        'last_message_time': FieldValue.serverTimestamp(),
        'created_at': FieldValue.serverTimestamp(),
        'is_deleted': false,
      });

      if (context.mounted) {
        Navigator.pop(context); // 다이얼로그 닫기
        Navigator.pushNamed(
          context,
          '/chat_room',
          arguments: chatRoom.id,
        );
      }
    } catch (e, stackTrace) {
      _logger.e('채팅방 생성 중 오류 발생: $e');
      _logger.e('스택 트레이스: $stackTrace');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('채팅방을 생성하는 중 오류가 발생했습니다.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isMatched = mentorship['status'] == 'matched';

    return AlertDialog(
      title: Text('${mentorship['category_name']} 매칭 정보'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('닉네임: ${mentorship['user_nickname']}'),
            Text('역할: ${mentorship['position'] == 'mentor' ? '멘토' : '멘티'}'),
            Text(
              '상태: ${_getStatusText(mentorship['status'])}',
            ),
            Text('생성일: ${_formatTimestamp(mentorship['created_at'])}'),
            const Divider(),
            const Text(
              '답변 내용:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            ..._buildAnswersList(mentorship),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('닫기'),
        ),
        if (isMatched) // 매칭이 완료된 경우에만 채팅 시작 버튼 표시
          TextButton(
            onPressed: () => _startChat(context),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Theme.of(context).primaryColor,
            ),
            child: const Text('채팅 시작'),
          ),
      ],
    );
  }

  String _getStatusText(String? status) {
    switch (status) {
      case 'pending':
        return '대기중';
      case 'matched':
        return '매칭완료';
      case 'failed':
        return '매칭실패';
      default:
        return '알 수 없음';
    }
  }

  List<Widget> _buildAnswersList(Map<String, dynamic> mentorship) {
    final answers = mentorship['answers'] as List?;
    if (answers == null || answers.isEmpty) {
      return [const Text('답변 정보가 없습니다.')];
    }

    return answers.asMap().entries.map<Widget>((entry) {
      return Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Text('답변 ${entry.key + 1}: ${entry.value}'),
      );
    }).toList();
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '날짜 정보 없음';
    return timestamp.toDate().toString();
  }
}
