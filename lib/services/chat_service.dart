import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger();

  // 현재 로그인된 사용자 ID 반환
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  // 새 채팅방 생성
  Future<String?> createChatRoom({
    required String matchesId,
    required String otherUserId,
  }) async {
    final currentUserId = getCurrentUserId();

    if (currentUserId == null) {
      _logger.e('사용자가 로그인되어 있지 않습니다.');
      return null;
    }

    try {
      // 채팅방 문서 생성
      final chatRef = await _firestore.collection('chats').add({
        'participants': [currentUserId, otherUserId],
        'matches_id': matchesId,
        'last_message': '',
        'last_message_time': FieldValue.serverTimestamp(),
        'created_at': FieldValue.serverTimestamp(),
      });

      return chatRef.id;
    } catch (e) {
      _logger.e('채팅방 생성 중 오류 발생: $e');
      return null;
    }
  }

  // 특정 매칭 ID로 채팅방 찾기
  Future<String?> findChatRoomByMatchesId(String matchesId) async {
    final currentUserId = getCurrentUserId();

    if (currentUserId == null) {
      _logger.e('사용자가 로그인되어 있지 않습니다.');
      return null;
    }

    try {
      final querySnapshot = await _firestore
          .collection('chats')
          .where('matches_id', isEqualTo: matchesId)
          .where('participants', arrayContains: currentUserId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.id;
      }
      return null;
    } catch (e) {
      _logger.e('채팅방 찾기 중 오류 발생: $e');
      return null;
    }
  }

  // 메시지 전송
  Future<void> sendMessage({
    required String chatId,
    required String content,
  }) async {
    final currentUserId = getCurrentUserId();

    if (currentUserId == null) {
      _logger.e('사용자가 로그인되어 있지 않습니다.');
      return;
    }

    try {
      // 메시지 하위 컬렉션에 메시지 추가
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'sender_id': currentUserId,
        'content': content,
        'timestamp': FieldValue.serverTimestamp(),
        'is_read': false,
      });

      // 채팅방의 마지막 메시지 업데이트
      await _firestore.collection('chats').doc(chatId).update({
        'last_message': content,
        'last_message_time': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      _logger.e('메시지 전송 중 오류 발생: $e');
    }
  }

  // 특정 채팅방의 메시지 스트림 가져오기
  Stream<QuerySnapshot> getMessagesStream(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  // 사용자의 채팅 목록 가져오기
  Stream<QuerySnapshot> getUserChatsStream() {
    final currentUserId = getCurrentUserId();

    if (currentUserId == null) {
      _logger.e('사용자가 로그인되어 있지 않습니다.');
      return const Stream.empty();
    }

    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .orderBy('last_message_time', descending: true)
        .snapshots();
  }

  // 메시지 읽음 상태 업데이트
  Future<void> markMessageAsRead(String chatId, String messageId) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({'is_read': true});
    } catch (e) {
      _logger.e('메시지 읽음 상태 업데이트 중 오류 발생: $e');
    }
  }

  // 특정 멘토십 ID로 채팅방 찾기
  Future<String?> findChatRoomByMentorshipId(String mentorshipId) async {
    final currentUserId = getCurrentUserId();

    if (currentUserId == null) {
      _logger.e('사용자가 로그인되어 있지 않습니다.');
      return null;
    }

    try {
      final querySnapshot = await _firestore
          .collection('chats')
          .where('mentorship_id', isEqualTo: mentorshipId)
          .where('participants', arrayContains: currentUserId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.id;
      }
      return null;
    } catch (e) {
      _logger.e('채팅방 찾기 중 오류 발생: $e');
      return null;
    }
  }
}
