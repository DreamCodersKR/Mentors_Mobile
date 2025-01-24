import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mentors_app/components/customListTile.dart';
import 'package:mentors_app/screens/board_detail_screen.dart';
import 'package:mentors_app/widgets/banner_ad.dart';

class RecentViewsScreen extends StatefulWidget {
  const RecentViewsScreen({super.key});

  @override
  State<RecentViewsScreen> createState() => _RecentViewsScreenState();
}

class _RecentViewsScreenState extends State<RecentViewsScreen> {
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
  }) async {
    try {
      final updatedDoc = await FirebaseFirestore.instance
          .collection('boards')
          .doc(boardId)
          .get();
      if (updatedDoc.exists) {
        final updatedData = updatedDoc.data();
        if (updatedData != null) {
          final isDeleted = updatedData['is_deleted'] ?? false;
          if (isDeleted) {
            _showDeletedDialog(context);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BoardDetailScreen(
                  boardId: boardId,
                  title: updatedData['title'] ?? title,
                  content: updatedData['content'] ?? content,
                  author: updatedData['author'] ?? author,
                  authorUid: authorUid,
                  category: updatedData['category'] ?? category,
                  likes: updatedData['like_count'] ?? likes,
                  views: updatedData['views'] ?? views,
                ),
              ),
            ).then((_) {
              setState(() {});
            });
          }
        }
      } else {
        _showDeletedDialog(context);
      }
    } catch (e) {
      print('게시글 데이터 로드 실패: $e');
    }

    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => BoardDetailScreen(
    //       boardId: boardId,
    //       title: title,
    //       content: content,
    //       author: author,
    //       authorUid: authorUid,
    //       category: category,
    //       likes: likes,
    //       views: views,
    //     ),
    //   ),
    // ).then((_) {
    //   setState(() {});
    // });
  }

  void _showDeletedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('게시글 삭제됨'),
          content: const Text('해당 게시글은 삭제된 상태입니다.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('확인'),
            ),
          ],
        );
      },
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
                  print("Firestore 오류: ${snapshot.error}");
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

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('boards')
                          .doc(boardId)
                          .get(),
                      builder: (context, boardSnapshot) {
                        if (boardSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }

                        if (boardSnapshot.hasError || !boardSnapshot.hasData) {
                          return const Text('게시글 데이터를 가져올 수 없습니다.');
                        }

                        final boardData =
                            boardSnapshot.data?.data() as Map<String, dynamic>?;

                        if (boardData == null) {
                          return const Text('게시글 데이터가 없습니다.');
                        }

                        final updatedTitle = boardData['title'] ?? title;
                        final updatedCategory =
                            boardData['category'] ?? category;
                        final updatedLikes = boardData['like_count'] ?? likes;
                        final updatedViews = boardData['views'] ?? views;

                        return CustomListTile(
                          title: Text(
                            updatedTitle,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            updatedCategory,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                          trailing: Text(
                            '조회수 $updatedViews',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                          onTap: () async {
                            await _incrementViews(boardId);
                            _navigateToDetail(
                              context,
                              boardId: boardId,
                              title: updatedTitle,
                              content: content,
                              author: authorNickname,
                              authorUid: authorId,
                              category: updatedCategory,
                              likes: updatedLikes,
                              views: updatedViews + 1,
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 30),
          const BannerAdWidget(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
