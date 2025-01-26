import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:mentors_app/screens/board_detail_screen.dart';

final Logger logger = Logger();

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '알림',
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: const Color(0xFFE2D4FF),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            onPressed: () => _deleteAllNotifications(),
            icon: const Icon(Icons.delete, color: Colors.black),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('user_id', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
            .where('is_deleted', isEqualTo: false)
            .orderBy('created_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
              child: Text('오류가 발생했습니다. 다시 시도해주세요.'),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                '알림이 없습니다.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            );
          }
          final notifications = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.all(16.0),
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final notification = notifications[index];
              final data = notification.data() as Map<String, dynamic>;
              final isRead = data['is_read'] ?? false;
              final content = data['content'] ?? '알림 내용 없음';
              final createdAt = (data['created_at'] as Timestamp?)?.toDate();
              final formattedDate = createdAt != null
                  ? DateFormat('yyyy.MM.dd HH:mm:ss').format(createdAt)
                  : '알 수 없음';
              final action = data['action'] as Map<String, dynamic>?;

              if (action == null ||
                  action['screen'] == null ||
                  action['params'] == null) {
                return ListTile(
                  leading: const Icon(Icons.mail, color: Colors.grey),
                  title: const Text('잘못된 알림 데이터'),
                  subtitle: Text(
                    formattedDate,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteNotification(notification.id),
                  ),
                );
              }

              final params = action['params'] as Map<String, dynamic>;
              final boardId = params['board_id'];

              return ListTile(
                leading: const Icon(Icons.mail, color: Colors.grey),
                title: Text(
                  content,
                  style: TextStyle(
                    fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  formattedDate,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteNotification(notification.id),
                ),
                onTap: () async {
                  await _handleNotificationTap(boardId, context);
                  await notification.reference.update({'is_read': true});
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _handleNotificationTap(
      String boardId, BuildContext context) async {
    if (boardId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('게시글 ID가 없습니다.')),
      );
      return;
    }

    try {
      final boardSnapshot = await FirebaseFirestore.instance
          .collection('boards')
          .doc(boardId)
          .get();
      if (!boardSnapshot.exists ||
          (boardSnapshot.data()?['is_deleted'] ?? false)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('해당 게시글은 삭제되었습니다.')),
        );
        return;
      }

      if (boardSnapshot.exists) {
        final boardData = boardSnapshot.data() as Map<String, dynamic>;
        final authorId = boardData['author_id'] ?? '';

        String authorNickname = '익명';

        if (authorId.isNotEmpty) {
          final authorSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(authorId)
              .get();

          if (authorSnapshot.exists) {
            final authorData = authorSnapshot.data() as Map<String, dynamic>;
            authorNickname = authorData['user_nickname'] ?? '익명';
          }
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BoardDetailScreen(
              boardId: boardId,
              title: boardData['title'] ?? '제목 없음',
              content: boardData['content'] ?? '내용 없음',
              author: authorNickname,
              authorUid: authorId,
              category: boardData['category'] ?? '카테고리 없음',
              likes: boardData['likes'] ?? 0,
              views: boardData['views'] ?? 0,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('게시글 데이터를 찾을 수 없습니다.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류 발생: $e')),
      );
    }
  }

  Future<void> _deleteAllNotifications() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final notificationQuery = FirebaseFirestore.instance
        .collection('notifications')
        .where('user_id', isEqualTo: userId)
        .where('is_deleted', isEqualTo: false);
    final snapshot = await notificationQuery.get();

    for (var doc in snapshot.docs) {
      await doc.reference.update({'is_deleted': true});
    }
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(notificationId)
          .update({'is_deleted': true});
    } catch (e) {
      logger.e('알림 삭제 실패 : $e');
    }
  }
}
