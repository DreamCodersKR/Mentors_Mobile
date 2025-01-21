import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mentors_app/screens/board_detail_screen.dart';
import 'package:mentors_app/widgets/banner_ad.dart';

class RecentViewsScreen extends StatelessWidget {
  const RecentViewsScreen({super.key});

  Future<void> _incrementViews(String boardId) async {
    try {
      await FirebaseFirestore.instance
          .collection('boards')
          .doc(boardId)
          .update({
        'views': FieldValue.increment(1),
      });
    } catch (e) {
      print('조회수 증가 실패: $e');
    }
  }

  void _navigateToDetail(
    BuildContext context, {
    required String boardId,
    required String title,
    required String content,
    required String author,
    required String authorUid,
    required String category,
    required int likes,
    required int views,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BoardDetailScreen(
          boardId: boardId,
          title: title,
          content: content,
          author: author,
          authorUid: authorUid,
          category: category,
          likes: likes,
          views: views,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(
        child: Text("로그인이 필요합니다."),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "최근 본 게시글",
          style: TextStyle(color: Colors.black),
        ),
        backgroundColor: const Color(0xFFE2D4FF),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('recent_views')
                  .orderBy('viewed_at', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return const Center(
                    child: Text("오류가 발생했습니다. 다시 시도해주세요."),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text("최근 본 게시글이 없습니다."),
                  );
                }

                final recentViews = snapshot.data!.docs;

                return ListView.separated(
                  itemCount: recentViews.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final data =
                        recentViews[index].data() as Map<String, dynamic>;
                    final title = data['title'] ?? '제목 없음';
                    final category = data['category'] ?? '카테고리 없음';
                    final content = data['content'] ?? '내용 없음';
                    final authorNickname = data['author'] ?? '익명';
                    final authorId = data['author_id'];
                    final likes = data['likes'];
                    final views = data['views'];
                    final boardId = data['board_id'];

                    return ListTile(
                      title: Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(category),
                      onTap: () async {
                        await _incrementViews(boardId);

                        _navigateToDetail(
                          context,
                          boardId: boardId,
                          title: title,
                          content: content,
                          author: authorNickname,
                          authorUid: authorId,
                          category: category,
                          likes: likes,
                          views: views + 1,
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          SizedBox(
            height: 30,
          ),
          const BannerAdWidget(),
          SizedBox(
            height: 20,
          ),
        ],
      ),
    );
  }
}
