import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BoardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  /// 특정 `author_id`가 작성한 모든 게시글 가져오기
  Future<List<BoardModel>> getBoardsByAuthorId(String authorId) async {
    try {
      final querySnapshot = await _firestore
          .collection('boards')
          .where('author_id', isEqualTo: authorId)
          .where('is_deleted', isEqualTo: false)
          .orderBy('created_at', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => BoardModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('게시글을 불러오는 중 오류 발생: $e');
    }
  }
}

class BoardModel {
  final String id;
  final String title;
  final String content;
  final String author;
  final String authorUid;
  final String category;
  final int likes;
  final int views;
  final DateTime createdAt;

  BoardModel({
    required this.id,
    required this.title,
    required this.content,
    required this.author,
    required this.authorUid,
    required this.category,
    required this.likes,
    required this.views,
    required this.createdAt,
  });

  /// Firestore 데이터에서 BoardModel 객체로 변환하는 factory 메서드
  factory BoardModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return BoardModel(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      author: data['author'] ?? '',
      authorUid: data['author_id'] ?? '',
      category: data['category'] ?? '',
      likes: data['like_count'] ?? 0,
      views: data['views'] ?? 0,
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
