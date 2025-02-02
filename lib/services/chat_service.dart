import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger();

  // 채팅방 생성
  Future<String?> createChatRoom({
    required String matchesId,
    required String mentorId,
    required String menteeId,
  }) async {
    try {
      // 이미 존재하는 채팅방 확인
      final existingChat = await _firestore
          .collection('chats')
          .where('matches_id', isEqualTo: matchesId)
          .where('is_deleted', isEqualTo: false)
          .get();

      if (existingChat.docs.isNotEmpty) {
        _logger.i('이미 존재하는 채팅방: ${existingChat.docs.first.id}');
        return existingChat.docs.first.id;
      }

      // 새로운 채팅방 생성
      final chatRef = await _firestore.collection('chats').add({
        'participants': [mentorId, menteeId],
        'matches_id': matchesId,
        'mentor_id': mentorId,
        'mentee_id': menteeId,
        'last_message': '채팅이 시작되었습니다.',
        'last_message_time': FieldValue.serverTimestamp(),
        'created_at': FieldValue.serverTimestamp(),
        'is_deleted': false,
      });

      // 첫 메시지 자동 생성
      await chatRef.collection('messages').add({
        'sender_id': mentorId, // 시스템 메시지로 처리
        'content': '채팅이 시작되었습니다.',
        'timestamp': FieldValue.serverTimestamp(),
        'is_read': false,
        'is_deleted': false,
      });

      _logger.i('새로운 채팅방 생성: ${chatRef.id}');
      return chatRef.id;
    } catch (e) {
      _logger.e('채팅방 생성 중 오류: $e');
      return null;
    }
  }

  // 메시지 전송
  Future<void> sendMessage({
    required String chatId,
    required String content,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _logger.w('로그인된 사용자가 없습니다.');
        return;
      }

      // messages 서브컬렉션에 메시지 추가
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'sender_id': user.uid,
        'content': content,
        'timestamp': FieldValue.serverTimestamp(),
        'is_read': false,
        'is_deleted': false,
      });

      // 채팅방의 마지막 메시지 정보 업데이트
      await _firestore.collection('chats').doc(chatId).update({
        'last_message': content,
        'last_message_time': FieldValue.serverTimestamp(),
      });

      _logger.i('메시지 전송 완료');
    } catch (e) {
      _logger.e('메시지 전송 중 오류: $e');
      rethrow;
    }
  }

  // 메시지 읽음 처리
  Future<void> markMessageAsRead(String chatId, String messageId) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({'is_read': true});
    } catch (e) {
      _logger.e('메시지 읽음 처리 중 오류: $e');
    }
  }

  // 사용자의 채팅방 목록 조회
  Stream<QuerySnapshot> getUserChatRooms() {
    final user = _auth.currentUser;
    if (user == null) {
      _logger.w('로그인된 사용자가 없습니다.');
      return const Stream.empty();
    }

    return _firestore
        .collection('chats')
        .where('participants', arrayContains: user.uid)
        .where('is_deleted', isEqualTo: false)
        .orderBy('last_message_time', descending: true)
        .snapshots();
  }

  // 특정 채팅방의 메시지 스트림
  Stream<QuerySnapshot> getChatMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('is_deleted', isEqualTo: false)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // 채팅방 삭제 (실제 삭제가 아닌 is_deleted 플래그 설정)
  Future<void> deleteChatRoom(String chatId) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .update({'is_deleted': true});
      _logger.i('채팅방 삭제 완료');
    } catch (e) {
      _logger.e('채팅방 삭제 중 오류: $e');
      rethrow;
    }
  }

  // 채팅방 정보 조회
  Future<DocumentSnapshot?> getChatRoom(String chatId) async {
    try {
      return await _firestore.collection('chats').doc(chatId).get();
    } catch (e) {
      _logger.e('채팅방 정보 조회 중 오류: $e');
      return null;
    }
  }
}
